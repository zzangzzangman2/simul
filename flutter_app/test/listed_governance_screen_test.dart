import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/shareholder_governance_engine.dart';
import 'package:millennium_capital/main.dart';

import 'support/market_fixture.dart';

void main() {
  testWidgets('360px 화면에서 주주권, 주총, 공개매수 흐름을 스크롤할 수 있다', (tester) async {
    tester.view.physicalSize = const Size(360, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final base = const GameEngine().createNewGame(
      '주주 UI 테스트',
      worldSeed: 'listed-governance-widget',
    );
    final state = base.copyWith(
      cash: 20000000000,
      brokerageCash: 0,
      positions: const <PortfolioPosition>[
        PortfolioPosition(
          assetId: 'hanbit_telecom',
          symbol: '1001',
          name: '한빛통신',
          market: 'KSE',
          currency: 'KRW',
          units: 200000,
          totalCost: 1000000000,
        ),
      ],
    );
    final universe = testMarketUniverse();
    final asset = universe.assets.first;

    await tester.pumpWidget(
      MaterialApp(
        home: ListedGovernanceScreen(
          state: state,
          asset: asset,
          marketCap: 6110000000,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('listed-governance-screen')), findsOneWidget);
    expect(find.text('지분별 주주권'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.byKey(const Key('launch-tender-offer-51')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('launch-tender-offer-51')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('경영권 확보 회사는 업종별 이사회 안건을 의결하고 시장반응을 본다', (tester) async {
    tester.view.physicalSize = const Size(360, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final base = const GameEngine().createNewGame(
      '경영 UI 테스트',
      worldSeed: 'listed-management-widget',
    );
    final state = base.copyWith(
      cash: 20000000000,
      brokerageCash: 0,
      positions: const <PortfolioPosition>[
        PortfolioPosition(
          assetId: 'hanbit_telecom',
          symbol: '1001',
          name: '한빛통신',
          market: 'KSE',
          currency: 'KRW',
          units: 600000,
          totalCost: 3000000000,
        ),
      ],
    );
    final asset = testMarketUniverse().assets.first;

    await tester.pumpWidget(
      MaterialApp(
        home: ListedGovernanceScreen(
          state: state,
          asset: asset,
          marketCap: 6110000000,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -1200));
    await tester.pumpAndSettle();
    final focusedOption = find.byKey(const Key('management-option-focused'));
    expect(focusedOption, findsOneWidget);
    await tester.ensureVisible(focusedOption);
    await tester.pumpAndSettle();
    expect(find.textContaining('반도체 이사회'), findsOneWidget);
    expect(find.textContaining('누적 시장평가'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(focusedOption);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('confirm-management-decision')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('confirm-management-decision')));
    await tester.pumpAndSettle();

    expect(find.textContaining('이번 분기 핵심안건은 결정'), findsOneWidget);
    expect(find.text('경영 공시·실행 기록'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('특별결의 지배주주는 CEO로 취임하고 다른 지배회사와 합병을 추진한다', (tester) async {
    tester.view.physicalSize = const Size(360, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final base = const GameEngine().createNewGame(
      'CEO 합병 UI 테스트',
      worldSeed: 'listed-ceo-merger-widget',
    );
    final universe = testMarketUniverse(includeKnownPartner: true);
    var state = base.copyWith(
      cash: 20000000000,
      brokerageCash: 0,
      positions: const <PortfolioPosition>[
        PortfolioPosition(
          assetId: 'hanbit_telecom',
          symbol: '1001',
          name: '한빛통신',
          market: 'KSE',
          currency: 'KRW',
          units: 700000,
          totalCost: 3000000000,
        ),
        PortfolioPosition(
          assetId: 'widget_partner',
          symbol: '1002',
          name: '테스트 부품',
          market: 'KSE',
          currency: 'KRW',
          units: 350000,
          totalCost: 100000000,
        ),
      ],
    );
    state = const ShareholderGovernanceEngine().processDay(state, universe);

    await tester.pumpWidget(
      MaterialApp(
        home: ListedGovernanceScreen(
          state: state,
          asset: universe.assets.first,
          marketCap: 6110000000,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final appoint = find.byKey(const Key('appoint-player-ceo'));
    await tester.scrollUntilVisible(
      appoint,
      350,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(appoint);
    await tester.pumpAndSettle();
    await tester.tap(appoint);
    await tester.pumpAndSettle();
    expect(find.textContaining('플레이어 대표이사 CEO'), findsOneWidget);

    final mergerButton = find.byKey(const Key('start-listed-merger'));
    await tester.scrollUntilVisible(
      mergerButton,
      350,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(mergerButton);
    await tester.pumpAndSettle();
    await tester.tap(mergerButton);
    await tester.pumpAndSettle();

    final candidate = find.byKey(
      const Key('corporate-merger-widget_partner-absorption'),
    );
    expect(candidate, findsOneWidget);
    await tester.tap(candidate);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-corporate-action')));
    await tester.pumpAndSettle();

    expect(find.textContaining('흡수합병'), findsWidgets);
    expect(find.textContaining('통합 진행 중'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
