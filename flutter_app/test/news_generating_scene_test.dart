import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/main.dart';

void main() {
  testWidgets('360px에서도 다음 날 뉴스 생성 장면이 온전히 보인다', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: NewsGeneratingScene(date: DateTime(2007, 6, 29))),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const Key('news-generating-scene')), findsOneWidget);
    expect(find.text('조간신문과 오늘의 시장을 준비 중입니다…'), findsOneWidget);
    expect(find.textContaining('신문에는 전날 시장에서 확인된 사실만 담습니다'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
