import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/business_engine.dart';
import 'package:millennium_capital/game/business_simulation.dart';
import 'package:millennium_capital/game/business_state.dart';
import 'package:millennium_capital/game/game_engine.dart';

void main() {
  test(
    'ten-year business replay closes a structurally losing v3 shop',
    () {
      const gameEngine = GameEngine();
      const businessEngine = LocalBusinessEngine();
      const seed = 'codex-ten-year-cross-asset-audit-v1';
      const initialCash = 4000000000;
      const listingId =
          'business-listing-2000-01-convenienceStore-university-'
          'gyeonggi_uijeongbu_station-5';
      var state = gameEngine
          .createNewGame(
            '10년 사업 재검증',
            initialCash: initialCash,
            worldSeed: seed,
          )
          .copyWith(brokerageCash: 0, decisions: const []);
      final listing = generateBusinessListings(
        worldSeed: seed,
        asOfDate: state.currentDate,
        count: LocalBusinessEngine.listingCount,
      ).singleWhere((candidate) => candidate.id == listingId);
      final opened = businessEngine.openOrAcquire(
        state,
        BusinessLaunchRequest(
          listingId: listing.id,
          businessName: '10년 편의점 재검증',
          locationId: listing.locationId,
          premiseMode: BusinessPremiseMode.leased,
          policy: BusinessOperatingPolicy.neutral,
        ),
      );
      expect(opened.success, isTrue, reason: opened.message);
      state = opened.state;
      final businessId = state.businesses.businesses.single.id;
      DateTime? closureDate;
      var stalledDays = 0;

      while (state.currentDate.isBefore(DateTime(2010, 1, 1))) {
        final beforeDay = state.day;
        state = gameEngine.advanceOneDay(state.copyWith(decisions: const []));
        if (state.day == beforeDay) {
          stalledDays += 1;
          break;
        }
        final business = state.businesses.businessById(businessId)!;
        if (closureDate == null && business.status == BusinessStatus.closed) {
          closureDate = state.currentDate;
        }
      }

      final business = state.businesses.businessById(businessId)!;
      final businessCashFlow = state.ledger
          .where((entry) => entry.sourceId.startsWith('business-'))
          .fold<int>(0, (sum, entry) => sum + entry.amount);
      final result = <String, Object?>{
        'seed': seed,
        'startDate': '2000-01-01',
        'endDate': state.currentDate.toIso8601String().split('T').first,
        'listingId': listing.id,
        'status': business.status.name,
        'closureDate': closureDate?.toIso8601String().split('T').first,
        'settledMonths': business.consecutiveLossMonths,
        'storedStatements': business.statements.length,
        'operatingProfit': business.totalProfit,
        'businessNetCashFlow': businessCashFlow,
        'bookValue': business.bookValue,
        'accountsPayable': business.accountsPayable,
        'eventsResolved': state.businesses.eventHistory.length,
        'eventsPending': state.businesses.pendingEvents.length,
        'closures': state.businesses.totalClosures,
        'finalCash': state.cash,
        'stalledDays': stalledDays,
      };
      // ignore: avoid_print
      print('TEN_YEAR_BUSINESS_REPLAY_JSON=${jsonEncode(result)}');

      expect(stalledDays, 0);
      expect(state.currentDate, DateTime(2010, 1, 1));
      expect(business.status, BusinessStatus.closed);
      expect(closureDate, isNotNull);
      expect(
        closureDate!.difference(DateTime(2000, 1, 1)).inDays,
        lessThan(550),
      );
      expect(state.businesses.totalClosures, 1);
      expect(business.accountsPayable, 0);
      expect(business.bookValue, 0);
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
