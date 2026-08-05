import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/cohort_standing_events.dart';
import 'package:millennium_capital/game/cohort_withdrawal_crisis.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/life_calendar.dart';
import 'package:millennium_capital/game/market_clock.dart';
import 'package:millennium_capital/game/market_data.dart';
import 'package:millennium_capital/game/market_quote.dart';
import 'package:millennium_capital/game/order_book.dart';
import 'package:millennium_capital/game/shareholder_governance.dart';
import 'package:millennium_capital/game/shareholder_governance_engine.dart';
import 'package:millennium_capital/game/weekend_activity.dart';
import 'package:millennium_capital/game/weekly_portfolio_review.dart';

void main() {
  const engine = GameEngine();
  const governance = ShareholderGovernanceEngine();
  const initialCapital = 100000000000;

  test(
    '1,000억원으로 1년간 분할매수해 주주권부터 인수와 경영까지 진행한다',
    () async {
      final universe = await FictionalMarketUniverse.load(
        seed: 'one-year-gradual-takeover-audit',
        throughDate: DateTime(2000, 12, 31),
        forceRefresh: true,
      );
      var state = engine.createNewGame(
        '1년 분할인수 감사',
        worldSeed: 'one-year-gradual-takeover-audit',
        initialCash: initialCapital,
      );
      // 인수자금·주주행동 비용을 위해 150억원은 회사계좌에 남긴다.
      state = state.copyWith(brokerageCash: 85000000000);

      final selectionDate = DateTime(2000, 1, 3);
      final firstUniverse = universe.asOf(selectionDate);
      final candidates = <({FictionalMarketAsset asset, int marketCap})>[];
      for (final asset in firstUniverse.assets.where(
        (item) => item.isDomestic,
      )) {
        final fullAsset = universe.assets.firstWhere(
          (item) => item.id == asset.id,
        );
        if (fullAsset.delistedOn != null) continue;
        final quote = asset.quoteAtOrBefore(selectionDate);
        final shares = asset.sharesOutstandingAtOrBefore(selectionDate);
        if (quote == null || shares == null || shares <= 0) continue;
        candidates.add((
          asset: asset,
          marketCap: (quote.close * shares).round(),
        ));
      }
      candidates.sort(
        (left, right) => left.marketCap.compareTo(right.marketCap),
      );
      expect(candidates, isNotEmpty);
      final target = candidates.first.asset;
      final initialTargetMarketCap = candidates.first.marketCap;
      final cheapest = candidates
          .take(5)
          .map((row) => '${row.asset.name}:${_eok(row.marketCap)}억원');

      var tradingDays = 0;
      var buyAttempts = 0;
      var filledBuys = 0;
      var boughtShares = 0.0;
      var buyNotional = 0;
      var tenderAttempted = false;
      var tenderSucceeded = false;
      var meetingAttendances = 0;
      var votes = 0;
      var proposals = 0;
      var auditRequested = false;
      var proxiesSolicited = false;
      var extraordinaryCalled = false;
      var managementChoices = 0;
      var minimumCash = state.cash;
      var maximumOwnership = 0.0;
      var inventoryChecks = 0;
      double? firstFillPrice;
      double? lastFillPrice;
      var highestFillPrice = 0.0;
      int? controlDay;
      final reachedRights = <ShareholderRight, int>{};
      final ownershipMilestones = <double, int>{};
      final actionFailures = <String>[];

      for (var elapsed = 0; elapsed < 365; elapsed += 1) {
        final dayUniverse = universe.asOf(state.currentDate);
        state = governance.processDay(state, dayUniverse);

        var decisionGuard = 0;
        while (state.pendingDecisions.isNotEmpty) {
          final decision = state.pendingDecisions.first;
          final affordable = decision.options.where(
            (option) => option.cashCost <= state.bankCash,
          );
          expect(affordable, isNotEmpty, reason: '${decision.id} 진행 불가');
          state = engine.resolveDecision(
            state,
            decision.id,
            affordable.first.id,
          );
          decisionGuard += 1;
          expect(decisionGuard, lessThan(100));
        }

        final targetAsset = dayUniverse.assets
            .where((asset) => asset.id == target.id)
            .firstOrNull;
        if (targetAsset != null && isMarketTradingDay(state.currentDate)) {
          tradingDays += 1;
          // 매 거래일 30분 간격으로 8회, 발행주식의 1%씩 요청한다.
          // 실제 체결량은 각 시점의 호가 잔량과 1회 주문한도가 제한한다.
          for (
            var slice = 0;
            slice < 8 && state.availableBrokerageCash > 1000000;
            slice += 1
          ) {
            state = state.copyWith(
              marketMinute: krxOpenMinute + 30 + slice * 30,
            );
            state = governance.sync(state, dayUniverse);
            final company = state.shareholderGovernance.companyById(target.id);
            final outstanding = targetAsset.sharesOutstandingAtOrBefore(
              state.currentDate,
            );
            final quote = resolveMarketTradeQuote(
              dayUniverse,
              state,
              target.id,
            );
            if (outstanding == null ||
                quote == null ||
                (company?.ownershipPct ?? 0) >= 50.01) {
              break;
            }
            final inventory = gameMarketInventoryProfile(
              assetId: target.id,
              day: state.day,
              referencePrice: quote.unitPrice,
              simulationSeed: state.simulationSeed,
              sharesOutstanding: outstanding,
              playerOwnedUnits: company?.ownedShares ?? 0,
              playerTenderAcquiredUnits: company?.tenderAcquiredShares ?? 0,
            );
            expect(inventory.conservedShares, outstanding);
            expect(
              (company?.ownedShares ?? 0) +
                  state.pendingBuyReservedUnits(target.id),
              lessThanOrEqualTo(outstanding + 0.000001),
            );
            inventoryChecks += 1;
            final remaining = math.max(
              0,
              outstanding - (company?.ownedShares.ceil() ?? 0),
            );
            final requested = math.min(
              remaining,
              math.max(1, (outstanding * 0.01).round()),
            );
            if (requested <= 0) break;
            buyAttempts += 1;
            final previousRaw = targetAsset.unadjustedReferenceCloseFor(
              quote.quoteDate,
            );
            final previousClose =
                targetAsset.marketReferenceCloseOn(
                  DateTime.parse(quote.quoteDate),
                  previousClose: previousRaw,
                ) *
                state.shareholderGovernance.priceMultiplierFor(
                  target.id,
                  state.day - 1,
                );
            final result = engine.executeTrade(
              state,
              TradeOrder(
                side: TradeSide.buy,
                assetId: target.id,
                symbol: targetAsset.code,
                name: targetAsset.name,
                market: targetAsset.market,
                currency: targetAsset.currency,
                quantity: requested.toDouble(),
                unitPrice: quote.unitPrice,
                quoteDate: quote.quoteDate,
                marketMinute: quote.marketMinute,
                isTradingDay: quote.isTradingDay,
                previousClose: previousClose,
                maximumPositionUnits: outstanding,
                isIpoFirstTradingDay: targetAsset.isIpoFirstTradingDay(
                  state.currentDate,
                ),
                microstructureFrame: buyAttempts,
              ),
            );
            if (result.success && result.filledQuantity > 0) {
              state = governance.sync(result.state, dayUniverse);
              filledBuys += 1;
              boughtShares += result.filledQuantity;
              buyNotional += result.notional;
              firstFillPrice ??= result.averageFillPrice;
              lastFillPrice = result.averageFillPrice;
              highestFillPrice = math.max(
                highestFillPrice,
                result.averageFillPrice,
              );
            } else {
              actionFailures.add(
                '${state.currentDate.toIso8601String().split('T').first} 매수: ${result.message}',
              );
            }
          }

          var company = state.shareholderGovernance.companyById(target.id);
          if (!tenderAttempted &&
              state.day >= 240 &&
              company != null &&
              company.ownershipPct >= 20 &&
              company.ownershipPct < 50.01) {
            tenderAttempted = true;
            final rawPrice = targetAsset
                .quoteAtOrBefore(state.currentDate)!
                .close;
            final price = state.shareholderGovernance.adjustedPrice(
              target.id,
              state.day,
              rawPrice,
            );
            final requiredShares = math.max(
              0,
              (company.sharesOutstanding * 0.51 - company.ownedShares).ceil(),
            );
            final estimatedCost = (requiredShares * price * 1.25).round();
            final transferNeeded = math.max(
              0,
              estimatedCost - state.bankCash + 1000000,
            );
            if (transferNeeded > 0) {
              final transfer = engine.transferBrokerageCash(
                state,
                amount: math.min(
                  transferNeeded,
                  state.withdrawableBrokerageCash,
                ),
                deposit: false,
              );
              if (transfer.success) state = transfer.state;
            }
            final tender = governance.launchTenderOffer(
              state,
              asset: targetAsset,
              targetOwnershipPct: 51,
              premiumBps: 2500,
            );
            if (tender.success) {
              tenderSucceeded = true;
              state = governance.sync(tender.state, dayUniverse);
            } else {
              actionFailures.add('공개매수: ${tender.message}');
            }
            company = state.shareholderGovernance.companyById(target.id);
          }
        }

        var company = state.shareholderGovernance.companyById(target.id);
        if (company != null) {
          maximumOwnership = math.max(maximumOwnership, company.ownershipPct);
          for (final threshold in const <double>[
            1,
            3,
            5,
            10,
            20,
            33.34,
            50.01,
          ]) {
            if (company.ownershipPct >= threshold) {
              ownershipMilestones.putIfAbsent(threshold, () => state.day);
            }
          }
          for (final right in company.rights) {
            reachedRights.putIfAbsent(right, () => state.day);
          }
          if (company.isControlled) controlDay ??= state.day;

          final meetings = state.shareholderGovernance
              .meetingsFor(target.id)
              .where(
                (meeting) => meeting.status != ShareholderMeetingStatus.closed,
              )
              .toList();
          if (company.rights.contains(ShareholderRight.submitProposal) &&
              meetings.isNotEmpty &&
              !meetings.first.agendas.any(
                (agenda) => agenda.proposedByPlayer,
              )) {
            final result = governance.submitProposal(
              state,
              assetId: target.id,
              type: ShareholderAgendaType.strategy,
            );
            if (result.success) {
              state = result.state;
              proposals += 1;
            }
          }

          final openMeetings = state.shareholderGovernance
              .meetingsFor(target.id)
              .where(
                (meeting) => meeting.status == ShareholderMeetingStatus.open,
              )
              .toList();
          for (var meeting in openMeetings) {
            if (!meeting.attended) {
              final result = governance.attendMeeting(state, meeting.id);
              if (result.success) {
                state = result.state;
                meetingAttendances += 1;
                meeting = state.shareholderGovernance
                    .meetingsFor(target.id)
                    .firstWhere((item) => item.id == meeting.id);
              }
            }
            for (final agenda in meeting.agendas.where(
              (agenda) => agenda.vote == null,
            )) {
              final result = governance.vote(
                state,
                meetingId: meeting.id,
                agendaId: agenda.id,
                choice: ShareholderVoteChoice.support,
              );
              if (result.success) {
                state = result.state;
                votes += 1;
              }
            }
          }

          company = state.shareholderGovernance.companyById(target.id)!;
          if (!auditRequested &&
              company.rights.contains(ShareholderRight.requestAudit)) {
            final result = governance.requestAudit(state, target.id);
            auditRequested = result.success;
            if (result.success) state = result.state;
          }
          company = state.shareholderGovernance.companyById(target.id)!;
          if (!proxiesSolicited &&
              company.rights.contains(ShareholderRight.solicitProxies)) {
            final cap = targetAsset == null
                ? initialTargetMarketCap
                : ((targetAsset.quoteAtOrBefore(state.currentDate)?.close ??
                              0) *
                          company.sharesOutstanding)
                      .round();
            final result = governance.solicitProxies(
              state,
              assetId: target.id,
              marketCap: cap,
            );
            proxiesSolicited = result.success;
            if (result.success) state = result.state;
          }
          company = state.shareholderGovernance.companyById(target.id)!;
          if (!extraordinaryCalled &&
              state.day >= 180 &&
              company.rights.contains(
                ShareholderRight.callExtraordinaryMeeting,
              )) {
            final result = governance.callExtraordinaryMeeting(
              state,
              target.id,
            );
            extraordinaryCalled = result.success;
            if (result.success) state = result.state;
          }

          company = state.shareholderGovernance.companyById(target.id)!;
          if (company.isControlled) {
            final agenda = governance.managementAgendaFor(state, targetAsset!);
            if (agenda != null &&
                company.lastManagementQuarter != agenda.quarterKey) {
              final option =
                  agenda.options[managementChoices % agenda.options.length];
              final result = governance.executeManagementDecision(
                state,
                asset: targetAsset,
                optionId: option.id,
              );
              if (result.success) {
                state = result.state;
                managementChoices += 1;
              } else {
                actionFailures.add('경영결정: ${result.message}');
              }
            }
          }
        }

        if (isMarketTradingDay(state.currentDate)) {
          state = state.copyWith(marketMinute: krxCloseMinute);
          final settlement = engine.settleCohortInvestmentDay(
            state,
            universe: dayUniverse,
          );
          expect(
            settlement.success,
            isTrue,
            reason: '${state.currentDate} 투자결산: ${settlement.message}',
          );
          state = settlement.state;
          final acknowledged = engine.acknowledgeCohortInvestmentReport(state);
          expect(acknowledged.success, isTrue);
          state = acknowledged.state;
        }

        state = openCohortWithdrawalCrisis(state);
        final crisis = activeCohortWithdrawalCrisis(state);
        if (crisis != null && state.day >= crisis.deadlineDay) {
          final result = respondToCohortWithdrawal(
            state,
            CohortWithdrawalResponse.respectRight,
          );
          expect(result.success, isTrue);
          state = result.state;
        }
        final standing = pendingCohortStandingEvent(state);
        if (standing != null) {
          state = acknowledgeCohortStandingEvent(state, standing);
        }
        if (weeklyPortfolioReviewDue(state)) {
          state = completeWeeklyPortfolioReview(
            state,
            action: WeeklyPortfolioReviewAction.research,
            assetId: target.id,
            assetName: target.name,
            automatic: true,
          );
        }
        if (isWeekendOutingDay(state.currentDate) &&
            !weekendScheduleCompleteForState(state)) {
          final result = engine.completeWeekendActivity(
            state,
            const WeekendActivityRequest(activityId: 'rest'),
          );
          expect(result.success, isTrue);
          state = result.state;
        }
        if (!state.relationships.completedEveningForDay(state.day)) {
          final result = engine.restDuringRelationshipEvening(state);
          expect(result.success, isTrue);
          state = result.state;
        }

        minimumCash = math.min(minimumCash, state.cash);
        expect(state.cash, greaterThanOrEqualTo(0));
        expect(state.brokerageCash, greaterThanOrEqualTo(0));
        expect(state.bankCash, greaterThanOrEqualTo(0));
        if (elapsed % 30 == 0) {
          state = GameState.fromJson(state.toJson());
        }

        final next = engine.advanceOneDay(state);
        expect(next.day, state.day + 1);
        final nextUniverse = universe.asOf(next.currentDate);
        state = engine.applyCorporateActions(
          next,
          nextUniverse.corporateActionsOn(next.currentDate),
        );
        state = governance
            .processDay(state, nextUniverse)
            .copyWith(marketMinute: marketDayStartMinute);
      }

      final finalUniverse = universe.asOf(state.currentDate);
      final closePrices = <String, double>{};
      for (final asset in finalUniverse.assets) {
        final quote = asset.quoteAtOrBefore(state.currentDate);
        if (quote == null) continue;
        closePrices[asset.id] = state.shareholderGovernance.adjustedPrice(
          asset.id,
          state.day,
          quote.close,
        );
      }
      final endingNetWorth = state.cash + state.portfolioValue(closePrices);
      final finalCompany = state.shareholderGovernance.companyById(target.id)!;
      final completedManagement = finalCompany.managementDecisions.where(
        (decision) =>
            !decision.isExecuting && !decision.title.startsWith('주주총회'),
      );

      // ignore: avoid_print
      print('''
=== 1년 분할인수 감사 ===
최저 시가총액 5개: ${cheapest.join(', ')}
대상: ${target.name} (${target.sector}) · 초기 시총 ${_eok(initialTargetMarketCap)}억원
매수: 거래일 $tradingDays일 · $buyAttempts회 시도 / $filledBuys회 체결 · ${boughtShares.round()}주 · ${_eok(buyNotional)}억원
지분: 최대 ${maximumOwnership.toStringAsFixed(2)}% · 최종 ${finalCompany.ownershipPct.toStringAsFixed(2)}%
지분 단계 도달일: ${ownershipMilestones.entries.map((entry) => '${entry.key}%=${entry.value}일').join(', ')}
주주행동: 제안 $proposals · 주총참석 $meetingAttendances · 표결 $votes · 감사 $auditRequested · 위임 $proxiesSolicited · 임시주총 $extraordinaryCalled
공개매수: 시도 $tenderAttempted · 성공 $tenderSucceeded · 경영권 확보일 ${controlDay ?? '-'}
경영결정: $managementChoices회 · 완료 ${completedManagement.length}회 · 실행중 ${finalCompany.managementDecisions.where((item) => item.isExecuting).length}회
회사 KPI: 기술 ${finalCompany.innovation} / 운영 ${finalCompany.operations} / 신뢰 ${finalCompany.brandTrust} / 조직 ${finalCompany.workforce}
시장평가: ${((finalCompany.priceMultiplierAt(state.day) - 1) * 100).toStringAsFixed(2)}%
주식원장: $inventoryChecks회 보존검사 · 공개매수 취득 ${finalCompany.tenderAcquiredShares.round()}주
체결가: 최초 ${firstFillPrice?.round() ?? 0}원 · 최종 ${lastFillPrice?.round() ?? 0}원 · 최고 ${highestFillPrice.round()}원
현금: 최저 ${_eok(minimumCash)}억원 · 최종 ${_eok(state.cash)}억원
총자산: 시작 ${_eok(initialCapital)}억원 · 종료 ${_eok(endingNetWorth)}억원 · 수익률 ${((endingNetWorth / initialCapital - 1) * 100).toStringAsFixed(2)}%
실패/거절: ${actionFailures.isEmpty ? '없음' : actionFailures.join(' | ')}
========================
''');

      expect(state.currentDate, DateTime(2000, 12, 31));
      expect(filledBuys, greaterThanOrEqualTo(20));
      expect(inventoryChecks, greaterThanOrEqualTo(100));
      expect(boughtShares, greaterThan(0));
      expect(ownershipMilestones.containsKey(1), isTrue);
      expect(ownershipMilestones.containsKey(20), isTrue);
      expect(tenderAttempted, isTrue);
      expect(tenderSucceeded, isTrue);
      expect(finalCompany.isControlled, isTrue);
      expect(managementChoices, greaterThanOrEqualTo(1));
      expect(endingNetWorth, greaterThan(0));
      expect(GameState.fromJson(state.toJson()).toJson(), state.toJson());
    },
    timeout: const Timeout(Duration(minutes: 8)),
  );
}

int _eok(num won) => (won / 100000000).round();
