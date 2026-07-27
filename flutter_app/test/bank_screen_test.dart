import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/main.dart';

import 'support/market_fixture.dart';

void main() {
  const engine = GameEngine();

  testWidgets(
    '390x844 bank consultation opens a deposit and changes clerk pose',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var latest = engine
          .createNewGame('은행 UI 테스트', initialCash: 1000000)
          .copyWith(brokerageCash: 0);

      Future<FinanceActionResult> unavailable() async => FinanceActionResult(
        state: latest,
        success: false,
        message: '테스트에서는 사용할 수 없습니다.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BankScreen(
            state: latest,
            onOpenDeposit: (amount, termMonths) async {
              final result = engine.openTimeDeposit(
                latest,
                amount: amount,
                termMonths: termMonths,
              );
              if (result.success) latest = result.state;
              return result;
            },
            onRedeemDeposit: (_) => unavailable(),
            onTakeLoan: (_, _) => unavailable(),
            onRepayLoan: (_, _) => unavailable(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('bank-screen')), findsOneWidget);
      expect(find.byKey(const Key('bank-clerk-welcome')), findsOneWidget);
      expect(find.byKey(const Key('bank-intro-dialogue')), findsOneWidget);

      await tester.tap(find.byKey(const Key('bank-intro-continue')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('bank-clerk-explain')), findsOneWidget);
      await tester.tap(find.byKey(const Key('bank-intro-deposit')));
      await tester.pumpAndSettle();
      final panel = find.byKey(const Key('bank-consultation-panel'));
      expect(panel, findsOneWidget);
      final panelRect = tester.getRect(panel);
      expect(panelRect.left, greaterThanOrEqualTo(0));
      expect(panelRect.right, lessThanOrEqualTo(390));
      expect(panelRect.bottom, lessThanOrEqualTo(844));
      expect(find.byKey(const Key('bank-clerk-explain')), findsOneWidget);

      await tester.tap(find.byKey(const Key('bank-open-deposit')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('bank-amount-input')), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('bank-amount-input')),
        '100000',
      );
      await tester.tap(find.byKey(const Key('bank-amount-confirm')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('bank-clerk-approve')), findsOneWidget);
      expect(find.textContaining('원금 100,000원'), findsOneWidget);

      await tester.tap(find.text('대출'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('bank-clerk-concerned')), findsOneWidget);
      expect(find.textContaining('만 20세부터'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('정기예금 가입 뒤에도 장부 순자산이 사라지지 않는다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final before = engine
        .createNewGame('은행 장부 테스트', initialCash: 1000000)
        .copyWith(brokerageCash: 0);
    final opened = engine.openTimeDeposit(
      before,
      amount: 500000,
      termMonths: 12,
    );
    expect(opened.success, isTrue);

    await tester.pumpWidget(
      MaterialApp(
        home: PortfolioLedgerScreen(
          key: const ValueKey('ledger-before-deposit'),
          state: before,
          universe: testMarketUniverse(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final beforeLabel = tester
        .widget<Text>(find.byKey(const Key('ledger-total-aum')))
        .data;

    await tester.pumpWidget(
      MaterialApp(
        home: PortfolioLedgerScreen(
          key: const ValueKey('ledger-after-deposit'),
          state: opened.state,
          universe: testMarketUniverse(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final afterLabel = tester
        .widget<Text>(find.byKey(const Key('ledger-total-aum')))
        .data;

    expect(afterLabel, beforeLabel);
    expect(find.text('순자산 · 원화 장부'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('360x800 큰 글자에서도 DSR과 대출 상환 미리보기를 표시한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final base = engine.createNewGame(
      '은행 대출 UI 테스트',
      initialCash: 1000000,
      worldSeed: 'bank-loan-ui-test',
    );
    final adultDay =
        DateTime(2010, 2, 15).difference(base.campaignStartDate).inDays + 1;
    var latest = base.copyWith(
      day: adultDay,
      brokerageCash: 0,
      decisions: const [],
      company: base.company.copyWith(
        votingOwnershipPct: 55,
        monthlyRevenue: 20000000,
      ),
    );

    Future<FinanceActionResult> unavailable() async => FinanceActionResult(
      state: latest,
      success: false,
      message: '테스트에서는 사용할 수 없습니다.',
    );

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            size: const Size(360, 800),
            textScaler: const TextScaler.linear(1.2),
          ),
          child: child!,
        ),
        home: BankScreen(
          state: latest,
          onOpenDeposit: (_, _) => unavailable(),
          onRedeemDeposit: (_) => unavailable(),
          onTakeLoan: (amount, termMonths) async {
            final result = engine.takeUnsecuredLoan(
              latest,
              amount: amount,
              termMonths: termMonths,
            );
            if (result.success) latest = result.state;
            return result;
          },
          onRepayLoan: (_, _) => unavailable(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('bank-intro-continue')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const Key('bank-intro-loan')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('현재 DSR'), findsOneWidget);
    expect(find.textContaining('기준금리'), findsOneWidget);

    await tester.tap(find.byKey(const Key('bank-take-loan')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bank-amount-preview')), findsOneWidget);
    expect(find.textContaining('월 원리금 약'), findsOneWidget);
    expect(find.textContaining('총 예상이자 약'), findsOneWidget);
    expect(find.textContaining('첫 납부'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
