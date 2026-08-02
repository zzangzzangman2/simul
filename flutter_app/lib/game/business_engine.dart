import 'dart:math' as math;

import 'business_districts.dart';
import 'business_simulation.dart';
import 'business_state.dart';
import 'game_state.dart';
import 'personal_finance_state.dart';
import 'real_estate_market.dart';
import 'real_estate_rental.dart';

/// Player input for starting a new shop or acquiring an existing one.
///
/// Only the listing id is trusted. [LocalBusinessEngine.openOrAcquire]
/// regenerates the current month's listings and copies the matching listing so
/// a stale or client-edited quote cannot change the price.
class BusinessLaunchRequest {
  const BusinessLaunchRequest({
    required this.listingId,
    required this.businessName,
    required this.locationId,
    required this.premiseMode,
    required this.policy,
    this.linkedRealEstateId,
  });

  final String listingId;
  final String businessName;
  final String locationId;
  final BusinessPremiseMode premiseMode;
  final BusinessOperatingPolicy policy;
  final String? linkedRealEstateId;
}

/// Result shared by every state-changing local-business action.
class BusinessActionResult {
  const BusinessActionResult({
    required this.state,
    required this.success,
    required this.message,
    this.cashDelta = 0,
  });

  final GameState state;
  final bool success;
  final String message;

  /// Actual movement in the company bank account.
  ///
  /// Costs converted into accounts payable are deliberately excluded.
  final int cashDelta;
}

/// Applies the local-business simulation to [GameState].
///
/// `advanceOneDay` processes the date already present in the supplied state. It
/// never increments `GameState.day`; the main game engine owns the clock.
class LocalBusinessEngine {
  const LocalBusinessEngine();

  static const int listingCount = 24;

  BusinessActionResult openOrAcquire(
    GameState state,
    BusinessLaunchRequest request,
  ) {
    final listingId = request.listingId.trim();
    if (listingId.isEmpty) {
      return _failure(state, '선택한 사업 매물이 없습니다.');
    }
    final currentListings = generateBusinessListings(
      worldSeed: state.simulationSeed,
      asOfDate: state.currentDate,
      count: listingCount,
      generatorVersion: businessWorldGeneratorVersion,
    );
    BusinessListing? quotedListing;
    for (final candidate in currentListings) {
      if (candidate.id == listingId) {
        quotedListing = candidate;
        break;
      }
    }
    if (quotedListing == null ||
        !quotedListing.isAvailableOn(state.currentDate)) {
      return _failure(state, '매물이 만료되었거나 이번 달 목록과 일치하지 않습니다.');
    }

    final locationId = quotedListing.mode == BusinessListingMode.acquisition
        ? quotedListing.locationId
        : request.locationId;
    if (businessLocationProfileById(locationId) == null) {
      return _failure(state, '선택한 상권을 찾을 수 없습니다.');
    }
    final listing = repriceBusinessListingForLocation(
      listing: quotedListing,
      locationId: locationId,
    );

    final businessId = 'local-${listing.id}';
    final sourceId = 'business-launch-${listing.id}';
    if (state.businesses.businessById(businessId) != null ||
        state.processedEventIds.contains(sourceId)) {
      return _failure(state, '이미 인수했거나 개점한 매물입니다.');
    }

    OwnedRealEstate? linkedProperty;
    if (request.premiseMode == BusinessPremiseMode.ownedProperty) {
      final propertyId = request.linkedRealEstateId?.trim() ?? '';
      if (propertyId.isEmpty) {
        return _failure(state, '입점할 보유 상가나 오피스 빌딩을 선택해 주세요.');
      }
      for (final property in state.personalFinance.realEstate) {
        if (property.id == propertyId) {
          linkedProperty = property;
          break;
        }
      }
      final problem = _ownedPremiseProblem(state, linkedProperty);
      if (problem != null) return _failure(state, problem);
      final propertyDistrictId = _districtIdForOwnedProperty(linkedProperty);
      if (propertyDistrictId == null) {
        return _failure(state, '지역 정보가 없는 구형 부동산은 직영점으로 연결할 수 없습니다.');
      }
      if (listing.districtId.isEmpty ||
          propertyDistrictId != listing.districtId) {
        final listingDistrict = businessDistrictProfileById(listing.districtId);
        final propertyDistrict = businessDistrictProfileById(
          propertyDistrictId,
        );
        return _failure(
          state,
          '이 매물은 ${listingDistrict?.name ?? listing.districtId} 지역입니다. '
          '${propertyDistrict?.name ?? propertyDistrictId} 소재 보유 건물에는 입점할 수 없습니다.',
        );
      }
    }

    final usesOwnedProperty =
        request.premiseMode == BusinessPremiseMode.ownedProperty;
    final initialCashRequired =
        listing.askingPrice + (usesOwnedProperty ? 0 : listing.leaseDeposit);
    if (state.bankCash < initialCashRequired) {
      return _failure(
        state,
        '회사 통장 잔액이 ${initialCashRequired - state.bankCash}원 부족합니다.',
      );
    }

    final business = createOwnedBusinessFromListing(
      listing: listing,
      businessId: businessId,
      name: request.businessName,
      acquiredDay: state.day,
      openedDate: state.currentDate,
      policy: request.policy,
      premiseMode: request.premiseMode,
      linkedRealEstateId: linkedProperty?.id,
    );
    var personalFinance = state.personalFinance;
    if (linkedProperty != null) {
      personalFinance = _markPropertyInUse(
        personalFinance,
        linkedProperty.id,
        business.name,
      );
    }

    final entries = <LedgerEntry>[
      LedgerEntry(
        id: '$sourceId-acquisition',
        day: state.day,
        amount: -listing.askingPrice,
        notional: listing.askingPrice,
        account: 'company_bank',
        counterAccount: 'business_acquisition_asset',
        description: '${business.name} ${listing.mode.label} 대금',
        sourceId: sourceId,
      ),
      if (!usesOwnedProperty && listing.leaseDeposit > 0)
        LedgerEntry(
          id: '$sourceId-deposit',
          day: state.day,
          amount: -listing.leaseDeposit,
          notional: listing.leaseDeposit,
          account: 'company_bank',
          counterAccount: 'business_lease_deposit',
          description: '${business.name} 임차보증금',
          sourceId: sourceId,
        ),
    ];
    final portfolio = state.businesses
        .replaceBusiness(business)
        .copyWith(
          totalAcquisitionSpend:
              state.businesses.totalAcquisitionSpend + initialCashRequired,
        );
    final next = state.copyWith(
      cash: state.cash - initialCashRequired,
      businesses: portfolio,
      personalFinance: personalFinance,
      ledger: [...state.ledger, ...entries],
      processedEventIds: _appendProcessed(state.processedEventIds, sourceId),
    );
    return BusinessActionResult(
      state: next,
      success: true,
      cashDelta: -initialCashRequired,
      message: usesOwnedProperty
          ? '${business.name} 개점 완료 · 보유 ${linkedProperty!.assetType.label} 입점'
          : '${business.name} 개점 완료 · 초기 현금 $initialCashRequired원',
    );
  }

  BusinessActionResult updatePolicy(
    GameState state,
    String businessId,
    BusinessOperatingPolicy policy,
  ) {
    final business = state.businesses.businessById(businessId);
    if (business == null) return _failure(state, '사업체를 찾지 못했습니다.');
    if (!business.isActive) {
      return _failure(state, '영업 중인 사업체만 운영 정책을 바꿀 수 있습니다.');
    }
    final updated = business.copyWith(policy: policy);
    return BusinessActionResult(
      state: state.copyWith(
        businesses: state.businesses.replaceBusiness(updated),
      ),
      success: true,
      message: '${business.name} 운영 정책을 저장했습니다. 다음 정산에 반영됩니다.',
    );
  }

  BusinessActionResult invest(
    GameState state,
    String businessId,
    BusinessInvestmentKind kind,
  ) {
    final business = state.businesses.businessById(businessId);
    if (business == null) return _failure(state, '사업체를 찾지 못했습니다.');
    if (!business.isActive) {
      return _failure(state, '영업 중인 사업체에만 추가 투자할 수 있습니다.');
    }
    final plan = businessInvestmentPlanFor(business, kind);
    if (state.bankCash < plan.cost) {
      return _failure(state, '회사 통장 잔액이 ${plan.cost - state.bankCash}원 부족합니다.');
    }
    final applied = applyBusinessInvestment(business, kind);
    final sourceId =
        'business-invest-${business.id}-${kind.name}-${state.day}-'
        '${business.totalInvested}';
    final next = state.copyWith(
      cash: state.cash + applied.cashDelta,
      businesses: state.businesses.replaceBusiness(applied.business),
      ledger: [
        ...state.ledger,
        LedgerEntry(
          id: sourceId,
          day: state.day,
          amount: applied.cashDelta,
          notional: plan.cost,
          account: 'company_bank',
          counterAccount: 'business_investment_asset',
          description: '${business.name} ${kind.label} · ${plan.description}',
          sourceId: sourceId,
        ),
      ],
      processedEventIds: _appendProcessed(state.processedEventIds, sourceId),
    );
    return BusinessActionResult(
      state: next,
      success: true,
      message: applied.message,
      cashDelta: applied.cashDelta,
    );
  }

  BusinessActionResult chooseEvent(
    GameState state,
    String eventId,
    String choiceId,
  ) {
    BusinessEventInstance? event;
    for (final candidate in state.businesses.pendingEvents) {
      if (candidate.id == eventId) {
        event = candidate;
        break;
      }
    }
    if (event == null) return _failure(state, '처리할 사업 사건을 찾지 못했습니다.');
    final business = state.businesses.businessById(event.businessId);
    if (business == null || !business.isActive) {
      return _failure(state, '해당 사업체가 더 이상 영업 중이 아닙니다.');
    }
    if (event.status != BusinessEventStatus.pendingChoice) {
      return _failure(state, '이미 선택을 마친 사건입니다.');
    }
    final due = event.choiceDueDate;
    if (due != null && state.currentDate.isAfter(due)) {
      return _failure(state, '선택 기한이 지나 자동 대응 대상이 되었습니다.');
    }
    if (!event.choices.any((choice) => choice.id == choiceId)) {
      return _failure(state, '선택지를 찾지 못했습니다.');
    }
    return _applyEventChoice(
      state,
      event,
      choiceId,
      selectedAt: state.currentDate,
      automatic: false,
    );
  }

  BusinessActionResult closeOrSell(GameState state, String businessId) {
    final business = state.businesses.businessById(businessId);
    if (business == null) return _failure(state, '사업체를 찾지 못했습니다.');
    if (business.status == BusinessStatus.closed ||
        business.status == BusinessStatus.sold) {
      return _failure(state, '이미 폐업 또는 매각 정산을 마친 사업체입니다.');
    }
    final accrued = accrueCurrentDay(state, onlyBusinessId: businessId);
    final partialSettlement = _settleAccruedMonth(
      accrued.state,
      businessId,
      state.currentDate,
    );
    final current = partialSettlement.state.businesses.businessById(businessId);
    if (current == null) return _failure(state, '사업체를 찾지 못했습니다.');
    final liquidation = _liquidateBusiness(
      partialSettlement.state,
      current,
      forced: false,
      sourceId: 'business-disposition-${business.id}',
    );
    return BusinessActionResult(
      state: liquidation.state,
      success: liquidation.success,
      cashDelta:
          accrued.cashDelta +
          partialSettlement.cashDelta +
          liquidation.cashDelta,
      message: partialSettlement.message.isEmpty
          ? liquidation.message
          : '${partialSettlement.message} · ${liquidation.message}',
    );
  }

  /// Freezes the current day's operating result before the game clock moves.
  /// Existing saves without an accrual ledger backfill only the still-open
  /// portion of the current month once, then append one immutable day at a time.
  BusinessActionResult accrueCurrentDay(
    GameState state, {
    String? onlyBusinessId,
  }) {
    var portfolio = state.businesses;
    var accruedCount = 0;
    final date = state.currentDate;
    final dateIso = _businessDateIso(date);
    final monthKey = _businessMonthKey(date);
    final allEvents = <BusinessEventInstance>[
      ...state.businesses.pendingEvents,
      ...state.businesses.eventHistory,
    ];

    for (final snapshot in state.businesses.activeBusinesses) {
      if (onlyBusinessId != null && snapshot.id != onlyBusinessId) continue;
      var business = portfolio.businessById(snapshot.id);
      if (business == null || !business.isActive) continue;
      if (business.lastSettledMonth == monthKey) continue;
      final openedDate =
          DateTime.tryParse(business.openedDateIso) ??
          state.dateForDay(business.acquiredDay);
      if (date.isBefore(openedDate)) continue;
      if (business.unsettledDailyResults.any(
        (result) => result.dateIso == dateIso,
      )) {
        continue;
      }

      final existingThisMonth = business.unsettledDailyResults
          .where((result) => result.dateIso.startsWith('$monthKey-'))
          .toList(growable: false);
      final firstDate = existingThisMonth.isEmpty
          ? _laterDate(DateTime(date.year, date.month, 1), openedDate)
          : date;
      final additions = <BusinessDailyResult>[];
      for (
        var cursor = firstDate;
        !cursor.isAfter(date);
        cursor = cursor.add(const Duration(days: 1))
      ) {
        final cursorIso = _businessDateIso(cursor);
        if (business.unsettledDailyResults.any(
          (result) => result.dateIso == cursorIso,
        )) {
          continue;
        }
        additions.add(
          simulateBusinessDay(
            business: business,
            worldSeed: state.simulationSeed,
            date: cursor,
            events: allEvents,
          ),
        );
      }
      if (additions.isEmpty) continue;
      business = business.copyWith(
        unsettledDailyResults: <BusinessDailyResult>[
          ...business.unsettledDailyResults,
          ...additions,
        ]..sort((left, right) => left.dateIso.compareTo(right.dateIso)),
      );
      portfolio = portfolio.replaceBusiness(business);
      accruedCount += additions.length;
    }
    return BusinessActionResult(
      state: state.copyWith(businesses: portfolio),
      success: true,
      message: accruedCount == 0 ? '' : '사업 일일 원장 $accruedCount일 확정',
    );
  }

  /// Processes monthly settlement, event deadlines/outcomes, and event draws
  /// for the state's current date. This method does not advance the game clock.
  BusinessActionResult advanceOneDay(GameState state) {
    var next = state;
    var totalCashDelta = 0;
    var monthlySettlements = 0;
    var automaticChoices = 0;
    var resolvedEvents = 0;
    var generatedEvents = 0;

    if (next.currentDate.day == 1) {
      final settledBefore = _monthlySettlementCount(next.processedEventIds);
      final settlement = _settlePreviousFullMonth(next);
      next = settlement.state;
      totalCashDelta += settlement.cashDelta;
      monthlySettlements =
          _monthlySettlementCount(next.processedEventIds) - settledBefore;
    }

    final overdue = next.businesses.pendingEvents
        .where((event) {
          final due = event.choiceDueDate;
          return event.status == BusinessEventStatus.pendingChoice &&
              event.choices.isNotEmpty &&
              due != null &&
              next.currentDate.isAfter(due);
        })
        .map((event) => event.id)
        .toList(growable: false);
    for (final eventId in overdue) {
      final currentEvent = _pendingEventById(next.businesses, eventId);
      if (currentEvent == null ||
          currentEvent.status != BusinessEventStatus.pendingChoice ||
          currentEvent.choices.isEmpty) {
        continue;
      }
      final automatic = _applyEventChoice(
        next,
        currentEvent,
        currentEvent.choices.last.id,
        selectedAt: currentEvent.choiceDueDate ?? next.currentDate,
        automatic: true,
      );
      if (automatic.success) {
        next = automatic.state;
        totalCashDelta += automatic.cashDelta;
        automaticChoices += 1;
      }
    }

    final dueOutcomes = next.businesses.pendingEvents
        .where((event) {
          final resolution = event.resolutionDate;
          return event.status == BusinessEventStatus.awaitingOutcome &&
              resolution != null &&
              !next.currentDate.isBefore(resolution);
        })
        .map((event) => event.id)
        .toList(growable: false);
    for (final eventId in dueOutcomes) {
      final resolution = _resolveEvent(next, eventId);
      if (resolution.success) {
        next = resolution.state;
        totalCashDelta += resolution.cashDelta;
        resolvedEvents += 1;
      }
    }

    final businessIds = next.businesses.activeBusinesses
        .map((business) => business.id)
        .toList(growable: false);
    for (final businessId in businessIds) {
      final business = next.businesses.businessById(businessId);
      if (business == null || !business.isActive) continue;
      final allEvents = <BusinessEventInstance>[
        ...next.businesses.pendingEvents,
        ...next.businesses.eventHistory,
      ];
      final event = generateBusinessEventForDay(
        business: business,
        worldSeed: next.simulationSeed,
        date: next.currentDate,
        existingEvents: allEvents,
      );
      if (event == null) continue;
      final sourceId = 'business-event-created-${event.id}';
      if (next.processedEventIds.contains(sourceId)) continue;
      next = next.copyWith(
        businesses: next.businesses.addPendingEvent(event),
        processedEventIds: _appendProcessed(next.processedEventIds, sourceId),
      );
      generatedEvents += 1;
    }

    final reconciled = reconcilePremises(next);
    next = reconciled.state;
    totalCashDelta += reconciled.cashDelta;
    final details = <String>[
      if (monthlySettlements > 0) '월 정산 $monthlySettlements건',
      if (automaticChoices > 0) '자동 대응 $automaticChoices건',
      if (resolvedEvents > 0) '결과 공개 $resolvedEvents건',
      if (generatedEvents > 0) '새 사건 $generatedEvents건',
      if (reconciled.message != _noPremiseChangeMessage) reconciled.message,
    ];
    return BusinessActionResult(
      state: next,
      success: true,
      cashDelta: totalCashDelta,
      message: details.isEmpty ? '오늘 사업 운영 변동이 없습니다.' : details.join(' · '),
    );
  }

  /// Repairs stale owned-property links without granting permanent free rent.
  ///
  /// A missing, leased, sale-listed, residential, or duplicate property link is
  /// converted to a safe zero-deposit commercial lease.
  BusinessActionResult reconcilePremises(GameState state) {
    var portfolio = state.businesses;
    final claimedPropertyIds = <String>{};
    final convertedNames = <String>[];
    final processedIds = [...state.processedEventIds];
    final entries = <LedgerEntry>[];

    for (final snapshot in portfolio.businesses) {
      if (!snapshot.isActive ||
          snapshot.premiseMode != BusinessPremiseMode.ownedProperty) {
        continue;
      }
      final propertyId = snapshot.linkedRealEstateId ?? '';
      OwnedRealEstate? property;
      for (final candidate in state.personalFinance.realEstate) {
        if (candidate.id == propertyId) {
          property = candidate;
          break;
        }
      }
      final invalid =
          propertyId.isEmpty ||
          property == null ||
          !_isCommercialPremise(property) ||
          property.hasActiveLease ||
          property.leaseType != RealEstateLeaseType.vacant ||
          property.isDirectUse ||
          property.saleListedDay > 0 ||
          claimedPropertyIds.contains(propertyId);
      if (!invalid) {
        claimedPropertyIds.add(propertyId);
        continue;
      }

      final location =
          businessLocationProfileById(snapshot.locationId) ??
          businessLocationProfileById('residential')!;
      final profile = businessIndustryProfileFor(snapshot.industry);
      final districtProfile =
          snapshot.generatorVersion >= 2 && snapshot.districtId.isNotEmpty
          ? businessDistrictProfileById(snapshot.districtId)
          : null;
      final district = districtProfile == null
          ? null
          : businessDistrictSnapshotFor(
              districtProfile,
              asOf: state.currentDate,
              worldSeed: state.simulationSeed,
              generatorVersion: businessDistrictVersionForBusinessWorld(
                snapshot.generatorVersion,
              ),
            );
      final fallbackRent = math.max(
        100000,
        (profile.baseMonthlyRent *
                location.rentMultiplier *
                (district?.rentMultiplier ?? 1.0) *
                businessEraCostIndexAt(state.currentDate))
            .round(),
      );
      final converted = snapshot.copyWith(
        premiseMode: BusinessPremiseMode.leased,
        clearLinkedRealEstateId: true,
        leaseDeposit: 0,
        monthlyRent: fallbackRent,
        districtRentIndexAtOpenBps:
            ((district?.rentMultiplier ?? 1.0) *
                    businessEraCostIndexAt(state.currentDate) *
                    10000)
                .round(),
        status: snapshot.accountsPayable > 0
            ? BusinessStatus.struggling
            : BusinessStatus.operating,
        riskLevel: snapshot.riskLevel + 5,
      );
      portfolio = portfolio.replaceBusiness(converted);
      convertedNames.add(snapshot.name);
      final sourceId = 'business-premise-conversion-${snapshot.id}';
      if (!processedIds.contains(sourceId)) {
        processedIds.add(sourceId);
        entries.add(
          LedgerEntry(
            id: sourceId,
            day: state.day,
            amount: 0,
            notional: fallbackRent,
            account: 'business_lease_commitment',
            counterAccount: 'premise_relocation',
            description: '${snapshot.name} 연결 건물 상실 · 안전 임차 전환',
            sourceId: sourceId,
          ),
        );
      }
    }

    if (convertedNames.isEmpty) {
      return BusinessActionResult(
        state: state,
        success: true,
        message: _noPremiseChangeMessage,
      );
    }
    return BusinessActionResult(
      state: state.copyWith(
        businesses: portfolio,
        ledger: [...state.ledger, ...entries],
        processedEventIds: processedIds,
      ),
      success: true,
      message: '${convertedNames.join(', ')}: 연결 건물 문제로 안전 임차 전환',
    );
  }

  BusinessActionResult _applyEventChoice(
    GameState state,
    BusinessEventInstance event,
    String choiceId, {
    required DateTime selectedAt,
    required bool automatic,
  }) {
    final business = state.businesses.businessById(event.businessId);
    if (business == null || !business.isActive) {
      return _failure(state, '사건 대상 사업체가 영업 중이 아닙니다.');
    }
    BusinessEventChoiceApplication applied;
    try {
      applied = applyBusinessEventChoice(
        business: business,
        event: event,
        choiceId: choiceId,
        selectedAt: selectedAt,
      );
    } on Object {
      return _failure(state, '이 사건의 선택을 적용할 수 없습니다.');
    }

    final cost = math.max(0, -applied.cashDelta);
    final paid = math.min(cost, state.bankCash);
    final shortfall = cost - paid;
    final updatedBusiness = applied.business.copyWith(
      accountsPayable: applied.business.accountsPayable + shortfall,
      status: shortfall > 0
          ? BusinessStatus.struggling
          : applied.business.status,
    );
    var portfolio = state.businesses.replaceBusiness(updatedBusiness);
    portfolio = portfolio.copyWith(
      pendingEvents: _replacePendingEvent(
        portfolio.pendingEvents,
        applied.event,
      ),
    );
    final sourceId = 'business-event-choice-${event.id}';
    final entries = <LedgerEntry>[
      LedgerEntry(
        id: sourceId,
        day: state.day,
        amount: -paid,
        notional: cost,
        account: 'company_bank',
        counterAccount: 'business_event_response',
        description:
            '${business.name} 사건 대응${automatic ? ' 자동선택' : ''} · '
            '${applied.choice.label}',
        sourceId: sourceId,
      ),
      if (shortfall > 0)
        LedgerEntry(
          id: '$sourceId-payable',
          day: state.day,
          amount: 0,
          notional: shortfall,
          account: 'business_event_expense',
          counterAccount: 'business_accounts_payable',
          description: '${business.name} 사건 대응 미지급금',
          sourceId: sourceId,
        ),
    ];
    final next = state.copyWith(
      cash: state.cash - paid,
      businesses: portfolio,
      ledger: [...state.ledger, ...entries],
      processedEventIds: _appendProcessed(state.processedEventIds, sourceId),
    );
    return BusinessActionResult(
      state: next,
      success: true,
      cashDelta: -paid,
      message: automatic
          ? '${event.title}: 기한 경과로 마지막 대응안을 자동 선택했습니다.'
          : '${applied.choice.label} 대응을 시작했습니다. 결과는 예정일에 공개됩니다.',
    );
  }

  BusinessActionResult _resolveEvent(GameState state, String eventId) {
    final event = _pendingEventById(state.businesses, eventId);
    if (event == null) return _failure(state, '해결할 사건을 찾지 못했습니다.');
    final business = state.businesses.businessById(event.businessId);
    if (business == null || !business.isActive) {
      return _failure(state, '사건 대상 사업체가 영업 중이 아닙니다.');
    }
    final sourceId = 'business-event-result-${event.id}';
    if (state.processedEventIds.contains(sourceId)) {
      return _failure(state, '이미 반영한 사건 결과입니다.');
    }
    final resolution = resolveBusinessEvent(
      business: business,
      event: event,
      worldSeed: state.simulationSeed,
      asOfDate: state.currentDate,
    );
    if (!resolution.resolved) {
      return _failure(state, '아직 사건 결과가 확정되지 않았습니다.');
    }

    final requestedCost = math.max(0, -resolution.cashDelta);
    final paid = math.min(requestedCost, state.bankCash);
    final shortfall = requestedCost - paid;
    final received = math.max(0, resolution.cashDelta);
    final actualCashDelta = received - paid;
    final updatedBusiness = resolution.business.copyWith(
      accountsPayable: resolution.business.accountsPayable + shortfall,
      status: shortfall > 0
          ? BusinessStatus.struggling
          : resolution.business.status,
    );
    var portfolio = state.businesses.replaceBusiness(updatedBusiness);
    portfolio = portfolio.archiveEvent(resolution.event);
    final entries = <LedgerEntry>[
      LedgerEntry(
        id: sourceId,
        day: state.day,
        amount: actualCashDelta,
        notional: resolution.cashDelta.abs(),
        account: 'company_bank',
        counterAccount: resolution.cashDelta >= 0
            ? 'business_event_gain'
            : 'business_event_loss',
        description: '${business.name} · ${resolution.event.outcomeTitle}',
        sourceId: sourceId,
      ),
      if (shortfall > 0)
        LedgerEntry(
          id: '$sourceId-payable',
          day: state.day,
          amount: 0,
          notional: shortfall,
          account: 'business_event_loss',
          counterAccount: 'business_accounts_payable',
          description: '${business.name} 사건 결과 미지급금',
          sourceId: sourceId,
        ),
    ];
    return BusinessActionResult(
      state: state.copyWith(
        cash: state.cash + actualCashDelta,
        businesses: portfolio,
        ledger: [...state.ledger, ...entries],
        processedEventIds: _appendProcessed(state.processedEventIds, sourceId),
      ),
      success: true,
      cashDelta: actualCashDelta,
      message: resolution.event.outcomeTitle,
    );
  }

  BusinessActionResult _settlePreviousFullMonth(GameState state) {
    final previousMonth = DateTime(
      state.currentDate.year,
      state.currentDate.month - 1,
      1,
    );
    var next = state;
    var totalCashDelta = 0;
    var settlementCount = 0;
    final businessIds = state.businesses.activeBusinesses
        .map((business) => business.id)
        .toList(growable: false);

    for (final businessId in businessIds) {
      final business = next.businesses.businessById(businessId);
      if (business == null || !business.isActive) continue;
      final openedDate =
          DateTime.tryParse(business.openedDateIso) ??
          state.dateForDay(business.acquiredDay);
      final accruedResults = business.unsettledDailyResults
          .where(
            (result) => result.dateIso.startsWith(
              '${previousMonth.year}-'
              '${previousMonth.month.toString().padLeft(2, '0')}-',
            ),
          )
          .toList(growable: false);
      if (openedDate.isAfter(previousMonth) && accruedResults.isEmpty) {
        continue;
      }
      final monthKey =
          '${previousMonth.year}-'
          '${previousMonth.month.toString().padLeft(2, '0')}';
      if (business.lastSettledMonth == monthKey) continue;

      final allEvents = <BusinessEventInstance>[
        ...next.businesses.pendingEvents,
        ...next.businesses.eventHistory,
      ];
      final simulation = accruedResults.isEmpty
          ? simulateBusinessMonth(
              business: business,
              worldSeed: next.simulationSeed,
              year: previousMonth.year,
              month: previousMonth.month,
              events: allEvents,
            )
          : summarizeBusinessDays(
              business: business,
              year: previousMonth.year,
              month: previousMonth.month,
              dailyResults: accruedResults,
            );
      final sourceId = simulation.statement.sourceId;
      if (next.processedEventIds.contains(sourceId)) continue;
      final settlement = settleBusinessMonth(
        business: business.copyWith(
          unsettledDailyResults: business.unsettledDailyResults
              .where((result) => !accruedResults.contains(result))
              .toList(growable: false),
        ),
        statement: simulation.statement,
        availableBankCash: next.bankCash,
      );
      if (settlement.alreadySettled) continue;

      var portfolio = applyBusinessMonthSettlement(next.businesses, settlement);
      final entries = <LedgerEntry>[
        LedgerEntry(
          id: sourceId,
          day: next.day,
          amount: settlement.cashDelta,
          notional: settlement.statement.grossSales,
          realizedPnl: settlement.statement.netProfit,
          account: 'company_bank',
          counterAccount: settlement.statement.netProfit >= 0
              ? 'business_operating_profit'
              : 'business_operating_loss',
          description:
              '${business.name} $monthKey 월 정산 · '
              '순이익 ${settlement.statement.netProfit}원',
          sourceId: sourceId,
        ),
        if (settlement.payableChange != 0)
          LedgerEntry(
            id: '$sourceId-payable',
            day: next.day,
            amount: 0,
            notional: settlement.payableChange.abs(),
            account: settlement.payableChange > 0
                ? 'business_operating_expense'
                : 'business_accounts_payable',
            counterAccount: settlement.payableChange > 0
                ? 'business_accounts_payable'
                : 'company_bank',
            description: settlement.payableChange > 0
                ? '${business.name} 월 운영비 미지급'
                : '${business.name} 기존 미지급금 상환',
            sourceId: sourceId,
          ),
      ];
      next = next.copyWith(
        cash: next.cash + settlement.cashDelta,
        businesses: portfolio,
        ledger: [...next.ledger, ...entries],
        processedEventIds: _appendProcessed(next.processedEventIds, sourceId),
      );
      totalCashDelta += settlement.cashDelta;
      settlementCount += 1;

      if (settlement.forcedClosure) {
        final closed = next.businesses.businessById(business.id);
        if (closed != null) {
          final liquidation = _liquidateBusiness(
            next,
            closed,
            forced: true,
            sourceId: 'business-liquidation-${business.id}',
          );
          if (liquidation.success) {
            next = liquidation.state;
            totalCashDelta += liquidation.cashDelta;
          }
        }
      }
    }
    return BusinessActionResult(
      state: next,
      success: true,
      cashDelta: totalCashDelta,
      message: settlementCount == 0
          ? '정산할 완전 영업월이 없습니다.'
          : '직영점 월 정산 $settlementCount건 완료',
    );
  }

  BusinessActionResult _settleAccruedMonth(
    GameState state,
    String businessId,
    DateTime date,
  ) {
    final business = state.businesses.businessById(businessId);
    if (business == null) return _failure(state, '사업체를 찾지 못했습니다.');
    final monthKey = _businessMonthKey(date);
    if (business.lastSettledMonth == monthKey) {
      return BusinessActionResult(state: state, success: true, message: '');
    }
    final results = business.unsettledDailyResults
        .where((result) => result.dateIso.startsWith('$monthKey-'))
        .toList(growable: false);
    if (results.isEmpty) {
      return BusinessActionResult(state: state, success: true, message: '');
    }
    final simulation = summarizeBusinessDays(
      business: business,
      year: date.year,
      month: date.month,
      dailyResults: results,
    );
    final settlement = settleBusinessMonth(
      business: business.copyWith(
        unsettledDailyResults: business.unsettledDailyResults
            .where((result) => !results.contains(result))
            .toList(growable: false),
      ),
      statement: simulation.statement,
      availableBankCash: state.bankCash,
    );
    final portfolio = applyBusinessMonthSettlement(
      state.businesses,
      settlement,
    );
    final sourceId = simulation.statement.sourceId;
    final next = state.copyWith(
      cash: state.cash + settlement.cashDelta,
      businesses: portfolio,
      ledger: <LedgerEntry>[
        ...state.ledger,
        LedgerEntry(
          id: sourceId,
          day: state.day,
          amount: settlement.cashDelta,
          notional: settlement.statement.grossSales,
          realizedPnl: settlement.statement.netProfit,
          account: 'company_bank',
          counterAccount: settlement.statement.netProfit >= 0
              ? 'business_operating_profit'
              : 'business_operating_loss',
          description:
              '${business.name} $monthKey 폐업일 부분 정산 · '
              '순이익 ${settlement.statement.netProfit}원',
          sourceId: sourceId,
        ),
        if (settlement.payableChange != 0)
          LedgerEntry(
            id: '$sourceId-payable',
            day: state.day,
            amount: 0,
            notional: settlement.payableChange.abs(),
            account: settlement.payableChange > 0
                ? 'business_operating_expense'
                : 'business_accounts_payable',
            counterAccount: settlement.payableChange > 0
                ? 'business_accounts_payable'
                : 'company_bank',
            description: settlement.payableChange > 0
                ? '${business.name} 월 운영비 미지급'
                : '${business.name} 기존 미지급금 상환',
            sourceId: sourceId,
          ),
      ],
      processedEventIds: _appendProcessed(state.processedEventIds, sourceId),
    );
    return BusinessActionResult(
      state: next,
      success: true,
      cashDelta: settlement.cashDelta,
      message: '$monthKey 영업손익 부분 정산',
    );
  }

  /// Final daily sweep after every company-bank inflow has been processed.
  BusinessActionResult repayDisposedBusinessPayablesForDay(GameState state) =>
      _repayDisposedBusinessPayables(state);

  BusinessActionResult _repayDisposedBusinessPayables(
    GameState state, {
    String? onlyBusinessId,
    String? fixedSourceId,
  }) {
    assert(fixedSourceId == null || onlyBusinessId != null);
    var availableBankCash = state.bankCash;
    if (availableBankCash <= 0) {
      return BusinessActionResult(
        state: state,
        success: true,
        message: '상환 가능한 회사 통장 잔액이 없습니다.',
      );
    }

    final debtors =
        state.businesses.businesses
            .where(
              (business) =>
                  (onlyBusinessId == null || business.id == onlyBusinessId) &&
                  (business.status == BusinessStatus.closed ||
                      business.status == BusinessStatus.sold) &&
                  business.accountsPayable > 0,
            )
            .toList(growable: false)
          ..sort((left, right) => left.id.compareTo(right.id));
    var portfolio = state.businesses;
    final processedIds = [...state.processedEventIds];
    final entries = <LedgerEntry>[];
    var totalRepaid = 0;

    for (final snapshot in debtors) {
      if (availableBankCash <= 0) break;
      final business = portfolio.businessById(snapshot.id);
      if (business == null || business.accountsPayable <= 0) continue;
      final sourceId =
          fixedSourceId ??
          'business-payable-repayment-${business.id}-${state.day}';
      if (processedIds.contains(sourceId)) {
        // Do not let a later creditor bypass this sweep's stable priority.
        break;
      }
      final repayment = math.min(business.accountsPayable, availableBankCash);
      if (repayment <= 0) continue;

      portfolio = portfolio.replaceBusiness(
        business.copyWith(
          accountsPayable: business.accountsPayable - repayment,
        ),
      );
      availableBankCash -= repayment;
      totalRepaid += repayment;
      processedIds.add(sourceId);
      entries.add(
        LedgerEntry(
          id: sourceId,
          day: state.day,
          amount: -repayment,
          notional: repayment,
          account: 'company_bank',
          counterAccount: 'business_accounts_payable',
          description: '${business.name} 폐업 후 미지급금 자동상환',
          sourceId: sourceId,
        ),
      );
    }

    if (totalRepaid <= 0) {
      return BusinessActionResult(
        state: state,
        success: true,
        message: '오늘 상환할 폐업점 미지급금이 없습니다.',
      );
    }
    return BusinessActionResult(
      state: state.copyWith(
        cash: state.cash - totalRepaid,
        businesses: portfolio,
        ledger: [...state.ledger, ...entries],
        processedEventIds: processedIds,
      ),
      success: true,
      cashDelta: -totalRepaid,
      message: '폐업점 미지급금 ${entries.length}건 · $totalRepaid원 자동상환',
    );
  }

  BusinessActionResult _liquidateBusiness(
    GameState state,
    OwnedBusiness business, {
    required bool forced,
    required String sourceId,
  }) {
    if (state.processedEventIds.contains(sourceId)) {
      return _failure(state, '이미 사업 정리 정산을 반영했습니다.');
    }
    final equipmentRecovery =
        (business.equipmentBookValue * business.equipmentCondition / 100 * 0.55)
            .round();
    final positiveProfit = math.max(0, business.trailingTwelveMonthProfit);
    final goodwillRecovery = forced || positiveProfit <= 0
        ? 0
        : (business.goodwillBookValue * 0.60 +
                  math.min(
                    positiveProfit * 0.25,
                    business.acquisitionPrice * 0.35,
                  ))
              .round();
    final grossRecovery =
        business.leaseDeposit + equipmentRecovery + goodwillRecovery;
    final payableOffset = math.min(business.accountsPayable, grossRecovery);
    final netCash = grossRecovery - payableOffset;
    final remainingPayable = math.max(
      0,
      business.accountsPayable - payableOffset,
    );
    final finalStatus = forced
        ? BusinessStatus.closed
        : positiveProfit > 0
        ? BusinessStatus.sold
        : BusinessStatus.closed;
    final disposed = business.copyWith(
      status: finalStatus,
      premiseMode: BusinessPremiseMode.leased,
      clearLinkedRealEstateId: true,
      leaseDeposit: 0,
      monthlyRent: 0,
      equipmentBookValue: 0,
      goodwillBookValue: 0,
      accountsPayable: remainingPayable,
      demandMomentumBps: 0,
    );
    var portfolio = state.businesses.replaceBusiness(disposed);
    if (!forced) {
      portfolio = portfolio.copyWith(
        totalClosures: portfolio.totalClosures + 1,
      );
    }
    portfolio = _archiveBusinessEvents(
      portfolio,
      business.id,
      forced ? '강제 폐업으로 사건이 종료되었습니다.' : '사업 정리로 사건이 종료되었습니다.',
    );
    var personalFinance = state.personalFinance;
    final propertyId = business.linkedRealEstateId;
    if (propertyId != null && propertyId.isNotEmpty) {
      personalFinance = _releaseProperty(
        personalFinance,
        propertyId,
        business.name,
      );
    }
    final entries = <LedgerEntry>[
      LedgerEntry(
        id: sourceId,
        day: state.day,
        amount: netCash,
        notional: grossRecovery,
        disposedCost: business.bookValue,
        realizedPnl: grossRecovery - business.bookValue,
        account: 'company_bank',
        counterAccount: forced
            ? 'business_forced_liquidation'
            : 'business_disposition',
        description:
            '${business.name} ${forced ? '강제 폐업' : finalStatus.label} 정산 · '
            '회수 $grossRecovery원',
        sourceId: sourceId,
      ),
      if (payableOffset > 0)
        LedgerEntry(
          id: '$sourceId-payable',
          day: state.day,
          amount: 0,
          notional: payableOffset,
          account: 'business_accounts_payable',
          counterAccount: 'business_liquidation_assets',
          description: '${business.name} 미지급금 자산 상계',
          sourceId: sourceId,
        ),
    ];
    final liquidated = state.copyWith(
      cash: state.cash + netCash,
      businesses: portfolio,
      personalFinance: personalFinance,
      ledger: [...state.ledger, ...entries],
      processedEventIds: _appendProcessed(state.processedEventIds, sourceId),
    );
    final repayment = _repayDisposedBusinessPayables(
      liquidated,
      onlyBusinessId: business.id,
      fixedSourceId: '$sourceId-remaining-payable-cash',
    );
    final finalBusiness = repayment.state.businesses.businessById(business.id)!;
    final repaymentAmount = -repayment.cashDelta;
    return BusinessActionResult(
      state: repayment.state,
      success: true,
      cashDelta: netCash + repayment.cashDelta,
      message:
          '${business.name} ${forced ? '강제 폐업' : finalStatus.label} 완료 · '
          '통장 회수 $netCash원'
          '${repaymentAmount > 0 ? ' · 미지급금 자동상환 $repaymentAmount원' : ''}'
          '${finalBusiness.accountsPayable > 0 ? ' · 잔존 미지급금 ${finalBusiness.accountsPayable}원' : ''}',
    );
  }
}

const _noPremiseChangeMessage = '사업장 연결 이상이 없습니다.';

int _monthlySettlementCount(List<String> processedIds) => processedIds
    .where((sourceId) => sourceId.startsWith('business-month-'))
    .length;

String _businessDateIso(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

String _businessMonthKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}';

DateTime _laterDate(DateTime left, DateTime right) =>
    left.isAfter(right) ? left : right;

BusinessActionResult _failure(GameState state, String message) =>
    BusinessActionResult(state: state, success: false, message: message);

String? _ownedPremiseProblem(GameState state, OwnedRealEstate? property) {
  if (property == null) return '보유 부동산을 찾지 못했습니다.';
  if (!_isCommercialPremise(property)) {
    return '상가 또는 오피스 빌딩만 직영점으로 사용할 수 있습니다.';
  }
  if (property.isDirectUse) return '이미 직접 사용하는 부동산입니다.';
  if (property.hasActiveLease ||
      property.leaseType != RealEstateLeaseType.vacant) {
    return '세입자가 없는 공실만 직영점으로 사용할 수 있습니다.';
  }
  if (property.saleListedDay > 0) return '매각 등록을 해제한 뒤 입점할 수 있습니다.';
  if (state.businesses.usesRealEstate(property.id)) {
    return '다른 직영점이 이미 사용하는 부동산입니다.';
  }
  return null;
}

String? _districtIdForOwnedProperty(OwnedRealEstate? property) {
  final asset = property?.marketAsset;
  if (asset == null) return null;
  return businessDistrictIdForRealEstateRegion(
    asset.region,
    province: asset.province,
  );
}

bool _isCommercialPremise(OwnedRealEstate property) =>
    property.assetType == RealEstateAssetType.commercialUnit ||
    property.assetType == RealEstateAssetType.officeBuilding;

List<String> _appendProcessed(List<String> ids, String sourceId) =>
    ids.contains(sourceId) ? ids : [...ids, sourceId];

BusinessEventInstance? _pendingEventById(
  BusinessPortfolioState portfolio,
  String eventId,
) {
  for (final event in portfolio.pendingEvents) {
    if (event.id == eventId) return event;
  }
  return null;
}

List<BusinessEventInstance> _replacePendingEvent(
  List<BusinessEventInstance> events,
  BusinessEventInstance replacement,
) => [
  for (final event in events)
    if (event.id == replacement.id) replacement else event,
];

BusinessPortfolioState _archiveBusinessEvents(
  BusinessPortfolioState portfolio,
  String businessId,
  String reason,
) {
  var next = portfolio;
  final matching = portfolio.pendingEvents
      .where((event) => event.businessId == businessId)
      .toList(growable: false);
  for (final event in matching) {
    next = next.archiveEvent(
      event.copyWith(
        status: BusinessEventStatus.expired,
        outcomeTitle: '${event.title} · 종료',
        outcomeBody: reason,
      ),
    );
  }
  return next;
}

PersonalFinanceState _markPropertyInUse(
  PersonalFinanceState finance,
  String propertyId,
  String businessName,
) {
  final assets = [...finance.realEstate];
  final index = assets.indexWhere((asset) => asset.id == propertyId);
  if (index < 0) return finance;
  assets[index] = assets[index].copyWith(
    lastRentalEvent: '$businessName 직영점 사용 중 · 임대수익 없음',
  );
  return finance.copyWith(realEstate: assets);
}

PersonalFinanceState _releaseProperty(
  PersonalFinanceState finance,
  String propertyId,
  String businessName,
) {
  final assets = [...finance.realEstate];
  final index = assets.indexWhere((asset) => asset.id == propertyId);
  if (index < 0) return finance;
  assets[index] = assets[index].copyWith(
    lastRentalEvent: '$businessName 영업 종료 · 공실 전환',
  );
  return finance.copyWith(realEstate: assets);
}
