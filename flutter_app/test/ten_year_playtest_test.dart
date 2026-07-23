import 'package:flutter_test/flutter_test.dart';

import '../tool/ten_year_playtest.dart' as playtest;

void main() {
  test(
    'ten-year fair trading playtest keeps accounts and saves valid',
    () async {
      await playtest.main();
    },
  );
}
