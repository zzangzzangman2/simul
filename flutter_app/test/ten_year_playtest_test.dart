import 'package:flutter_test/flutter_test.dart';

import '../tool/ten_year_playtest.dart' as playtest;

void main() {
  test(
    'full 2000-2026 fair trading playtest keeps accounts and saves valid',
    () async {
      await playtest.main();
    },
  );
}
