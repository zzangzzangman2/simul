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
    expect(find.text('뉴스를 생성 중입니다'), findsOneWidget);
    expect(find.textContaining('2007년의 시대 흐름'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
