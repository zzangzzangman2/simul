import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/historical_executives.dart';

void main() {
  test('Samsung keeps chairman and CEO as separate 2000 roles', () {
    final executives = executivesForCompany('005930', DateTime(2000, 1, 1));

    expect(executives, hasLength(2));
    expect(
      executives.map((executive) => executive.nameKo),
      containsAll(['이건희', '윤종용']),
    );
    expect(
      executives.map((executive) => executive.roleKo),
      containsAll(['회장', '대표이사 사장 · CEO']),
    );
  });

  test('Microsoft handover follows January 13 2000 without future leak', () {
    final before = executivesForCompany('MSFT', DateTime(2000, 1, 12));
    final after = executivesForCompany('MSFT', DateTime(2000, 1, 13));

    expect(before, hasLength(1));
    expect(before.single.nameEn, 'Bill Gates');
    expect(before.single.roleKo, '회장 · CEO');

    expect(after, hasLength(2));
    expect(
      after.map((executive) => executive.nameEn),
      containsAll(['Bill Gates', 'Steve Ballmer']),
    );
    expect(
      after
          .singleWhere((executive) => executive.nameEn == 'Steve Ballmer')
          .roleKo,
      '사장 · CEO',
    );
  });
}
