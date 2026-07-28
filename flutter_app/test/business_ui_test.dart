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
      '${size.width.toInt()}px home PC exposes a 2x2 business app and opens management',
      (tester) async {
        await usePhoneSurface(tester, size);
        final state = newState();

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => HomeComputerScreen(
                state: state,
                onOpenStockMarket: (current) async => current,
                onOpenRealEstate: (current) async => current,
                onOpenBusiness: (current) async {
                  await Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => businessScreen(current),
                    ),
                  );
                  return current;
                },
                onOpenStarShop: (current) async => current,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final stockApp = find.byKey(const Key('computer-stock-market-app'));
        final realEstateApp = find.byKey(const Key('computer-real-estate-app'));
        final businessApp = find.byKey(const Key('computer-business-app'));
        final starShopApp = find.byKey(const Key('computer-star-shop-app'));
        final apps = <Finder>[
          stockApp,
          realEstateApp,
          businessApp,
          starShopApp,
        ];

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
        expect(tester.getSize(businessApp), tester.getSize(stockApp));
        expect(tester.getSize(starShopApp), tester.getSize(stockApp));

        final stockCenter = tester.getCenter(stockApp);
        final realEstateCenter = tester.getCenter(realEstateApp);
        final businessCenter = tester.getCenter(businessApp);
        final starShopCenter = tester.getCenter(starShopApp);
        expect(stockCenter.dy, closeTo(realEstateCenter.dy, 0.5));
        expect(businessCenter.dy, closeTo(starShopCenter.dy, 0.5));
        expect(businessCenter.dy, greaterThan(stockCenter.dy));
        expect(stockCenter.dx, lessThan(realEstateCenter.dx));
        expect(businessCenter.dx, lessThan(starShopCenter.dx));
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
    GameState? realEstateInput;
    GameState? businessInput;
    GameState? starShopInput;

    await tester.pumpWidget(
      MaterialApp(
        home: HomeComputerScreen(
          state: initial,
          onOpenStockMarket: (current) async =>
              current.copyWith(cash: current.cash + 101),
          onOpenRealEstate: (current) async {
            realEstateInput = current;
            return current.copyWith(cash: current.cash + 202);
          },
          onOpenBusiness: (current) async {
            businessInput = current;
            return current.copyWith(cash: current.cash + 303);
          },
          onOpenStarShop: (current) async {
            starShopInput = current;
            return current;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('computer-stock-market-app')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('computer-real-estate-app')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('computer-business-app')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('computer-star-shop-app')));
    await tester.pumpAndSettle();

    expect(realEstateInput?.cash, initial.cash + 101);
    expect(businessInput?.cash, initial.cash + 303);
    expect(starShopInput?.cash, initial.cash + 606);
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
}
