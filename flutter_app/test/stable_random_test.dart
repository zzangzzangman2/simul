import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/stable_hash.dart';

void main() {
  test('31-bit multiplication matches exact modular arithmetic', () {
    final mask = BigInt.from(0x7fffffff);
    for (var index = 0; index < 10000; index++) {
      final left = stableHash31('multiply:left:$index');
      final right = stableHash31('multiply:right:$index');
      final expected = (BigInt.from(left) * BigInt.from(right) & mask).toInt();
      expect(multiply31Exact(left, right), expected);
    }
  });

  test('stable random stream is deterministic and bounded', () {
    for (var bound = 1; bound <= 100; bound++) {
      for (var index = 0; index < 100; index++) {
        final key = 'deterministic:$bound:$index';
        final first = stableRandomInt(key, bound);
        final replay = stableRandomInt(key, bound);
        expect(replay, first);
        expect(first, inInclusiveRange(0, bound - 1));
      }
    }
    expect(() => stableRandomInt('invalid', 0), throwsRangeError);
  });

  test('six-way and 37-way streams stay statistically balanced', () {
    final sixCounts = List<int>.filled(6, 0);
    for (var index = 0; index < 60000; index++) {
      sixCounts[stableRandomInt('balance:six:$index', 6)]++;
    }
    for (final count in sixCounts) {
      expect(count, inInclusiveRange(9500, 10500));
    }

    final wheelCounts = List<int>.filled(37, 0);
    for (var index = 0; index < 74000; index++) {
      wheelCounts[stableRandomInt('balance:wheel:$index', 37)]++;
    }
    for (final count in wheelCounts) {
      expect(count, inInclusiveRange(1800, 2200));
    }
  });

  test(
    'parallel streams and nearby rounds do not expose a four-round cycle',
    () {
      var equalParallelStreams = 0;
      final triples = <String>[];
      for (var round = 0; round < 60000; round++) {
        final first = stableRandomInt('independence:$round:stream:0', 6);
        final second = stableRandomInt('independence:$round:stream:1', 6);
        if (first == second) equalParallelStreams++;
        if (round < 200) {
          triples.add(
            '${stableRandomInt('round:$round:reel:0', 6)}-'
            '${stableRandomInt('round:$round:reel:1', 6)}-'
            '${stableRandomInt('round:$round:reel:2', 6)}',
          );
        }
      }
      expect(equalParallelStreams, inInclusiveRange(9500, 10500));

      var lagFourMatches = 0;
      for (var index = 4; index < triples.length; index++) {
        if (triples[index] == triples[index - 4]) lagFourMatches++;
      }
      expect(lagFourMatches, lessThanOrEqualTo(3));
    },
  );
}
