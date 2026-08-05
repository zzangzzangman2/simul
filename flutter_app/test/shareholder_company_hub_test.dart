import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/main.dart';

import 'support/market_fixture.dart';

void main() {
  testWidgets('PC 회사관리 허브가 보유회사와 정해진 정기주총 일정을 모아 보여준다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const engine = GameEngine();
    final base = engine.createNewGame(
      '회사관리 허브 테스트',
      initialCash: 100000000000,
      worldSeed: 'shareholder-company-hub-test',
    );
    final state = base.copyWith(
      positions: const <PortfolioPosition>[
        PortfolioPosition(
          assetId: 'hanbit_telecom',
          symbol: '1001',
          name: '한빛통신',
          market: 'KSE',
          currency: 'KRW',
          units: 510000,
          totalCost: 3116100000,
        ),
      ],
    );
    GameState? saved;

    await tester.pumpWidget(
      MaterialApp(
        home: ShareholderCompanyHubScreen(
          state: state,
          universe: testMarketUniverse(),
          onSaveState: (next) async {
            saved = next;
            return next;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('shareholder-company-hub-screen')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('shareholder-hub-summary')), findsOneWidget);
    expect(find.text('한빛통신 · 정기주총'), findsOneWidget);
    expect(find.textContaining('전자참석'), findsWidgets);
    expect(find.textContaining('한빛통신 · 경영권 확보'), findsOneWidget);
    expect(saved, isNotNull);

    final meeting = saved!.shareholderGovernance
        .meetingsFor('hanbit_telecom')
        .singleWhere((row) => !row.extraordinary);
    final heldDate = saved!.dateForDay(meeting.heldDay);
    expect(heldDate.month, 3);
    expect(heldDate.day, inInclusiveRange(20, 30));
    expect(heldDate.weekday, isNot(anyOf(DateTime.saturday, DateTime.sunday)));

    await tester.tap(find.byKey(Key('open-shareholder-meeting-${meeting.id}')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('listed-governance-screen')), findsOneWidget);
    expect(find.text('한빛통신 주주·경영관리'), findsOneWidget);
    expect(find.byKey(const Key('open-shareholder-governance')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('보유주식이 없으면 회사관리 허브가 안전한 빈 상태를 보여준다', (tester) async {
    const engine = GameEngine();
    final state = engine.createNewGame(
      '빈 회사관리 허브 테스트',
      worldSeed: 'empty-shareholder-company-hub-test',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ShareholderCompanyHubScreen(
          state: state,
          universe: testMarketUniverse(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('shareholder-hub-empty-companies')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('shareholder-hub-empty-meetings')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
