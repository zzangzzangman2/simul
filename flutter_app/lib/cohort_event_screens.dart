import 'package:flutter/material.dart';

import 'game/cohort_standing_events.dart';
import 'game/cohort_withdrawal_crisis.dart';
import 'game/game_state.dart';
import 'game/relationship_state.dart';

const _ink = Color(0xFF14212B);
const _paper = Color(0xFFF7F4EC);

/// 수익률 순위표가 촉발한 사건을 보여 준다.
///
/// 연속 최하위는 중단권 안내, 연속 1위는 기록 열람, 같은 동기에게 계속 밀리면 라이벌
/// 성립이다. 확인하면 같은 연속 길이로는 다시 열리지 않는다.
class CohortStandingEventScreen extends StatelessWidget {
  const CohortStandingEventScreen({
    super.key,
    required this.event,
    required this.onAcknowledge,
  });

  final CohortStandingEvent event;
  final Future<void> Function() onAcknowledge;

  Color get _accent => switch (event.kind) {
    CohortStandingEventKind.operatorReview => const Color(0xFF7FA88B),
    CohortStandingEventKind.rightsAudit => const Color(0xFF9C8AC7),
    CohortStandingEventKind.rivalDeclared => const Color(0xFFEF8A62),
  };

  String get _eyebrow => switch (event.kind) {
    CohortStandingEventKind.operatorReview => '데시멀 센터 · 운영관 면담',
    CohortStandingEventKind.rightsAudit => '데시멀 센터 · 권익감사',
    CohortStandingEventKind.rivalDeclared => '데시멀 센터 · 트레이딩 플로어',
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    key: const Key('cohort-standing-event-screen'),
    backgroundColor: _ink,
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _eyebrow,
              style: TextStyle(
                color: _accent,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              event.title,
              key: const Key('cohort-standing-event-title'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w900,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  decoration: BoxDecoration(
                    color: _paper,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _accent, width: 2),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.speaker,
                        key: const Key('cohort-standing-event-speaker'),
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        event.body,
                        key: const Key('cohort-standing-event-body'),
                        style: const TextStyle(
                          color: Color(0xFF33414F),
                          fontSize: 13,
                          height: 1.62,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              key: const Key('cohort-standing-event-continue'),
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: _ink,
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: () async {
                await onAcknowledge();
                if (context.mounted) Navigator.of(context).pop(true);
              },
              child: const Text(
                '알겠습니다',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// 동기가 중단권을 꺼낸 날의 화면.
///
/// 응답 셋은 서로 다른 관계 축을 움직이고 서로 다른 대답을 받는다. 아무도 명단에서
/// 빠지지 않는다. 바뀌는 것은 남는 방식이다.
class CohortWithdrawalCrisisScreen extends StatefulWidget {
  const CohortWithdrawalCrisisScreen({
    super.key,
    required this.state,
    required this.onRespond,
  });

  final GameState state;
  final Future<CohortWithdrawalOutcome> Function(CohortWithdrawalResponse)
  onRespond;

  @override
  State<CohortWithdrawalCrisisScreen> createState() =>
      _CohortWithdrawalCrisisScreenState();
}

class _CohortWithdrawalCrisisScreenState
    extends State<CohortWithdrawalCrisisScreen> {
  String? _reply;
  bool _sending = false;

  static const _labels = <CohortWithdrawalResponse, (String, String)>{
    CohortWithdrawalResponse.persuade: (
      '조금 더 해 보자고 말한다',
      '신뢰가 오른다. 방식을 바꾸라고 요구하지는 않는다.',
    ),
    CohortWithdrawalResponse.respectRight: (
      '그만둘 권리를 인정하고 기다린다',
      '투자존중이 오른다. 붙잡지 않는다.',
    ),
    CohortWithdrawalResponse.shareLedger: (
      '내 장부를 같이 보자고 한다',
      '신뢰와 투자존중이 함께 조금 오른다.',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final crisis = activeCohortWithdrawalCrisis(widget.state);
    final reason = crisis == null
        ? null
        : cohortWithdrawalReasonFor(crisis.girlId);
    final profile = crisis == null
        ? null
        : cohortGirlProfileById(crisis.girlId);
    if (reason == null) {
      return const Scaffold(
        key: Key('cohort-withdrawal-screen'),
        backgroundColor: _ink,
        body: SizedBox.shrink(),
      );
    }
    final accent = Color(profile?.accentValue ?? 0xFFEF8A62);
    final replied = _reply;

    return Scaffold(
      key: const Key('cohort-withdrawal-screen'),
      backgroundColor: _ink,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '데시멀 센터 · 20:00',
                style: TextStyle(
                  color: accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${reason.name}가 먼저 말을 꺼냈다',
                key: const Key('cohort-withdrawal-title'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: _paper,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: accent, width: 2),
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                        child: Text(
                          reason.opening,
                          key: const Key('cohort-withdrawal-opening'),
                          style: const TextStyle(
                            color: Color(0xFF33414F),
                            fontSize: 13.5,
                            height: 1.64,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (replied != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          key: const Key('cohort-withdrawal-reply'),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.6),
                            ),
                          ),
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                          child: Text(
                            replied,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              height: 1.6,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ] else
                        for (final entry in _labels.entries) ...[
                          const SizedBox(height: 10),
                          OutlinedButton(
                            key: Key('cohort-withdrawal-${entry.key.name}'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: accent.withValues(alpha: 0.7),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              alignment: Alignment.centerLeft,
                            ),
                            onPressed: _sending
                                ? null
                                : () => _respond(entry.key),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.value.$1,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  entry.value.$2,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withValues(alpha: 0.72),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                    ],
                  ),
                ),
              ),
              if (replied != null) ...[
                const SizedBox(height: 14),
                FilledButton(
                  key: const Key('cohort-withdrawal-continue'),
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: _ink,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    '하루를 마친다',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _respond(CohortWithdrawalResponse response) async {
    setState(() => _sending = true);
    final outcome = await widget.onRespond(response);
    if (!mounted) return;
    setState(() {
      _sending = false;
      _reply = outcome.success ? outcome.reply : null;
    });
    if (!outcome.success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(outcome.message)));
    }
  }
}
