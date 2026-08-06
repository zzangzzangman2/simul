part of 'market_data.dart';

enum CorporateDisclosureType {
  boardMeeting,
  preliminaryEarnings,
  periodicReport,
  auditReport,
  earningsCall,
  guidance,
  correction,
  annualGeneralMeeting,
  extraordinaryGeneralMeeting,
  dividend,
  rightsRecord,
  exRights,
  rightsSubscription,
  newShareListing,
  split,
  spinoff,
  merger,
  shareExchange,
  tenderOffer,
  delisting,
  buyback,
  shareCancellation,
  bonusIssue,
  bondIssue,
  convertibleBond,
  bondWithWarrant,
  tradingHalt,
  tradingResume,
  takeoverDefense,
  executiveChange,
  minorityShareholderAction,
  capexDecision,
  impairmentReview,
  restructuring,
  bankruptcyReview,
}

enum CorporateDisclosureStatus { completed, announced, scheduled }

class CorporateDisclosureEvent {
  const CorporateDisclosureEvent({
    required this.id,
    required this.assetId,
    required this.type,
    required this.date,
    required this.title,
    required this.summary,
    required this.status,
    this.minute = 16 * 60,
    this.material = false,
    this.playerGenerated = false,
    this.priceImpactBps = 0,
  });

  final String id;
  final String assetId;
  final CorporateDisclosureType type;
  final DateTime date;
  final int minute;
  final String title;
  final String summary;
  final CorporateDisclosureStatus status;
  final bool material;
  final bool playerGenerated;
  final int priceImpactBps;

  String get dateKey => marketDateKey(date);

  String get statusLabel => switch (status) {
    CorporateDisclosureStatus.completed => '공시 완료',
    CorporateDisclosureStatus.announced => '일정 확정',
    CorporateDisclosureStatus.scheduled => '예정',
  };
}

DateTime _corporateTradingDayOnOrAfter(DateTime date) {
  var cursor = DateTime(date.year, date.month, date.day);
  while (!isMarketTradingDay(cursor)) {
    cursor = cursor.add(const Duration(days: 1));
  }
  return cursor;
}

DateTime _corporateAddTradingDays(DateTime date, int tradingDays) {
  var cursor = DateTime(date.year, date.month, date.day);
  if (tradingDays == 0) return _corporateTradingDayOnOrAfter(cursor);
  final direction = tradingDays.isNegative ? -1 : 1;
  var remaining = tradingDays.abs();
  while (remaining > 0) {
    cursor = cursor.add(Duration(days: direction));
    if (isMarketTradingDay(cursor)) remaining -= 1;
  }
  return cursor;
}

DateTime marketFinancialPublicationDateForPeriod(String period) {
  final periodDate = DateTime.tryParse(period) ?? DateTime(2000, 12, 31);
  final quarter = (periodDate.month - 1) ~/ 3 + 1;
  final raw = switch (quarter) {
    1 => DateTime(periodDate.year, 5, 15),
    2 => DateTime(periodDate.year, 8, 14),
    3 => DateTime(periodDate.year, 11, 14),
    _ => DateTime(periodDate.year + 1, 3, 31),
  };
  return _corporateTradingDayOnOrAfter(raw);
}

DateTime marketFinancialPreliminaryDateForPeriod(String period) =>
    _corporateAddTradingDays(
      marketFinancialPublicationDateForPeriod(period),
      -7,
    );

String marketFinancialAuditOpinion(FictionalFinancialSnapshot snapshot) {
  if (snapshot.equity <= 0) return '의견거절';
  if (snapshot.netIncome < 0 && snapshot.operatingCashFlow < 0) return '한정';
  return '적정';
}

DateTime _corporateQuarterEnd(int year, int quarter) =>
    DateTime(year, quarter * 3 + 1, 0);

String _corporateQuarterLabel(int year, int quarter) => '$year ${quarter}Q';

CorporateDisclosureStatus _corporateDisclosureStatus({
  required DateTime eventDate,
  required DateTime announcedOn,
  required DateTime asOfDate,
}) {
  final today = DateTime(asOfDate.year, asOfDate.month, asOfDate.day);
  if (!eventDate.isAfter(today)) return CorporateDisclosureStatus.completed;
  if (!announcedOn.isAfter(today)) return CorporateDisclosureStatus.announced;
  return CorporateDisclosureStatus.scheduled;
}

DateTime _corporateThirdFriday(int year, int month) {
  var cursor = DateTime(year, month, 15);
  while (cursor.weekday != DateTime.friday) {
    cursor = cursor.add(const Duration(days: 1));
  }
  return cursor;
}

String _corporateCompactAmount(int value) {
  final absolute = value.abs();
  if (absolute >= 1000000000000) {
    return '${(value / 1000000000000).toStringAsFixed(1)}조원';
  }
  if (absolute >= 100000000) {
    return '${(value / 100000000).round()}억원';
  }
  return '$value원';
}

List<CorporateDisclosureEvent> buildCorporateDisclosureCalendar({
  required FictionalMarketAsset asset,
  required String simulationSeed,
  required DateTime asOfDate,
  ShareholderGovernanceState? governance,
  DateTime Function(int day)? governanceDateForDay,
  int pastDays = 180,
  int futureDays = 365,
}) {
  final today = DateTime(asOfDate.year, asOfDate.month, asOfDate.day);
  final windowStart = today.subtract(Duration(days: pastDays));
  final windowEnd = today.add(Duration(days: futureDays));
  final events = <CorporateDisclosureEvent>[];
  final snapshotsByQuarter = <String, FictionalFinancialSnapshot>{};
  for (final snapshot in asset.financials) {
    final periodDate = DateTime.tryParse(snapshot.period);
    if (periodDate == null) continue;
    final quarter = (periodDate.month - 1) ~/ 3 + 1;
    snapshotsByQuarter['${periodDate.year}-Q$quarter'] = snapshot;
  }

  void add(CorporateDisclosureEvent event) {
    if (event.date.isBefore(windowStart) || event.date.isAfter(windowEnd)) {
      return;
    }
    events.add(event);
  }

  for (var year = today.year - 1; year <= today.year + 1; year += 1) {
    for (var quarter = 1; quarter <= 4; quarter += 1) {
      final quarterEnd = _corporateQuarterEnd(year, quarter);
      final releaseDate = marketFinancialPublicationDateForPeriod(
        marketDateKey(quarterEnd),
      );
      final preliminaryDate = _corporateAddTradingDays(releaseDate, -7);
      final quarterKey = '$year-Q$quarter';
      final snapshot = snapshotsByQuarter[quarterKey];
      final reportName = quarter == 4
          ? '사업보고서'
          : quarter == 2
          ? '반기보고서'
          : '분기보고서';
      final status = _corporateDisclosureStatus(
        eventDate: releaseDate,
        announcedOn: preliminaryDate,
        asOfDate: today,
      );
      add(
        CorporateDisclosureEvent(
          id: 'preliminary-${asset.id}-$quarterKey',
          assetId: asset.id,
          type: CorporateDisclosureType.preliminaryEarnings,
          date: preliminaryDate,
          minute: 15 * 60 + 40,
          title: '${_corporateQuarterLabel(year, quarter)} 잠정실적 발표',
          summary: snapshot == null || preliminaryDate.isAfter(today)
              ? '매출·영업이익 잠정치와 시장 컨센서스 차이를 공시합니다.'
              : '영업이익 ${_corporateCompactAmount(snapshot.operatingProfit)} · 컨센서스 대비 ${snapshot.earningsSurprisePct >= 0 ? '+' : ''}${snapshot.earningsSurprisePct.toStringAsFixed(1)}%',
          status: _corporateDisclosureStatus(
            eventDate: preliminaryDate,
            announcedOn: _corporateAddTradingDays(preliminaryDate, -5),
            asOfDate: today,
          ),
          material: true,
        ),
      );
      add(
        CorporateDisclosureEvent(
          id: 'report-${asset.id}-$quarterKey',
          assetId: asset.id,
          type: CorporateDisclosureType.periodicReport,
          date: releaseDate,
          minute: 16 * 60,
          title: '$reportName 제출 · 확정실적',
          summary: snapshot == null || releaseDate.isAfter(today)
              ? '연결 손익계산서·현금흐름·차입금·수주잔고를 확정 공시합니다.'
              : '연결매출 ${_corporateCompactAmount(snapshot.consolidatedRevenue == 0 ? snapshot.revenue : snapshot.consolidatedRevenue)} · 감사의견 ${snapshot.auditOpinion}',
          status: status,
          material: true,
        ),
      );
      add(
        CorporateDisclosureEvent(
          id: 'call-${asset.id}-$quarterKey',
          assetId: asset.id,
          type: CorporateDisclosureType.earningsCall,
          date: releaseDate,
          minute: 16 * 60 + 10,
          title: '실적 컨퍼런스콜 · 가이던스',
          summary: snapshot == null || releaseDate.isAfter(today)
              ? '경영진이 다음 분기 매출·영업이익 범위와 CAPEX 계획을 설명합니다.'
              : '매출 가이던스 ${_corporateCompactAmount(snapshot.guidanceRevenueLow)}~${_corporateCompactAmount(snapshot.guidanceRevenueHigh)} · CAPEX ${_corporateCompactAmount(snapshot.capex)}',
          status: status,
        ),
      );
      if (quarter == 4) {
        final auditDate = _corporateAddTradingDays(releaseDate, -3);
        add(
          CorporateDisclosureEvent(
            id: 'audit-${asset.id}-$quarterKey',
            assetId: asset.id,
            type: CorporateDisclosureType.auditReport,
            date: auditDate,
            title: '외부감사인 감사보고서',
            summary: snapshot == null || auditDate.isAfter(today)
                ? '감사의견·계속기업 불확실성·내부회계관리 결론을 공시합니다.'
                : '감사의견 ${snapshot.auditOpinion} · 손상차손 ${_corporateCompactAmount(snapshot.impairmentLoss)}',
            status: _corporateDisclosureStatus(
              eventDate: auditDate,
              announcedOn: preliminaryDate,
              asOfDate: today,
            ),
            material: snapshot?.auditOpinion != '적정',
          ),
        );
        final meetingYear = year + 1;
        final hasGovernanceMeeting =
            governance?.meetings.any(
              (meeting) =>
                  meeting.assetId == asset.id &&
                  meeting.year == meetingYear &&
                  !meeting.extraordinary,
            ) ??
            false;
        if (!hasGovernanceMeeting) {
          final meetingDate = _corporateThirdFriday(meetingYear, 3);
          add(
            CorporateDisclosureEvent(
              id: 'agm-${asset.id}-$year',
              assetId: asset.id,
              type: CorporateDisclosureType.annualGeneralMeeting,
              date: meetingDate,
              minute: 10 * 60,
              title: '정기주주총회',
              summary: '재무제표 승인·이사/감사 선임·보수한도·배당·주주제안을 표결합니다.',
              status: _corporateDisclosureStatus(
                eventDate: meetingDate,
                announcedOn: _corporateAddTradingDays(meetingDate, -15),
                asOfDate: today,
              ),
            ),
          );
        }
      }
    }
  }

  for (final action in asset.corporateActions) {
    final effectiveDate = DateTime.parse(action.date);
    final announcedOn = marketCorporateActionAnnouncementDate(action);
    final status = _corporateDisclosureStatus(
      eventDate: effectiveDate,
      announcedOn: announcedOn,
      asOfDate: today,
    );
    final baseSummary = switch (action.type) {
      MarketCorporateActionType.dividend =>
        '주당 ${action.amount.round()}원 현금배당·배당락을 반영합니다.',
      MarketCorporateActionType.rightsIssue =>
        '${action.allocationMethod == MarketRightsIssueAllocationMethod.shareholder ? '주주배정' : '제3자배정'} 유상증자 · 발행가 ${action.amount.round()}원 · 희석 ${action.ownershipDilutionRate.mul(100).toStringAsFixed(2)}%',
      MarketCorporateActionType.split =>
        '주식수 ${action.numerator}:${action.denominator} 조정과 기준가 변경을 반영합니다.',
      MarketCorporateActionType.spinoff =>
        '기존 주주에게 ${action.relatedName ?? '신설법인'} 주식을 배정합니다.',
      MarketCorporateActionType.materialSpinoff =>
        '신설법인 지분은 모회사가 보유하고 모회사 기준가를 재산정합니다.',
      MarketCorporateActionType.merger =>
        '${action.relatedName ?? '존속법인'} 주식 ${action.numerator}:${action.denominator} 비율로 합병합니다.',
      MarketCorporateActionType.shareExchange =>
        '${action.relatedName ?? '모회사'} 주식으로 포괄적 주식교환합니다.',
      MarketCorporateActionType.tenderOffer =>
        '주당 ${action.amount.round()}원에 공개매수하고 청약 종료 후 정산합니다.',
      MarketCorporateActionType.delisting => '매매정지·정리매매·잔여가치 정산 일정을 안내합니다.',
    };
    final title = switch (action.type) {
      MarketCorporateActionType.dividend => '배당 지급·배당락',
      MarketCorporateActionType.rightsIssue => '유상증자 기준일',
      MarketCorporateActionType.split => '주식분할 효력 발생',
      MarketCorporateActionType.spinoff => '인적분할 · 신설주 배정',
      MarketCorporateActionType.materialSpinoff => '물적분할 효력 발생',
      MarketCorporateActionType.merger => '합병 효력 발생',
      MarketCorporateActionType.shareExchange => '포괄적 주식교환',
      MarketCorporateActionType.tenderOffer => '공개매수 청약 종료·정산',
      MarketCorporateActionType.delisting => '상장폐지·잔여가치 정산',
    };
    add(
      CorporateDisclosureEvent(
        id: 'action-${action.id}',
        assetId: asset.id,
        type: switch (action.type) {
          MarketCorporateActionType.dividend =>
            CorporateDisclosureType.dividend,
          MarketCorporateActionType.rightsIssue =>
            CorporateDisclosureType.rightsRecord,
          MarketCorporateActionType.split => CorporateDisclosureType.split,
          MarketCorporateActionType.spinoff ||
          MarketCorporateActionType.materialSpinoff =>
            CorporateDisclosureType.spinoff,
          MarketCorporateActionType.merger => CorporateDisclosureType.merger,
          MarketCorporateActionType.shareExchange =>
            CorporateDisclosureType.shareExchange,
          MarketCorporateActionType.tenderOffer =>
            CorporateDisclosureType.tenderOffer,
          MarketCorporateActionType.delisting =>
            CorporateDisclosureType.delisting,
        },
        date: effectiveDate,
        minute: marketDayStartMinute,
        title: title,
        summary: baseSummary,
        status: status,
        material: true,
      ),
    );
    if (action.type == MarketCorporateActionType.rightsIssue) {
      final exDate = _corporateAddTradingDays(effectiveDate, -1);
      final subscriptionStart = _corporateAddTradingDays(effectiveDate, 10);
      final subscriptionEnd = _corporateAddTradingDays(subscriptionStart, 2);
      final listingDate = _corporateAddTradingDays(subscriptionEnd, 8);
      for (final stage
          in <
            ({
              CorporateDisclosureType type,
              DateTime date,
              String title,
              String summary,
            })
          >[
            (
              type: CorporateDisclosureType.exRights,
              date: exDate,
              title: '신주배정 권리락',
              summary: '이론 권리락 기준가와 신주인수권 가치를 반영합니다.',
            ),
            (
              type: CorporateDisclosureType.rightsSubscription,
              date: subscriptionStart,
              title: '신주인수권 거래·청약 시작',
              summary: '보유 권리 일부 청약·매도와 미청약 처리를 선택합니다.',
            ),
            (
              type: CorporateDisclosureType.rightsSubscription,
              date: subscriptionEnd,
              title: '구주주 청약 마감',
              summary: '청약대금·실권주·최종 발행주식 수를 확정합니다.',
            ),
            (
              type: CorporateDisclosureType.newShareListing,
              date: listingDate,
              title: '유상증자 신주 상장',
              summary: '신주가 예탁결제원 잔고와 발행주식 수에 반영됩니다.',
            ),
          ]) {
        add(
          CorporateDisclosureEvent(
            id: '${stage.type.name}-${action.id}',
            assetId: asset.id,
            type: stage.type,
            date: stage.date,
            minute: marketDayStartMinute,
            title: stage.title,
            summary: stage.summary,
            status: _corporateDisclosureStatus(
              eventDate: stage.date,
              announcedOn: announcedOn,
              asOfDate: today,
            ),
            material: true,
          ),
        );
      }
    }
  }

  for (var year = today.year - 1; year <= today.year + 1; year += 1) {
    final planHash = stableHash31(
      '$simulationSeed:${asset.id}:capital-plan:$year',
    );
    final eventDate = _corporateTradingDayOnOrAfter(
      DateTime(year, 6 + planHash % 5, 5 + (planHash ~/ 11) % 19),
    );
    final announcedOn = _corporateAddTradingDays(eventDate, -10);
    if (announcedOn.isAfter(today)) continue;
    final planType = planHash % 6;
    final plan = switch (planType) {
      0 => (
        CorporateDisclosureType.buyback,
        '자사주 취득 결의',
        '장내 취득 한도·일일 주문 한도·취득 진척률을 공시합니다.',
      ),
      1 => (
        CorporateDisclosureType.shareCancellation,
        '자사주 소각 이사회',
        '발행주식 수를 줄이고 주당가치·지분율 변화를 반영합니다.',
      ),
      2 => (
        CorporateDisclosureType.bonusIssue,
        '무상증자 신주배정',
        '자본준비금을 자본금으로 전입하고 권리락·신주상장을 순차 반영합니다.',
      ),
      3 => (
        CorporateDisclosureType.bondIssue,
        '회사채 발행 결의',
        '만기·금리·자금용도와 상환 스케줄을 공시합니다.',
      ),
      4 => (
        CorporateDisclosureType.convertibleBond,
        '전환사채(CB) 발행',
        '전환가·리픽싱·전환가능일·잠재 희석률을 공시합니다.',
      ),
      _ => (
        CorporateDisclosureType.bondWithWarrant,
        '신주인수권부사채(BW) 발행',
        '행사가·행사기간·사채 상환조건·잠재 희석률을 공시합니다.',
      ),
    };
    add(
      CorporateDisclosureEvent(
        id: 'capital-${asset.id}-$year',
        assetId: asset.id,
        type: plan.$1,
        date: eventDate,
        title: plan.$2,
        summary: plan.$3,
        status: _corporateDisclosureStatus(
          eventDate: eventDate,
          announcedOn: announcedOn,
          asOfDate: today,
        ),
        material: true,
      ),
    );

    final governanceHash = stableHash31(
      '$simulationSeed:${asset.id}:governance:$year',
    );
    if (governanceHash % 7 == 0) {
      final takeoverDate = _corporateTradingDayOnOrAfter(
        DateTime(year, 9, 8 + governanceHash % 13),
      );
      final takeoverAnnounced = _corporateAddTradingDays(takeoverDate, -5);
      if (!takeoverAnnounced.isAfter(today)) {
        add(
          CorporateDisclosureEvent(
            id: 'takeover-${asset.id}-$year',
            assetId: asset.id,
            type: CorporateDisclosureType.takeoverDefense,
            date: takeoverDate,
            title: '경영권 분쟁·방어책 이사회',
            summary: '경쟁 공개매수·백기사·자사주 처분·신주발행 대안을 이사의 충실의무와 함께 심의합니다.',
            status: _corporateDisclosureStatus(
              eventDate: takeoverDate,
              announcedOn: takeoverAnnounced,
              asOfDate: today,
            ),
            material: true,
          ),
        );
      }
    }
    if (governanceHash % 5 == 0) {
      final executiveDate = _corporateTradingDayOnOrAfter(
        DateTime(year, 12, 5 + governanceHash % 15),
      );
      final executiveAnnounced = _corporateAddTradingDays(executiveDate, -3);
      if (!executiveAnnounced.isAfter(today)) {
        add(
          CorporateDisclosureEvent(
            id: 'executive-${asset.id}-$year',
            assetId: asset.id,
            type: CorporateDisclosureType.executiveChange,
            date: executiveDate,
            title: '대표이사·사내이사 변경',
            summary: '선임·해임 사유와 이사회/감사위원회 구성, 소수주주 의견을 공시합니다.',
            status: _corporateDisclosureStatus(
              eventDate: executiveDate,
              announcedOn: executiveAnnounced,
              asOfDate: today,
            ),
          ),
        );
      }
    }
  }

  final latest = asset.financialAtOrBefore(today);
  if (latest != null && marketFinancialSnapshotIsManagementRisk(latest)) {
    final riskDate = _corporateTradingDayOnOrAfter(
      DateTime(today.year, 12, 20),
    );
    final riskType = latest.equity <= 0
        ? CorporateDisclosureType.bankruptcyReview
        : CorporateDisclosureType.restructuring;
    add(
      CorporateDisclosureEvent(
        id: 'risk-${asset.id}-${today.year}',
        assetId: asset.id,
        type: riskType,
        date: riskDate,
        title: latest.equity <= 0 ? '자본잠식·회생절차 검토' : '자구계획·채무재조정',
        summary: '감사의견·계속기업 가정·채무상환 여력·자산매각·법원 절차 위험을 연결해 판단합니다.',
        status: _corporateDisclosureStatus(
          eventDate: riskDate,
          announcedOn: today,
          asOfDate: today,
        ),
        material: true,
      ),
    );
  }

  if (governance != null && governanceDateForDay != null) {
    _appendPlayerGovernanceDisclosures(
      add: add,
      asset: asset,
      governance: governance,
      dateForDay: governanceDateForDay,
      asOfDate: today,
    );
  }

  events.sort((left, right) {
    final dateOrder = left.date.compareTo(right.date);
    if (dateOrder != 0) return dateOrder;
    final minuteOrder = left.minute.compareTo(right.minute);
    if (minuteOrder != 0) return minuteOrder;
    return left.id.compareTo(right.id);
  });
  return List<CorporateDisclosureEvent>.unmodifiable(events);
}

void _appendPlayerGovernanceDisclosures({
  required void Function(CorporateDisclosureEvent event) add,
  required FictionalMarketAsset asset,
  required ShareholderGovernanceState governance,
  required DateTime Function(int day) dateForDay,
  required DateTime asOfDate,
}) {
  final company = governance.companyById(asset.id);
  if (company != null) {
    for (final decision in company.managementDecisions) {
      // 기업재편은 아래의 구조화된 기록에서 발표와 결과를 한 쌍으로 만든다.
      // 같은 사건을 managementDecisions에서도 다시 넣으면 공시가 중복된다.
      if (decision.agendaId.startsWith('market-event:corporate-')) continue;

      final announcedOn = dateForDay(decision.decisionDay);
      final completedOn = dateForDay(decision.completionDay);
      final immediateImpact = decision.immediatePriceImpactBps != 0
          ? decision.immediatePriceImpactBps
          : decision.completionDay == decision.decisionDay
          ? decision.realizedPriceImpactBps
          : 0;
      final decisionType = _playerDecisionDisclosureType(decision);
      add(
        CorporateDisclosureEvent(
          id: 'player-decision-${asset.id}-${decision.id}',
          assetId: asset.id,
          type: decisionType,
          date: announcedOn,
          minute: 15 * 60 + 35,
          title: '${decision.title} · ${decision.optionLabel}',
          summary: _withPriceImpact(
            decision.summary,
            immediateImpact,
            nextTradingDay: true,
          ),
          status: CorporateDisclosureStatus.completed,
          material: immediateImpact.abs() >= 50,
          playerGenerated: true,
          priceImpactBps: immediateImpact,
        ),
      );

      if (decision.completionDay <= decision.decisionDay) continue;
      final resultIsPublic =
          !decision.isExecuting && !completedOn.isAfter(asOfDate);
      final resultImpact = resultIsPublic ? decision.realizedPriceImpactBps : 0;
      add(
        CorporateDisclosureEvent(
          id: 'player-decision-result-${asset.id}-${decision.id}',
          assetId: asset.id,
          type: decisionType,
          date: completedOn,
          minute: 16 * 60,
          title:
              '${decision.title} · 성과 ${resultIsPublic ? decision.status.label : '확정 예정'}',
          summary: resultIsPublic
              ? _withPriceImpact(
                  decision.outcome.isEmpty
                      ? '집행 결과가 확정됐습니다.'
                      : decision.outcome,
                  resultImpact,
                  nextTradingDay: true,
                )
              : '집행 성과와 추가 시장평가는 이 날짜에 확정되며 결과는 미리 공개되지 않습니다.',
          status: _corporateDisclosureStatus(
            eventDate: completedOn,
            announcedOn: announcedOn,
            asOfDate: asOfDate,
          ),
          material: true,
          playerGenerated: true,
          priceImpactBps: resultImpact,
        ),
      );
    }
  }

  for (final meeting in governance.meetingsFor(asset.id)) {
    final heldOn = dateForDay(meeting.heldDay);
    final deadlineOn = dateForDay(meeting.deadlineDay);
    final agendaTitles = meeting.agendas
        .map((agenda) => agenda.title)
        .where((title) => title.trim().isNotEmpty)
        .take(3)
        .join(' · ');
    final decided = meeting.agendas.where((agenda) => agenda.passed != null);
    final passedCount = decided.where((agenda) => agenda.passed == true).length;
    final meetingClosed = meeting.status == ShareholderMeetingStatus.closed;
    final playerDriven =
        meeting.extraordinary ||
        meeting.agendas.any((agenda) => agenda.proposedByPlayer);
    add(
      CorporateDisclosureEvent(
        id: 'governance-meeting-${meeting.id}',
        assetId: asset.id,
        type: meeting.extraordinary
            ? CorporateDisclosureType.extraordinaryGeneralMeeting
            : CorporateDisclosureType.annualGeneralMeeting,
        date: heldOn,
        minute: 10 * 60,
        title: meeting.extraordinary ? '임시주주총회' : '정기주주총회',
        summary: meetingClosed
            ? '${decided.length}개 안건 중 $passedCount개 가결${meeting.attended ? ' · 플레이어 참석·의결 완료' : ''}'
            : '${agendaTitles.isEmpty ? '상정 안건 공시 예정' : agendaTitles} · 의결 마감 ${marketDateKey(deadlineOn)}',
        status: _corporateDisclosureStatus(
          eventDate: heldOn,
          announcedOn: deadlineOn,
          asOfDate: asOfDate,
        ),
        material: meeting.agendas.any(
          (agenda) =>
              agenda.type == ShareholderAgendaType.merger ||
              agenda.type == ShareholderAgendaType.capitalIncrease ||
              agenda.type == ShareholderAgendaType.assetSale,
        ),
        playerGenerated: playerDriven,
      ),
    );
  }

  for (final action in governance.corporateActionsFor(asset.id)) {
    final announcedOn = dateForDay(action.announcedDay);
    final completedOn = dateForDay(action.completionDay);
    final isLead = action.leadAssetId == asset.id;
    final counterparty = isLead ? action.partnerName : action.leadName;
    final immediateImpact = isLead
        ? action.immediatePriceImpactBps
        : (action.immediatePriceImpactBps * 0.7).round();
    final relation = counterparty.isEmpty ? '' : ' · 상대 $counterparty';
    final disclosureType = _playerCorporateActionDisclosureType(action.type);
    add(
      CorporateDisclosureEvent(
        id: 'player-corporate-announcement-${action.id}-${asset.id}',
        assetId: asset.id,
        type: disclosureType,
        date: announcedOn,
        minute: 15 * 60 + 35,
        title: '${action.type.label} 추진 공시',
        summary: _withPriceImpact(
          '${action.strategy}$relation · 주주 승인과 실행 절차를 시작합니다.',
          immediateImpact,
          nextTradingDay: true,
        ),
        status: CorporateDisclosureStatus.completed,
        material: true,
        playerGenerated: true,
        priceImpactBps: immediateImpact,
      ),
    );

    final resultIsPublic =
        !action.isExecuting && !completedOn.isAfter(asOfDate);
    final resultImpact = resultIsPublic
        ? _playerCorporateActionResultImpact(action, isLead: isLead)
        : 0;
    add(
      CorporateDisclosureEvent(
        id: 'player-corporate-result-${action.id}-${asset.id}',
        assetId: asset.id,
        type: disclosureType,
        date: completedOn,
        minute: 16 * 60,
        title:
            '${action.type.label} ${resultIsPublic ? action.status.label : '결과 확정 예정'}',
        summary: resultIsPublic
            ? _withPriceImpact(
                action.outcome.isEmpty ? '기업재편 결과가 확정됐습니다.' : action.outcome,
                resultImpact,
                nextTradingDay: true,
              )
            : '통합·재편 성과와 추가 시장평가는 이 날짜에 확정되며 결과는 미리 공개되지 않습니다.',
        status: _corporateDisclosureStatus(
          eventDate: completedOn,
          announcedOn: announcedOn,
          asOfDate: asOfDate,
        ),
        material: true,
        playerGenerated: true,
        priceImpactBps: resultImpact,
      ),
    );
  }
}

CorporateDisclosureType _playerDecisionDisclosureType(
  ListedManagementDecisionRecord decision,
) {
  if (decision.title.contains('CEO') || decision.agendaId.startsWith('ceo:')) {
    return switch (decision.optionId) {
      'talentAndCulture' => CorporateDisclosureType.executiveChange,
      'shareholderReturn' => CorporateDisclosureType.dividend,
      'researchAndDevelopment' ||
      'automation' ||
      'globalExpansion' => CorporateDisclosureType.capexDecision,
      _ => CorporateDisclosureType.boardMeeting,
    };
  }
  if (decision.title.contains('주주총회') ||
      decision.title.contains('주주서한') ||
      decision.title.contains('서면질의')) {
    return CorporateDisclosureType.minorityShareholderAction;
  }
  return CorporateDisclosureType.boardMeeting;
}

CorporateDisclosureType _playerCorporateActionDisclosureType(
  ListedCorporateActionType type,
) => switch (type) {
  ListedCorporateActionType.merger => CorporateDisclosureType.merger,
  ListedCorporateActionType.jointVenture =>
    CorporateDisclosureType.capexDecision,
  ListedCorporateActionType.spinOff => CorporateDisclosureType.spinoff,
  ListedCorporateActionType.assetSale => CorporateDisclosureType.restructuring,
};

int _playerCorporateActionResultImpact(
  ListedCorporateActionRecord action, {
  required bool isLead,
}) {
  final leadImpact = switch (action.status) {
    ListedCorporateActionStatus.succeeded => action.successPriceImpactBps,
    ListedCorporateActionStatus.mixed =>
      (action.successPriceImpactBps * 0.25).round(),
    ListedCorporateActionStatus.failed => action.failurePriceImpactBps,
    ListedCorporateActionStatus.executing => 0,
  };
  return isLead ? leadImpact : (leadImpact * 0.7).round();
}

String _withPriceImpact(
  String summary,
  int impactBps, {
  required bool nextTradingDay,
}) {
  if (impactBps == 0) return summary;
  final impact = impactBps / 100;
  final timing = nextTradingDay ? '다음 거래일 시장평가' : '시장평가';
  return '$summary · $timing ${impact >= 0 ? '+' : ''}${impact.toStringAsFixed(1)}%';
}

extension on double {
  double mul(double other) => this * other;
}
