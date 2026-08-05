import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/business_districts.dart';
import 'package:millennium_capital/game/business_engine.dart';
import 'package:millennium_capital/game/business_simulation.dart';
import 'package:millennium_capital/game/business_state.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/main.dart';

void main() {
  const gameEngine = GameEngine();
  const businessEngine = LocalBusinessEngine();

  GameState newState() => gameEngine
      .createNewGame(
        '동네사업 UI 테스트 회사',
        initialCash: 1000000000,
        worldSeed: 'business-ui-test-world',
      )
      .copyWith(brokerageCash: 0);

  FinanceActionResult unavailable(GameState state) => FinanceActionResult(
    state: state,
    success: false,
    message: '테스트에서 실행하지 않는 동작입니다.',
  );

  FinanceActionResult asFinance(BusinessActionResult result) =>
      FinanceActionResult(
        state: result.state,
        success: result.success,
        message: result.message,
        cashDelta: result.cashDelta,
      );

  Widget businessScreen(GameState state) => BusinessManagementScreen(
    state: state,
    onAcquire:
        ({
          required listingId,
          required businessName,
          required locationId,
          required premiseMode,
          linkedRealEstateId,
          required policy,
        }) async => unavailable(state),
    onUpdatePolicy: (_, _) async => unavailable(state),
    onInvest: (_, _) async => unavailable(state),
    onClose: (_) async => unavailable(state),
    onChooseEvent: (_, _) async => unavailable(state),
  );

  Future<void> usePhoneSurface(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  Future<void> openDistrictTab(WidgetTester tester) async {
    final tab = find.byKey(const Key('business-tab-districts'));
    await tester.ensureVisible(tab);
    await tester.pumpAndSettle();
    await tester.tap(tab);
    await tester.pumpAndSettle();
  }

  for (final size in <Size>[const Size(390, 844), const Size(360, 800)]) {
    testWidgets(
      '${size.width.toInt()}px home PC exposes four current apps and opens management',
      (tester) async {
        await usePhoneSurface(tester, size);
        final state = newState();

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => HomeComputerScreen(
                state: state,
                onOpenStockMarket: (current) async => current,
                onOpenCompanyManagement: (current) async => current,
                onOpenRealEstate: (current) async => current,
                onOpenBusiness: (current) async {
                  await Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => businessScreen(current),
                    ),
                  );
                  return current;
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final stockApp = find.byKey(const Key('computer-stock-market-app'));
        final companyApp = find.byKey(
          const Key('computer-company-management-app'),
        );
        final realEstateApp = find.byKey(const Key('computer-real-estate-app'));
        final businessApp = find.byKey(const Key('computer-business-app'));
        final apps = <Finder>[stockApp, companyApp, realEstateApp, businessApp];

        for (final app in apps) {
          expect(app, findsOneWidget);
          expect(app.hitTestable(), findsOneWidget);
          final rect = tester.getRect(app);
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(size.width));
          expect(rect.top, greaterThanOrEqualTo(0));
          expect(rect.bottom, lessThanOrEqualTo(size.height));
        }
        expect(tester.getSize(realEstateApp), tester.getSize(stockApp));
        expect(tester.getSize(companyApp), tester.getSize(stockApp));
        expect(tester.getSize(businessApp), tester.getSize(stockApp));

        final stockCenter = tester.getCenter(stockApp);
        final companyCenter = tester.getCenter(companyApp);
        final realEstateCenter = tester.getCenter(realEstateApp);
        final businessCenter = tester.getCenter(businessApp);
        expect(stockCenter.dy, closeTo(companyCenter.dy, 0.5));
        expect(realEstateCenter.dy, closeTo(businessCenter.dy, 0.5));
        expect(realEstateCenter.dy, greaterThan(stockCenter.dy));
        expect(stockCenter.dx, lessThan(companyCenter.dx));
        expect(tester.takeException(), isNull);

        await tester.tap(businessApp);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(
          find.byKey(const Key('business-management-screen')),
          findsOneWidget,
        );
        expect(find.text('PC방'), findsWidgets);
        expect(find.text('노래방'), findsWidgets);
        expect(
          find.byKey(const Key('business-listing-district-filter')),
          findsOneWidget,
        );
        for (final tab in <String>['인수·창업', '내 점포', '사건함', '월별 손익', '상권판세']) {
          expect(find.text(tab), findsOneWidget);
        }
        expect(tester.takeException(), isNull);

        await openDistrictTab(tester);
        final ranked = rankBusinessDistricts(
          asOf: state.currentDate,
          worldSeed: state.simulationSeed,
        );
        final selectedId = ranked.first.snapshot.districtId;
        expect(
          find.byKey(const Key('business-district-board')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('business-district-as-of')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('business-district-select')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('business-district-ranking')),
          findsOneWidget,
        );
        expect(
          find.byKey(Key('business-district-phase-$selectedId')),
          findsOneWidget,
        );
        expect(
          find.byKey(Key('business-district-metrics-$selectedId')),
          findsOneWidget,
        );
        for (final key in const [
          'business-district-board',
          'business-district-as-of',
          'business-district-select',
          'business-district-ranking',
        ]) {
          final rect = tester.getRect(find.byKey(Key(key)));
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(size.width));
        }
        expect(tester.takeException(), isNull);

        Navigator.of(
          tester.element(find.byKey(const Key('business-management-screen'))),
        ).pop();
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('home-computer-screen')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('home PC forwards each app result to the next app', (
    tester,
  ) async {
    await usePhoneSurface(tester, const Size(390, 844));
    final initial = newState();
    GameState? companyInput;
    GameState? realEstateInput;
    GameState? businessInput;

    await tester.pumpWidget(
      MaterialApp(
        home: HomeComputerScreen(
          state: initial,
          onOpenStockMarket: (current) async =>
              current.copyWith(cash: current.cash + 101),
          onOpenCompanyManagement: (current) async {
            companyInput = current;
            return current.copyWith(cash: current.cash + 151);
          },
          onOpenRealEstate: (current) async {
            realEstateInput = current;
            return current.copyWith(cash: current.cash + 202);
          },
          onOpenBusiness: (current) async {
            businessInput = current;
            return current.copyWith(cash: current.cash + 303);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('computer-stock-market-app')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('computer-company-management-app')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('computer-real-estate-app')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('computer-business-app')));
    await tester.pumpAndSettle();
    expect(companyInput?.cash, initial.cash + 101);
    expect(realEstateInput?.cash, initial.cash + 252);
    expect(businessInput?.cash, initial.cash + 454);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'district board exposes only as-of history and current signals at 360px',
    (tester) async {
      await usePhoneSurface(tester, const Size(360, 800));
      final initial = newState();
      final targetDate = DateTime(2026, 6, 30);
      final state = initial.copyWith(
        day: targetDate.difference(initial.campaignStartDate).inDays + 1,
      );
      final ranked = rankBusinessDistricts(
        asOf: state.currentDate,
        worldSeed: state.simulationSeed,
      );
      final selected = ranked.first.snapshot;

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.2)),
            child: child!,
          ),
          home: businessScreen(state),
        ),
      );
      await tester.pumpAndSettle();
      await openDistrictTab(tester);

      final board = find.byKey(const Key('business-district-board'));
      final scrollable = find.descendant(
        of: board,
        matching: find.byType(Scrollable),
      );
      expect(board, findsOneWidget);
      expect(find.textContaining('현재까지 공개된 정보'), findsOneWidget);
      expect(
        find.byKey(Key('business-district-phase-${selected.districtId}')),
        findsOneWidget,
      );
      expect(
        find.byKey(Key('business-district-metrics-${selected.districtId}')),
        findsOneWidget,
      );
      expect(find.text('활력'), findsOneWidget);
      expect(find.text('임대료 부담'), findsOneWidget);
      expect(find.text('경쟁 강도'), findsOneWidget);
      expect(find.text('공실'), findsOneWidget);

      final ranking = find.byKey(const Key('business-district-ranking'));
      await tester.tap(ranking);
      await tester.pumpAndSettle();
      final firstRank = find.byKey(
        Key('business-district-rank-${selected.districtId}'),
      );
      expect(firstRank, findsOneWidget);
      expect(tester.getRect(firstRank).right, lessThanOrEqualTo(360));

      final signals = find.byKey(
        Key('business-district-signals-${selected.districtId}'),
      );
      await tester.scrollUntilVisible(
        signals,
        240,
        scrollable: scrollable.first,
      );
      await tester.pumpAndSettle();
      expect(signals, findsOneWidget);
      for (final signal in selected.currentSignals) {
        expect(find.textContaining(signal), findsOneWidget);
      }

      final historyToggle = find.byKey(
        Key('business-district-history-toggle-${selected.districtId}'),
      );
      await tester.scrollUntilVisible(
        historyToggle,
        220,
        scrollable: scrollable.first,
      );
      await tester.pumpAndSettle();
      await tester.tap(historyToggle);
      await tester.pumpAndSettle();

      final revealed = selected.revealedEvents.take(6).toList(growable: false);
      for (final event in revealed) {
        expect(event.revealedOn.isAfter(state.currentDate), isFalse);
        expect(
          find.byKey(
            Key('business-district-history-${selected.districtId}-${event.id}'),
          ),
          findsOneWidget,
        );
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'acquisition refreshes and owned shop expands with detailed controls',
    (tester) async {
      await usePhoneSurface(tester, const Size(360, 800));
      final state = newState();
      final listing = generateBusinessListings(
        worldSeed: state.simulationSeed,
        asOfDate: state.currentDate,
        count: LocalBusinessEngine.listingCount,
      ).first;
      var latestState = state;
      var acquisitionCallbackCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: BusinessManagementScreen(
            state: state,
            onAcquire:
                ({
                  required listingId,
                  required businessName,
                  required locationId,
                  required premiseMode,
                  linkedRealEstateId,
                  required policy,
                }) async {
                  acquisitionCallbackCount += 1;
                  final result = businessEngine.openOrAcquire(
                    latestState,
                    BusinessLaunchRequest(
                      listingId: listingId,
                      businessName: businessName,
                      locationId: locationId,
                      premiseMode: premiseMode,
                      policy: policy,
                      linkedRealEstateId: linkedRealEstateId,
                    ),
                  );
                  if (result.success) latestState = result.state;
                  return asFinance(result);
                },
            onUpdatePolicy: (_, _) async => unavailable(latestState),
            onInvest: (_, _) async => unavailable(latestState),
            onClose: (_) async => unavailable(latestState),
            onChooseEvent: (_, _) async => unavailable(latestState),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final listingCard = find.byKey(Key('business-listing-${listing.id}'));
      final listingsScrollable = find.descendant(
        of: find.byKey(const Key('business-listings-panel')),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        listingCard,
        220,
        scrollable: listingsScrollable.first,
      );
      await tester.pump();
      await tester.tap(listingCard);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('business-listing-review')), findsOneWidget);
      expect(
        find.byKey(Key('business-listing-fit-${listing.id}')),
        findsOneWidget,
      );

      final acquireConfirm = find.byKey(const Key('business-acquire-confirm'));
      final reviewScrollable = find.descendant(
        of: find.byKey(const Key('business-listing-review')),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        acquireConfirm,
        250,
        scrollable: reviewScrollable.first,
      );
      await tester.pump();
      expect(find.text('6축 운영계획'), findsOneWidget);
      for (final axis in BusinessPolicyAxis.values) {
        expect(find.text(axis.label), findsOneWidget);
        expect(find.byKey(Key('business-plan-${axis.name}')), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      expect(acquireConfirm.hitTestable(), findsOneWidget);
      await tester.tap(acquireConfirm);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('business-acquire-submit')), findsOneWidget);
      await tester.tap(find.byKey(const Key('business-acquire-submit')));
      await tester.pumpAndSettle();

      final acquiredId = 'local-${listing.id}';
      expect(acquisitionCallbackCount, 1);
      expect(latestState.businesses.businessById(acquiredId), isNotNull);
      await tester.scrollUntilVisible(
        find.text('사업 운전자금'),
        -250,
        scrollable: listingsScrollable.first,
      );
      await tester.pump();
      expect(find.text('영업 점포'), findsOneWidget);
      expect(find.text('1곳'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const Key('business-tab-owned')));
      await tester.pumpAndSettle();
      final ownedCard = find.byKey(Key('business-owned-$acquiredId'));
      expect(ownedCard, findsOneWidget);
      expect(ownedCard.hitTestable(), findsOneWidget);
      await tester.tap(ownedCard);
      await tester.pumpAndSettle();

      expect(find.text('6축 운영계획'), findsOneWidget);
      for (final axis in BusinessPolicyAxis.values) {
        expect(find.text(axis.label), findsOneWidget);
        expect(
          find.byKey(Key('business-policy-$acquiredId-${axis.name}')),
          findsOneWidget,
        );
      }
      expect(
        find.byKey(Key('business-policy-save-$acquiredId')),
        findsOneWidget,
      );
      expect(find.text('점포 투자'), findsOneWidget);
      for (final kind in BusinessInvestmentKind.values) {
        expect(
          find.byKey(Key('business-invest-$acquiredId-${kind.name}')),
          findsOneWidget,
        );
      }
      expect(find.byKey(Key('business-close-$acquiredId')), findsOneWidget);
      expect(find.text('폐업 및 정산'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    '360px text 1.2 keeps all tabs, event confirmation, and statements usable',
    (tester) async {
      await usePhoneSurface(tester, const Size(360, 800));
      final base = newState();
      final listing = generateBusinessListings(
        worldSeed: base.simulationSeed,
        asOfDate: base.currentDate,
        count: LocalBusinessEngine.listingCount,
      ).first;
      const statement = BusinessMonthlyStatement(
        businessId: 'mobile-audit-shop',
        year: 2000,
        month: 1,
        operatingDays: 31,
        customerCount: 1240,
        grossSales: 18600000,
        variableCosts: 6700000,
        payroll: 3200000,
        rent: 1400000,
        utilities: 900000,
        marketing: 500000,
        maintenance: 350000,
        eventCosts: 200000,
        taxes: 160000,
        netProfit: 5190000,
        policySnapshot: BusinessOperatingPolicy.neutral,
        sourceId: 'business-month-mobile-audit-shop-2000-01',
      );
      final business =
          createOwnedBusinessFromListing(
            listing: listing,
            businessId: 'mobile-audit-shop',
            name: '모바일 감사 점포',
            acquiredDay: 1,
            openedDate: base.currentDate,
          ).copyWith(
            statements: const [statement],
            totalSales: statement.grossSales,
            totalProfit: statement.netProfit,
          );
      const choice = BusinessEventChoice(
        id: 'repair-now',
        label: '즉시 수리한다',
        description: '비용을 내고 영업 중단 위험을 줄인다.',
        upfrontCost: 300000,
        immediateReputationDelta: 1,
        immediateRiskDelta: -4,
        successChanceBps: 7000,
        successCashDelta: 500000,
        successDemandDeltaBps: 300,
        successReputationDelta: 2,
        failureCashDelta: -200000,
        failureDemandDeltaBps: -200,
        failureReputationDelta: -1,
      );
      const event = BusinessEventInstance(
        id: 'mobile-audit-event',
        templateId: 'mobile-audit-template',
        businessId: 'mobile-audit-shop',
        title: '냉방 설비 이상',
        body: '더운 날 손님이 불편해하기 전에 대응 수준을 정해야 한다.',
        occurredDateIso: '2000-01-10',
        choiceDueDateIso: '2000-01-12',
        resolutionDateIso: '2000-01-16',
        choices: [choice],
        tags: ['maintenance'],
        dailyDemandDeltaBps: -200,
        dailyExtraCost: 10000,
      );
      final state = base.copyWith(
        businesses: BusinessPortfolioState(
          businesses: [business],
          pendingEvents: const [event],
          eventHistory: const [],
          totalAcquisitionSpend: business.totalInvested,
          totalSales: statement.grossSales,
          totalProfit: statement.netProfit,
          totalClosures: 0,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.2)),
            child: child!,
          ),
          home: businessScreen(state),
        ),
      );
      await tester.pumpAndSettle();

      for (final key in const <String>[
        'business-tab-listings',
        'business-tab-owned',
        'business-tab-events',
        'business-tab-statements',
        'business-tab-districts',
      ]) {
        final tab = find.byKey(Key(key));
        await tester.ensureVisible(tab);
        await tester.pumpAndSettle();
        expect(tab.hitTestable(), findsOneWidget, reason: key);
      }

      final eventTab = find.byKey(const Key('business-tab-events'));
      await tester.ensureVisible(eventTab);
      await tester.tap(eventTab);
      await tester.pumpAndSettle();
      final choiceButton = find.byKey(
        const Key('business-event-choice-mobile-audit-event-repair-now'),
      );
      await tester.scrollUntilVisible(
        choiceButton,
        180,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('business-events-panel')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(choiceButton.hitTestable(), findsOneWidget);
      expect(tester.getSize(choiceButton).height, greaterThanOrEqualTo(44));
      await tester.tap(choiceButton);
      await tester.pumpAndSettle();
      final dialog = find.byType(AlertDialog);
      expect(dialog, findsOneWidget);
      final dialogRect = tester.getRect(dialog);
      expect(dialogRect.left, greaterThanOrEqualTo(0));
      expect(dialogRect.right, lessThanOrEqualTo(360));
      expect(dialogRect.top, greaterThanOrEqualTo(0));
      expect(dialogRect.bottom, lessThanOrEqualTo(800));
      expect(find.text('대응 선택').hitTestable(), findsOneWidget);
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      final statementTab = find.byKey(const Key('business-tab-statements'));
      await tester.ensureVisible(statementTab);
      await tester.tap(statementTab);
      await tester.pumpAndSettle();
      final statementCard = find.byKey(
        const Key('business-statement-mobile-audit-shop-2000-1'),
      );
      expect(statementCard, findsOneWidget);
      expect(tester.getRect(statementCard).right, lessThanOrEqualTo(360));
      await tester.tap(statementCard);
      await tester.pumpAndSettle();
      expect(find.text('영업일'), findsOneWidget);
      expect(find.text('31일'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
