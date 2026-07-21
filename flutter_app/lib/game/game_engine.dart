import 'game_state.dart';
import 'story_state.dart';

class GameEngine {
  const GameEngine();

  GameState createNewGame(String companyName, {StoryState? story}) {
    final seed = 'simul-${_stableHash(companyName.trim())}';
    final storyState = story ?? StoryState.migratedDefault(companyName);
    final company = const CompanyState(
      id: 'apple',
      name: 'Apple',
      worldMode: WorldMode.historical,
      divergedAtDay: null,
      divergenceReason: null,
      votingOwnershipPct: 0,
      historicalPriceAtDivergence: null,
      simulatedPrice: null,
      monthlyRevenue: 120000,
      brand: 42,
      technology: 48,
      morale: 55,
      risk: 20,
    );
    return GameState(
      version: GameState.schemaVersion,
      companyName: companyName.trim(),
      day: 1,
      simulationSeed: seed,
      cash: 1000000,
      team: 1,
      story: storyState,
      company: company,
      project: null,
      decisions: [_firstResearchNote(1)],
      scheduledEvents: const [],
      ledger: const [],
      processedEventIds: const [],
    );
  }

  GameState migrate(Map<String, dynamic> json) {
    if (json['company'] != null) {
      return GameState.fromJson({...json, 'version': GameState.schemaVersion});
    }
    final companyName = (json['companyName'] as String? ?? '').trim();
    final fresh = createNewGame(companyName);
    return fresh.copyWith(
      day: ((json['day'] as num?)?.toInt() ?? 1).clamp(1, 4018),
      cash: (json['cash'] as num?)?.toInt() ?? 1000000,
      team: (json['team'] as num?)?.toInt() ?? 1,
    );
  }

  double historicalPriceForDay(int day) => 1000 + ((day - 1) * 2.0);

  double visiblePrice(GameState state) {
    if (state.company.worldMode == WorldMode.historical) {
      return historicalPriceForDay(state.day);
    }
    return state.company.simulatedPrice ?? historicalPriceForDay(state.day);
  }

  GameState resolveDecision(
    GameState state,
    String decisionId,
    String optionId,
  ) {
    final decision = state.decisions.firstWhere(
      (item) => item.id == decisionId,
    );
    if (decision.status != DecisionStatus.pending) return state;
    final option = decision.options.firstWhere((item) => item.id == optionId);
    if (option.cashCost > state.cash) return state;

    var decisions = state.decisions
        .map((item) => item.id == decisionId ? item.resolve(optionId) : item)
        .toList();
    var next = state.copyWith(decisions: decisions);

    switch (optionId) {
      case 'research_products':
      case 'research_cashflow':
      case 'research_people':
      case 'research_price':
        final focus = optionId.replaceFirst('research_', '');
        next = next.copyWith(
          story: next.story.copyWith(
            familyTrust: next.story.familyTrust + 1,
            storyFlags: {
              ...next.story.storyFlags,
              'firstResearchFocus': focus,
              'researchNoteUnlocked': true,
            },
            seenStoryEventIds: [
              ...next.story.seenStoryEventIds,
              if (!next.story.seenStoryEventIds.contains('FIRST_RESEARCH_NOTE'))
                'FIRST_RESEARCH_NOTE',
            ],
          ),
        );
      case 'acquire_control':
      case 'acquire_control_followup':
        next = _spend(next, option.cashCost, decisionId, 'Apple 경영권 시나리오 배정금');
        final continuityPrice = historicalPriceForDay(next.day);
        next = next.copyWith(
          company: next.company.copyWith(
            worldMode: WorldMode.diverged,
            divergedAtDay: next.day,
            divergenceReason: '의결권 55% 확보',
            votingOwnershipPct: 55,
            historicalPriceAtDivergence: continuityPrice,
            simulatedPrice: continuityPrice,
          ),
          decisions: [...next.decisions, _productProposal(next.day)],
        );
      case 'review_control':
        next = _schedule(
          next,
          'control-followup-${next.day + 3}',
          'control_followup',
          3,
        );
      case 'pass_control':
        next = next.copyWith(
          decisions: [
            ...next.decisions,
            _endingCard(
              next.day,
              '경쟁 세력이 먼저 Apple 이사회를 장악했습니다. 다음 기회를 기다려야 해요.',
            ),
          ],
        );
      case 'approve_full':
        next = _startProject(
          next,
          option.cashCost,
          'full',
          24,
          58,
          54,
          6,
          8,
          decisionId,
        );
      case 'approve_prototype':
        next = _startProject(
          next,
          option.cashCost,
          'prototype',
          14,
          52,
          52,
          2,
          4,
          decisionId,
        );
      case 'approve_partner':
        next = _startProject(
          next,
          option.cashCost,
          'partner',
          12,
          52,
          58,
          -1,
          -4,
          decisionId,
        );
      case 'reject_project':
        next = next.copyWith(
          company: next.company.copyWith(
            morale: next.company.morale - 8,
            technology: next.company.technology - 3,
            brand: next.company.brand - 2,
          ),
          project: const ProjectState(
            id: 'project-atlas',
            codename: 'Project Atlas',
            status: ProjectStatus.cancelled,
            approvedBudget: 0,
            spentBudget: 0,
            progress: 0,
            quality: 50,
            marketFit: 50,
            path: 'rejected',
          ),
        );
        next = _schedule(
          next,
          'competitor-result-${next.day + 4}',
          'competitor_result',
          4,
        );
      case 'fix_quality':
        next = _spend(next, option.cashCost, decisionId, '시제품 품질 개선');
        next = next.copyWith(
          company: next.company.copyWith(
            morale: next.company.morale + 3,
            risk: next.company.risk - 5,
          ),
          project: next.project!.copyWith(
            progress: next.project!.progress + 15,
            quality: next.project!.quality + 16,
            spentBudget: next.project!.spentBudget + option.cashCost,
          ),
        );
        next = _schedule(
          next,
          'launch-review-${next.day + 4}',
          'launch_review',
          4,
        );
      case 'cut_scope':
        next = _spend(next, option.cashCost, decisionId, '기능 축소와 안정화');
        next = next.copyWith(
          company: next.company.copyWith(
            morale: next.company.morale - 2,
            risk: next.company.risk + 4,
          ),
          project: next.project!.copyWith(
            progress: next.project!.progress + 24,
            quality: next.project!.quality - 8,
            marketFit: next.project!.marketFit - 5,
            spentBudget: next.project!.spentBudget + option.cashCost,
          ),
        );
        next = _schedule(
          next,
          'launch-review-${next.day + 2}',
          'launch_review',
          2,
        );
      case 'delay_development':
        next = _spend(next, option.cashCost, decisionId, '개발 일정 연장');
        next = next.copyWith(
          company: next.company.copyWith(
            morale: next.company.morale - 1,
            risk: next.company.risk - 3,
          ),
          project: next.project!.copyWith(
            progress: next.project!.progress + 18,
            quality: next.project!.quality + 8,
            spentBudget: next.project!.spentBudget + option.cashCost,
          ),
        );
        next = _schedule(
          next,
          'launch-review-${next.day + 6}',
          'launch_review',
          6,
        );
      case 'cancel_development':
      case 'cancel_launch':
        next = next.copyWith(
          company: next.company.copyWith(
            morale: next.company.morale - 9,
            brand: next.company.brand - 3,
          ),
          project: next.project?.copyWith(status: ProjectStatus.cancelled),
        );
        next = _schedule(
          next,
          'cancel-result-${next.day + 2}',
          'cancel_result',
          2,
        );
      case 'launch_now':
      case 'launch_after_delay':
        next = next.copyWith(
          company: next.company.copyWith(
            risk: next.company.risk + (optionId == 'launch_now' ? 6 : 1),
          ),
          project: next.project!.copyWith(
            status: ProjectStatus.launched,
            progress: 100,
          ),
        );
        next = _schedule(
          next,
          'launch-result-${next.day + 4}',
          'launch_result',
          4,
        );
      case 'delay_launch':
        next = _spend(next, option.cashCost, decisionId, '출시 전 품질 보강');
        next = next.copyWith(
          company: next.company.copyWith(
            morale: next.company.morale - 2,
            risk: next.company.risk - 7,
          ),
          project: next.project!.copyWith(
            status: ProjectStatus.launchReview,
            quality: next.project!.quality + 12,
            marketFit: next.project!.marketFit - 4,
            spentBudget: next.project!.spentBudget + option.cashCost,
          ),
        );
        next = _schedule(
          next,
          'final-launch-review-${next.day + 3}',
          'final_launch_review',
          3,
        );
      case 'acknowledge':
        break;
    }
    return next;
  }

  GameState advanceOneDay(GameState state) {
    if (state.pendingDecisions.isNotEmpty) return state;
    var next = state.copyWith(day: state.day + 1);
    if (next.company.worldMode == WorldMode.diverged) {
      final noise = _noise(
        next.simulationSeed,
        'price-${next.day}',
        -0.012,
        0.012,
      );
      final signal =
          (next.company.brand - 50) * 0.00015 +
          (next.company.technology - 50) * 0.00012 -
          next.company.risk * 0.00008;
      final change = (noise + signal).clamp(-0.15, 0.15);
      final price = (next.company.simulatedPrice! * (1 + change))
          .clamp(100, 1000000)
          .toDouble();
      next = next.copyWith(
        company: next.company.copyWith(simulatedPrice: price),
      );
    }
    if (next.day % 30 == 0 &&
        next.project?.status == ProjectStatus.development) {
      const burn = 10000;
      next = _spend(
        next,
        burn,
        'monthly-burn-${next.day}',
        'Project Atlas 월간 개발비',
      );
    }
    if (next.day >= 2558 &&
        next.company.worldMode == WorldMode.historical &&
        !next.decisions.any((item) => item.id.startsWith('control-offer'))) {
      next = next.copyWith(
        decisions: [
          ...next.decisions,
          _controlOffer(next.day, followUp: false),
        ],
      );
    }
    return _processDueEvents(next);
  }

  GameState _processDueEvents(GameState state) {
    var next = state;
    final due =
        next.scheduledEvents
            .where(
              (event) =>
                  event.dueDay <= next.day &&
                  !next.processedEventIds.contains(event.id),
            )
            .toList()
          ..sort((a, b) => a.dueDay.compareTo(b.dueDay));
    for (final event in due) {
      if (next.pendingDecisions.isNotEmpty) break;
      final processed = [...next.processedEventIds, event.id];
      next = next.copyWith(processedEventIds: processed);
      switch (event.type) {
        case 'control_followup':
          next = next.copyWith(
            decisions: [
              ...next.decisions,
              _controlOffer(next.day, followUp: true),
            ],
          );
        case 'development_issue':
          next = next.copyWith(
            decisions: [...next.decisions, _developmentIssue(next.day)],
          );
        case 'launch_review':
          next = next.copyWith(
            project: next.project?.copyWith(status: ProjectStatus.launchReview),
            decisions: [
              ...next.decisions,
              _launchReview(next.day, finalReview: false),
            ],
          );
        case 'final_launch_review':
          next = next.copyWith(
            decisions: [
              ...next.decisions,
              _launchReview(next.day, finalReview: true),
            ],
          );
        case 'launch_result':
          next = _applyLaunchResult(next);
        case 'competitor_result':
          next = next.copyWith(
            company: next.company.copyWith(
              brand: next.company.brand - 6,
              technology: next.company.technology - 5,
            ),
            decisions: [
              ...next.decisions,
              _endingCard(
                next.day,
                '경쟁사가 먼저 휴대형 기기를 공개했습니다. 현금을 지켰지만 기술과 브랜드가 뒤처졌어요.',
              ),
            ],
          );
        case 'cancel_result':
          next = next.copyWith(
            decisions: [
              ...next.decisions,
              _endingCard(
                next.day,
                '프로젝트는 정리됐습니다. 더 큰 손실은 막았지만 팀의 자신감이 흔들렸어요.',
              ),
            ],
          );
      }
    }
    return next;
  }

  GameState _applyLaunchResult(GameState state) {
    final project = state.project!;
    final roll = _noise(
      state.simulationSeed,
      'outcome-${project.path}',
      -15,
      15,
    ).round();
    final score =
        state.company.technology +
        state.company.brand +
        state.company.morale +
        project.quality +
        project.marketFit -
        state.company.risk +
        roll;
    late String message;
    late int revenueDelta;
    late int cashDelta;
    late int brandDelta;
    late int moraleDelta;
    late double priceMultiplier;
    if (score >= 235) {
      message =
          'Project Atlas가 예상 밖의 큰 호응을 얻었습니다. Apple이 새로운 휴대기기 시장의 기준을 만들기 시작했어요.';
      revenueDelta = 260000;
      cashDelta = 180000;
      brandDelta = 16;
      moraleDelta = 10;
      priceMultiplier = 1.18;
    } else if (score >= 205) {
      message = '출시는 안정적으로 자리 잡았습니다. 폭발적 성공은 아니지만 다음 제품을 만들 기반을 얻었어요.';
      revenueDelta = 140000;
      cashDelta = 85000;
      brandDelta = 9;
      moraleDelta = 6;
      priceMultiplier = 1.09;
    } else if (score >= 175) {
      message = '초기 반응은 엇갈렸습니다. 매출은 늘었지만 품질 지원과 다음 개선에 돈이 더 필요해요.';
      revenueDelta = 60000;
      cashDelta = 25000;
      brandDelta = 3;
      moraleDelta = -2;
      priceMultiplier = 0.98;
    } else {
      message = '제품은 시장에 닿았지만 결함과 낮은 수요가 겹쳤습니다. 실제 역사와 달리 성공은 보장되지 않아요.';
      revenueDelta = -30000;
      cashDelta = -50000;
      brandDelta = -8;
      moraleDelta = -10;
      priceMultiplier = 0.82;
    }
    var next = state.copyWith(
      cash: state.cash + cashDelta,
      company: state.company.copyWith(
        monthlyRevenue: state.company.monthlyRevenue + revenueDelta,
        brand: state.company.brand + brandDelta,
        morale: state.company.morale + moraleDelta,
        simulatedPrice: state.company.simulatedPrice! * priceMultiplier,
      ),
      project: project.copyWith(status: ProjectStatus.completed),
      decisions: [...state.decisions, _endingCard(state.day, message)],
    );
    next = next.copyWith(
      ledger: [
        ...next.ledger,
        LedgerEntry(
          id: 'launch-result-${next.day}',
          day: next.day,
          amount: cashDelta,
          account: 'cash',
          counterAccount: 'product_result',
          description: 'Project Atlas 초기 출시 결과',
          sourceId: 'launch_result',
        ),
      ],
    );
    return next;
  }

  GameState _startProject(
    GameState state,
    int cost,
    String path,
    int progress,
    int quality,
    int marketFit,
    int moraleDelta,
    int riskDelta,
    String sourceId,
  ) {
    var next = _spend(state, cost, sourceId, 'Project Atlas 1차 개발 승인');
    next = next.copyWith(
      company: next.company.copyWith(
        morale: next.company.morale + moraleDelta,
        risk: next.company.risk + riskDelta,
        technology: next.company.technology + (path == 'partner' ? 2 : 1),
      ),
      project: ProjectState(
        id: 'project-atlas',
        codename: 'Project Atlas',
        status: ProjectStatus.development,
        approvedBudget: cost,
        spentBudget: cost,
        progress: progress,
        quality: quality,
        marketFit: marketFit,
        path: path,
      ),
    );
    return _schedule(
      next,
      'development-issue-${next.day + 3}',
      'development_issue',
      3,
    );
  }

  GameState _spend(
    GameState state,
    int cost,
    String sourceId,
    String description,
  ) {
    if (cost == 0) return state;
    final ledgerId = '$sourceId-${state.day}-$cost';
    if (state.ledger.any((entry) => entry.id == ledgerId)) return state;
    return state.copyWith(
      cash: state.cash - cost,
      ledger: [
        ...state.ledger,
        LedgerEntry(
          id: ledgerId,
          day: state.day,
          amount: -cost,
          account: 'cash',
          counterAccount: 'investment',
          description: description,
          sourceId: sourceId,
        ),
      ],
    );
  }

  GameState _schedule(
    GameState state,
    String id,
    String type,
    int daysFromNow,
  ) {
    if (state.scheduledEvents.any((event) => event.id == id) ||
        state.processedEventIds.contains(id)) {
      return state;
    }
    return state.copyWith(
      scheduledEvents: [
        ...state.scheduledEvents,
        ScheduledGameEvent(id: id, type: type, dueDay: state.day + daysFromNow),
      ],
    );
  }

  static DecisionCardData _firstResearchNote(int day) => DecisionCardData(
    id: 'first-research-note',
    category: '가족 이야기',
    title: '첫 기업 조사노트',
    proposer: '외할아버지의 일곱 가지 질문',
    body:
        '첫 투자는 아직 하지 않아요. 우리 집과 신문에서 본 회사를 어떤 순서로 살펴볼지 정하고, 왜 사고 싶은지 한 줄씩 기록해봅시다.',
    createdDay: day,
    dueDay: day + 30,
    requestedFunds: 0,
    benefit: '기업 조사노트와 오늘의 시세표 준비',
    risk: '한 관점만 믿으면 중요한 단서를 놓칠 수 있음',
    advisorOpinions: const [
      '엄마: 돈을 어떻게 버는 회사인지부터 적어보자.',
      '아빠: 제품과 공장을 직접 봐야 숫자가 이해된다.',
      '누나: 사람들이 진짜 쓰는지도 봐야지.',
    ],
    options: const [
      DecisionOptionData(
        id: 'research_products',
        label: '제품부터 본다',
        description: '우리 집에서 실제로 쓰는 물건과 기술을 살펴봅니다.',
      ),
      DecisionOptionData(
        id: 'research_cashflow',
        label: '돈 버는 구조부터 본다',
        description: '누가 얼마나 자주 돈을 내는지 기록합니다.',
      ),
      DecisionOptionData(
        id: 'research_people',
        label: '사람과 경영진부터 본다',
        description: '회사를 운영하는 사람과 현장의 이야기를 봅니다.',
      ),
      DecisionOptionData(
        id: 'research_price',
        label: '가격부터 본다',
        description: '싸 보이는 이유와 이미 반영된 기대를 함께 확인합니다.',
      ),
    ],
  );

  static DecisionCardData _controlOffer(
    int day, {
    required bool followUp,
  }) => DecisionCardData(
    id: followUp ? 'control-offer-followup-$day' : 'control-offer-$day',
    category: '경영권',
    title: followUp ? 'Apple, 마지막 이사회 기회' : 'Apple 경영권 체험 시나리오',
    proposer: '시나리오 운영자 윤 실장',
    body: followUp
        ? '검토하는 사이 경쟁 세력이 이사회 표를 모았습니다. 시나리오 비용은 늘었고 오늘 결론이 필요해요.'
        : '첫 세로 슬라이스에서는 개발용 시나리오 계약으로 Apple 이사회 의결권 55%를 맡습니다. 실제 거래가격이나 내부정보가 아니며, 이후 역사는 우리의 선택으로 움직입니다.',
    createdDay: day,
    dueDay: day + (followUp ? 1 : 3),
    requestedFunds: followUp ? 350000 : 300000,
    benefit: 'Apple 경영권과 이사회 과반 체험',
    risk: '게임 자금 감소 · 제품 성공 불확실',
    advisorOpinions: const [
      '운영자: 실제 인수가 아닌 대체역사 체험용 조건입니다.',
      '기술자: 통합형 휴대기기 아이디어는 있으나 성공은 모릅니다.',
      '친구: 그래도 우리 게임 자금을 거의 3분의 1이나 쓰는 거야!',
    ],
    options: followUp
        ? const [
            DecisionOptionData(
              id: 'acquire_control_followup',
              label: '35만원으로 시나리오 시작',
              description: '비용은 올랐지만 지금 Apple 지배 시나리오를 시작합니다.',
              cashCost: 350000,
            ),
            DecisionOptionData(
              id: 'pass_control',
              label: '이번 기회 포기',
              description: '현금을 지키고 경쟁사의 선택을 지켜봅니다.',
            ),
          ]
        : const [
            DecisionOptionData(
              id: 'acquire_control',
              label: '30만원으로 시나리오 시작',
              description: '오늘의 개발용 기준지수에서 Apple 대체역사를 시작합니다.',
              cashCost: 300000,
            ),
            DecisionOptionData(
              id: 'review_control',
              label: '3일 더 검토',
              description: '정보는 늘지만 가격과 경쟁 위험이 커집니다.',
            ),
          ],
  );

  static DecisionCardData _productProposal(int day) => DecisionCardData(
    id: 'product-proposal-$day',
    category: 'CEO 제안',
    title: 'Project Atlas: 통합형 휴대기기',
    proposer: 'Apple CEO',
    body:
        '전화, 음악, 인터넷 기능을 하나의 터치 기기에 통합하고 싶습니다. 게임 속 내부 코드명만 표시하며 실제 역사상 결과는 미리 알려주지 않습니다.',
    createdDay: day,
    dueDay: day + 3,
    requestedFunds: 180000,
    benefit: '새 시장 진입 · 기술과 브랜드 성장',
    risk: '배터리 · 생산수율 · 현금 부족',
    advisorOpinions: const [
      'CEO: 작게 시작해도 우리가 먼저 배워야 합니다.',
      '회계사: 전액 투자는 회사 현금을 빠르게 줄입니다.',
      '기술자: 핵심 부품은 준비됐지만 배터리는 불안합니다.',
    ],
    options: const [
      DecisionOptionData(
        id: 'approve_full',
        label: '18만원 전액 투자',
        description: '속도와 팀 사기는 오르지만 실행 위험도 큽니다.',
        cashCost: 180000,
      ),
      DecisionOptionData(
        id: 'approve_prototype',
        label: '7만원 시제품만 승인',
        description: '위험을 줄이고 다음 단계에서 다시 판단합니다.',
        cashCost: 70000,
      ),
      DecisionOptionData(
        id: 'approve_partner',
        label: '5만원 공동개발',
        description: '비용과 위험을 나누지만 주도권도 나눕니다.',
        cashCost: 50000,
      ),
      DecisionOptionData(
        id: 'reject_project',
        label: '제안 거절',
        description: '현금을 지키지만 팀과 기술 기회를 잃을 수 있습니다.',
      ),
    ],
  );

  static DecisionCardData _developmentIssue(int day) => DecisionCardData(
    id: 'development-issue-$day',
    category: '개발 문제',
    title: '시제품이 너무 뜨거워집니다',
    proposer: '기술책임자 미나',
    body: '오래 사용하면 배터리 온도가 안전 기준을 넘습니다. 출시 일정, 기능, 품질을 동시에 지킬 수는 없어요.',
    createdDay: day,
    dueDay: day + 2,
    requestedFunds: 80000,
    benefit: '품질 개선 또는 빠른 일정 유지',
    risk: '지연 · 기능 축소 · 개발비 증가',
    advisorOpinions: const [
      '기술자: 부품을 바꾸면 품질은 좋아지지만 시간이 듭니다.',
      'CEO: 핵심 기능을 줄이면 제품의 매력이 약해집니다.',
      '회계사: 추가 지출 뒤에도 비상금은 남겨야 합니다.',
    ],
    options: const [
      DecisionOptionData(
        id: 'fix_quality',
        label: '8만원 들여 부품 교체',
        description: '품질과 팀 사기는 오르지만 비용이 큽니다.',
        cashCost: 80000,
      ),
      DecisionOptionData(
        id: 'cut_scope',
        label: '2만원으로 기능 축소',
        description: '빠르게 가지만 품질과 시장성이 낮아집니다.',
        cashCost: 20000,
      ),
      DecisionOptionData(
        id: 'delay_development',
        label: '3만5천원 · 일정 연장',
        description: '품질을 보강하지만 경쟁사가 움직일 시간이 생깁니다.',
        cashCost: 35000,
      ),
      DecisionOptionData(
        id: 'cancel_development',
        label: '개발 중단',
        description: '추가 손실을 막지만 조직 충격이 큽니다.',
      ),
    ],
  );

  static DecisionCardData _launchReview(int day, {required bool finalReview}) =>
      DecisionCardData(
        id: '${finalReview ? 'final-' : ''}launch-review-$day',
        category: '출시 심사',
        title: finalReview
            ? 'Project Atlas 최종 출시 결정'
            : 'Project Atlas를 세상에 내놓을까요?',
        proposer: 'Apple 이사회',
        body: finalReview
            ? '품질 보강은 끝났지만 경쟁사의 소문이 커졌습니다. 이제 출시하거나 접어야 합니다.'
            : '시제품은 작동하지만 수요는 넓은 범위로만 추정됩니다. 지금 출시하면 빠르지만 품질 위험이 남습니다.',
        createdDay: day,
        dueDay: day + 2,
        requestedFunds: finalReview ? 0 : 40000,
        benefit: '첫 매출과 브랜드 기회',
        risk: '실제 성공은 보장되지 않음 · 출시 후 지원비',
        advisorOpinions: const [
          'CEO: 완벽하지 않아도 시장에서 배울 수 있습니다.',
          '기술자: 조금 더 다듬으면 결함 가능성을 낮출 수 있습니다.',
          '회계사: 연기할수록 현금과 선점 기회가 줄어듭니다.',
        ],
        options: finalReview
            ? const [
                DecisionOptionData(
                  id: 'launch_after_delay',
                  label: '보강한 제품 출시',
                  description: '개선된 품질로 시장 반응을 확인합니다.',
                ),
                DecisionOptionData(
                  id: 'cancel_launch',
                  label: '출시 취소',
                  description: '남은 위험을 피하지만 투자금과 기회를 잃습니다.',
                ),
              ]
            : const [
                DecisionOptionData(
                  id: 'launch_now',
                  label: '지금 출시',
                  description: '선점 기회가 크지만 품질 위험도 남습니다.',
                ),
                DecisionOptionData(
                  id: 'delay_launch',
                  label: '4만원 · 3일 연기',
                  description: '품질은 좋아지지만 비용과 경쟁 위험이 생깁니다.',
                  cashCost: 40000,
                ),
                DecisionOptionData(
                  id: 'cancel_launch',
                  label: '출시 취소',
                  description: '추가 위험은 막지만 팀과 브랜드가 흔들립니다.',
                ),
              ],
      );

  static DecisionCardData _endingCard(int day, String message) =>
      DecisionCardData(
        id: 'story-result-$day-${_stableHash(message)}',
        category: '결과 보고',
        title: '선택의 결과가 도착했어요',
        proposer: '시뮬레이션 기록실',
        body: message,
        createdDay: day,
        dueDay: day + 30,
        requestedFunds: 0,
        benefit: '이번 선택의 변화가 저장됩니다.',
        risk: '다음 선택에도 누적 영향을 줍니다.',
        advisorOpinions: const [
          '기록: 실제 회사명은 사용하지만 내부 수치·의견·결과는 게임용 가상 시나리오입니다.',
        ],
        options: const [
          DecisionOptionData(
            id: 'acknowledge',
            label: '결과 확인',
            description: '대체역사 기록을 닫고 사무실로 돌아갑니다.',
          ),
        ],
      );

  static int _stableHash(String input) {
    var hash = 2166136261;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 16777619) & 0x7fffffff;
    }
    return hash;
  }

  static double _noise(String seed, String key, double min, double max) {
    final normalized = _stableHash('$seed:$key') / 0x7fffffff;
    return min + (max - min) * normalized;
  }
}
