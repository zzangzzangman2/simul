import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/real_estate_financing.dart';
import 'package:millennium_capital/game/real_estate_market.dart';
import 'package:millennium_capital/game/real_estate_rental.dart';
import 'package:millennium_capital/game/real_estate_world.dart';
import 'package:millennium_capital/main.dart';

String _money(int value) => value.toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (_) => ',',
);

Widget _testApp({required Widget home, double textScale = 1}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: home,
);

Future<({GeneratedRealEstateListing listing, String buttonKey})>
_openFirstListingDetail(WidgetTester tester, GameState state) async {
  final carousel = find.byKey(const Key('real-estate-listing-carousel'));
  await tester.scrollUntilVisible(
    carousel,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();

  final listings =
      realEstateMarketCatalogAt(state.currentDate)
          .where((asset) => asset.tier == RealEstateInvestmentTier.starter)
          .expand(
            (asset) => realEstateActiveListingsAt(
              asset,
              state.simulationSeed,
              state.currentDate,
            ),
          )
          .toList()
        ..sort(
          (left, right) => left
              .priceAt(state.currentDate)
              .compareTo(right.priceAt(state.currentDate)),
        );
  expect(listings, isNotEmpty);
  final listing = listings.first;
  final buttonKey = 'real-estate-buy-${listing.asset.id}-${listing.index}';
  final stableDetailButton = find.byKey(Key(buttonKey));
  expect(stableDetailButton, findsOneWidget);
  await tester.ensureVisible(stableDetailButton);
  await tester.pumpAndSettle();
  final horizontalScrollable = find.descendant(
    of: carousel,
    matching: find.byType(Scrollable),
  );
  final horizontalPosition = tester
      .state<ScrollableState>(horizontalScrollable)
      .position;
  horizontalPosition.jumpTo(
    horizontalPosition.maxScrollExtent.clamp(0, 220).toDouble(),
  );
  await tester.pumpAndSettle();
  expect(stableDetailButton.hitTestable(), findsOneWidget);
  await tester.tap(stableDetailButton);
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('real-estate-detail-screen')), findsOneWidget);
  return (listing: listing, buttonKey: buttonKey);
}

Future<void> _openDetailTab(
  WidgetTester tester,
  String tabName,
  String panelName,
) async {
  final tab = find.byKey(Key('real-estate-detail-tab-$tabName'));
  expect(tab, findsOneWidget);
  await tester.ensureVisible(tab);
  await tester.pumpAndSettle();
  expect(tab.hitTestable(), findsOneWidget);
  await tester.tap(tab);
  await tester.pumpAndSettle();
  expect(
    find.byKey(Key('real-estate-detail-$panelName-panel')),
    findsOneWidget,
  );
}

Future<void> _scrollDetailPanelUntilVisible(
  WidgetTester tester, {
  required String panelName,
  required Finder target,
}) async {
  final panel = find.byKey(Key('real-estate-detail-$panelName-panel'));
  final scrollable = find.descendant(
    of: panel,
    matching: find.byType(Scrollable),
  );
  await tester.scrollUntilVisible(target, 240, scrollable: scrollable);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('2000년 화면은 미래 부동산 단계와 매물을 미리 보여주지 않는다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const engine = GameEngine();
    final state = engine.createNewGame('부동산 비누설 테스트');

    await tester.pumpWidget(
      MaterialApp(
        home: AssetSpendingScreen(
          state: state,
          onPurchase: (optionId) async =>
              engine.purchaseSpendingOption(state, optionId),
          onSellRealEstate: (assetId) async =>
              engine.sellRealEstate(state, assetId),
          onPlayChanceGame: (stake) async =>
              engine.playAdultChanceGame(state, stake),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('real-estate-tier-starter')), findsOneWidget);
    expect(find.byKey(const Key('real-estate-tier-income')), findsOneWidget);
    expect(find.byKey(const Key('real-estate-tier-apartment')), findsOneWidget);
    expect(find.byKey(const Key('real-estate-tier-prestige')), findsNothing);
    expect(find.byKey(const Key('real-estate-tier-building')), findsNothing);
    expect(find.byKey(const Key('real-estate-tier-landmark')), findsNothing);
    expect(find.textContaining('판교푸르지오그랑블'), findsNothing);
    expect(find.textContaining('센트로폴리스'), findsNothing);
    final starterAssets = realEstateMarketCatalogAt(
      state.currentDate,
    ).where((asset) => asset.tier == RealEstateInvestmentTier.starter);
    final activeListingCount = starterAssets.fold<int>(
      0,
      (sum, asset) =>
          sum +
          realEstateActiveListingsAt(
            asset,
            state.simulationSeed,
            state.currentDate,
          ).length,
    );
    final carousel = tester.widget<ListView>(
      find.byKey(const Key('real-estate-listing-carousel')),
    );
    expect(
      (carousel.childrenDelegate.estimatedChildCount! + 1) ~/ 2,
      activeListingCount,
      reason: '현재 날짜에 활성 상태인 매물만 carousel item으로 만들어야 한다.',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('360px 글자 1.2배에서 상세 6탭과 노트를 확인한 뒤 현금 매입한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const engine = GameEngine();
    var state = engine
        .createNewGame('부동산 화면 테스트', initialCash: 100000000)
        .copyWith(brokerageCash: 0, decisions: const []);

    await tester.pumpWidget(
      _testApp(
        textScale: 1.2,
        home: AssetSpendingScreen(
          state: state,
          onPurchase: (optionId) async {
            final result = engine.purchaseSpendingOption(state, optionId);
            if (result.success) state = result.state;
            return result;
          },
          onSellRealEstate: (assetId) async =>
              engine.sellRealEstate(state, assetId),
          onPlayChanceGame: (stake) async =>
              engine.playAdultChanceGame(state, stake),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final opened = await _openFirstListingDetail(tester, state);
    final listing = opened.listing;
    final quote = listing.quoteAt(state.currentDate);

    for (final tab in const [
      'listing',
      'price',
      'returns',
      'loan',
      'tax',
      'news',
    ]) {
      expect(find.byKey(Key('real-estate-detail-tab-$tab')), findsOneWidget);
    }
    expect(
      find.byKey(const Key('real-estate-detail-listing-panel')),
      findsOneWidget,
    );
    const savedNote = '등기부와 수리 견적을 계약 전에 다시 확인';
    final noteField = find.byKey(const Key('real-estate-investment-note'));
    await _scrollDetailPanelUntilVisible(
      tester,
      panelName: 'listing',
      target: noteField,
    );
    await tester.enterText(noteField, savedNote);
    final noteSave = find.byKey(const Key('real-estate-investment-note-save'));
    await tester.ensureVisible(noteSave);
    await tester.tap(noteSave);
    await tester.pumpAndSettle();
    expect(find.text('저장됨'), findsOneWidget);

    tester.testTextInput.hide();
    await tester.pageBack();
    await tester.pumpAndSettle();
    final reopenButton = find.byKey(Key(opened.buttonKey));
    await tester.ensureVisible(reopenButton);
    await tester.tap(reopenButton);
    await tester.pumpAndSettle();
    final reopenedNote = find.byKey(const Key('real-estate-investment-note'));
    await _scrollDetailPanelUntilVisible(
      tester,
      panelName: 'listing',
      target: reopenedNote,
    );
    expect(tester.widget<TextField>(reopenedNote).controller!.text, savedNote);

    await _openDetailTab(tester, 'price', 'price');
    expect(find.byKey(const Key('real-estate-price-chart')), findsOneWidget);
    for (final futureAnchor in listing.asset.priceAnchors.where(
      (anchor) => anchor.date.isAfter(state.currentDate),
    )) {
      expect(
        find.textContaining(
          '${futureAnchor.date.year}.'
          '${futureAnchor.date.month.toString().padLeft(2, '0')}',
        ),
        findsNothing,
        reason: '현재 날짜 이후의 가격 근거 날짜는 상세 시세 탭에 노출하면 안 된다.',
      );
    }
    await _openDetailTab(tester, 'returns', 'returns');
    expect(find.text('월 NOI'), findsOneWidget);
    expect(find.text('Cap rate'), findsOneWidget);
    expect(find.text('Cash-on-cash'), findsOneWidget);
    expect(find.text('DSCR'), findsOneWidget);
    await _openDetailTab(tester, 'loan', 'loan');
    await _openDetailTab(tester, 'tax', 'tax');
    await _openDetailTab(tester, 'news', 'news');
    final visibleEvents = [...listing.visibleEventsAt(state.currentDate)]
      ..sort((left, right) => right.announcedAt.compareTo(left.announcedAt));
    if (visibleEvents.isEmpty) {
      expect(find.text('현재 시점에 공개된 지역뉴스가 없습니다.'), findsOneWidget);
    } else {
      expect(find.textContaining('최근 24건'), findsOneWidget);
      expect(find.text(visibleEvents.first.title), findsOneWidget);
      if (visibleEvents.length > 24) {
        expect(find.text(visibleEvents.last.title), findsNothing);
      }
    }
    await _openDetailTab(tester, 'listing', 'listing');

    final purchaseButton = find.byKey(const Key('real-estate-detail-purchase'));
    expect(purchaseButton.hitTestable(), findsOneWidget);
    final purchaseRect = tester.getRect(purchaseButton);
    expect(purchaseRect.left, greaterThanOrEqualTo(0));
    expect(purchaseRect.right, lessThanOrEqualTo(360));
    expect(purchaseRect.bottom, lessThanOrEqualTo(800));
    await tester.tap(purchaseButton);
    await tester.pumpAndSettle();

    expect(find.text('위험 확인 후 매입'), findsOneWidget);
    expect(find.textContaining('실제 필요 현금'), findsOneWidget);
    await tester.tap(find.text('위험 확인 후 매입'));
    await tester.pumpAndSettle();

    expect(state.cash, 100000000 - quote.totalCash);
    expect(
      state.personalFinance.realEstate.single.marketAssetId,
      listing.asset.id,
    );
    expect(
      state.personalFinance.realEstate.single.marketListingIndex,
      listing.index,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('390px 2010년 상세 대출 탭은 10% 단위 LTV와 통장 기준 필요현금을 반영한다', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const engine = GameEngine();
    final base = engine
        .createNewGame('부동산 대출 화면 테스트', initialCash: 1000000000)
        .copyWith(brokerageCash: 900000000, decisions: const []);
    final targetDay =
        DateTime(2010, 6, 15).difference(base.campaignStartDate).inDays + 1;
    var state = base.copyWith(day: targetDay);

    await tester.pumpWidget(
      MaterialApp(
        home: AssetSpendingScreen(
          state: state,
          onPurchase: (optionId) async {
            final result = engine.purchaseSpendingOption(state, optionId);
            if (result.success) state = result.state;
            return result;
          },
          onSellRealEstate: (assetId) async =>
              engine.sellRealEstate(state, assetId),
          onPlayChanceGame: (stake) async =>
              engine.playAdultChanceGame(state, stake),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final opened = await _openFirstListingDetail(tester, state);
    await _openDetailTab(tester, 'loan', 'loan');

    for (final ltv in const [0, 10, 20, 30, 40, 50, 60, 70]) {
      expect(find.byKey(Key('real-estate-detail-ltv-$ltv')), findsOneWidget);
    }
    expect(find.text('첫 12개월 상환 일정'), findsOneWidget);
    expect(find.textContaining('회사 통장 100,000,000원'), findsWidgets);

    final quote = realEstatePortfolioAdjustedPurchaseQuote(
      baseQuote: opened.listing.quoteAt(state.currentDate),
      date: state.currentDate,
      type: opened.listing.asset.type,
      ownedHousingCount: state.personalFinance.ownedHousingCount,
    );
    final terms = realEstateFinancingTermsAt(
      state.currentDate,
      opened.listing.asset.type,
    );
    final plan = terms.planFor(quote, 70);
    await tester.tap(find.byKey(const Key('real-estate-detail-ltv-70')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<ChoiceChip>(
            find.byKey(const Key('real-estate-detail-ltv-70')),
          )
          .selected,
      isTrue,
    );
    expect(find.text('필요 현금 ${_money(plan.cashRequired)}원'), findsOneWidget);
    expect(find.text('회사 통장 100,000,000원 · LTV 70%'), findsOneWidget);
    await _scrollDetailPanelUntilVisible(
      tester,
      panelName: 'loan',
      target: find.text('12회'),
    );
    expect(find.text('1회'), findsOneWidget);
    expect(find.text('12회'), findsOneWidget);
    final purchaseButton = find.byKey(const Key('real-estate-detail-purchase'));
    expect(tester.widget<FilledButton>(purchaseButton).onPressed, isNotNull);
    expect(purchaseButton.hitTestable(), findsOneWidget);
    await tester.tap(purchaseButton);
    await tester.pumpAndSettle();

    expect(find.text('위험 확인 후 매입'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.textContaining('월 원리금'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('390px 보유 상세관리에서 비활성 기능을 확인하고 임대 callback을 호출한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const engine = GameEngine();
    final base = engine
        .createNewGame('임대 운영 화면 테스트', initialCash: 1000000000)
        .copyWith(brokerageCash: 0, decisions: const []);
    final targetDay =
        DateTime(2010, 6, 15).difference(base.campaignStartDate).inDays + 1;
    final dated = base.copyWith(day: targetDay);
    final marketAsset = realEstateMarketAssetById(
      'uijeongbu_station_officetel_20',
    )!;
    final listing = realEstateActiveListingsAt(
      marketAsset,
      dated.simulationSeed,
      dated.currentDate,
    ).first;
    final purchase = engine.purchaseSpendingOption(dated, listing.optionId);
    expect(purchase.success, isTrue);
    final owned = purchase.state.personalFinance.realEstate.single;
    var state = purchase.state.copyWith(
      personalFinance: purchase.state.personalFinance.copyWith(
        realEstate: [
          owned.copyWith(
            vacancyMonths: realEstateTenantSearchMonths(
              worldSeed: purchase.state.simulationSeed,
              assetId: owned.id,
            ),
          ),
        ],
      ),
    );
    final ownedId = owned.id;
    var configureCalls = 0;
    var insuranceCalls = 0;
    String? insuredAssetId;
    bool? requestedInsuranceState;

    await tester.pumpWidget(
      MaterialApp(
        home: AssetSpendingScreen(
          state: state,
          onPurchase: (optionId) async =>
              engine.purchaseSpendingOption(state, optionId),
          onSellRealEstate: (assetId) async =>
              engine.sellRealEstate(state, assetId),
          onConfigureLease: (assetId, leaseType) async {
            configureCalls += 1;
            final result = engine.configureRealEstateLease(
              state,
              assetId,
              leaseType,
            );
            if (result.success) state = result.state;
            return result;
          },
          onSetRealEstateInsurance: (assetId, active) async {
            insuranceCalls += 1;
            insuredAssetId = assetId;
            requestedInsuranceState = active;
            final result = engine.setRealEstateInsurance(
              state,
              assetId,
              active,
            );
            if (result.success) state = result.state;
            return result;
          },
          onPlayChanceGame: (stake) async =>
              engine.playAdultChanceGame(state, stake),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final ownedDetailButton = find.byKey(
      Key('real-estate-owned-detail-$ownedId'),
    );
    for (
      var attempt = 0;
      attempt < 8 && ownedDetailButton.evaluate().isEmpty;
      attempt++
    ) {
      await tester.drag(
        find.byKey(const Key('asset-spending-screen')),
        const Offset(0, -600),
      );
      await tester.pumpAndSettle();
    }
    expect(ownedDetailButton, findsOneWidget);
    await tester.ensureVisible(ownedDetailButton);
    await tester.drag(find.byType(ListView).first, const Offset(0, -120));
    await tester.pumpAndSettle();
    await tester.tap(ownedDetailButton);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('real-estate-detail-screen')), findsOneWidget);
    expect(
      find.byKey(const Key('real-estate-detail-tab-management')),
      findsOneWidget,
    );
    await _openDetailTab(tester, 'management', 'management');

    final insuranceToggle = find.byKey(
      const Key('real-estate-detail-insurance-toggle'),
    );
    await _scrollDetailPanelUntilVisible(
      tester,
      panelName: 'management',
      target: insuranceToggle,
    );
    expect(insuranceToggle.hitTestable(), findsOneWidget);
    await tester.tap(insuranceToggle);
    await tester.pumpAndSettle();
    expect(find.text('보험 가입'), findsOneWidget);
    await tester.tap(find.text('보험 가입'));
    await tester.pumpAndSettle();

    expect(insuranceCalls, 1);
    expect(insuredAssetId, ownedId);
    expect(requestedInsuranceState, isTrue);
    expect(state.personalFinance.realEstate.single.insuranceActive, isTrue);

    final directUseDisabled = find.byKey(
      const Key('real-estate-detail-direct-use-disabled'),
    );
    final refinanceDisabled = find.byKey(
      const Key('real-estate-detail-refinance-disabled'),
    );
    await _scrollDetailPanelUntilVisible(
      tester,
      panelName: 'management',
      target: directUseDisabled,
    );
    expect(directUseDisabled, findsOneWidget);
    expect(refinanceDisabled, findsOneWidget);
    expect(tester.widget<OutlinedButton>(directUseDisabled).onPressed, isNull);
    expect(tester.widget<OutlinedButton>(refinanceDisabled).onPressed, isNull);
    expect(directUseDisabled.hitTestable(), findsNothing);
    expect(refinanceDisabled.hitTestable(), findsNothing);

    final manageButton = find.byKey(const Key('real-estate-detail-lease'));
    await _scrollDetailPanelUntilVisible(
      tester,
      panelName: 'management',
      target: manageButton,
    );
    expect(manageButton.hitTestable(), findsOneWidget);
    await tester.tap(manageButton);
    await tester.pumpAndSettle();

    expect(find.textContaining('보증금은 수익이 아니라'), findsOneWidget);
    expect(
      find.byKey(const Key('real-estate-lease-monthlyRent')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('real-estate-lease-monthlyRent')));
    await tester.pumpAndSettle();
    expect(find.text('계약 확정'), findsOneWidget);
    await tester.tap(find.text('계약 확정'));
    await tester.pumpAndSettle();

    expect(configureCalls, 1);
    expect(
      state.personalFinance.realEstate.single.leaseType,
      RealEstateLeaseType.monthlyRent,
    );
    expect(tester.takeException(), isNull);
  });
}
