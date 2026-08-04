import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/character_liveliness.dart';

const _bands = CharacterRegionBands();
const _limits = CharacterLivelinessLimits();
const _timing = CharacterLivelinessTiming();

CharacterVertexOffset _at(double x, double y, double seconds) =>
    characterVertexOffset(
      normalizedX: x,
      normalizedY: y,
      seconds: seconds,
      seed: 'han_sua',
    );

double _maxMagnitude(double x, double y, {int samples = 900}) {
  var worst = 0.0;
  for (var index = 0; index < samples; index += 1) {
    final offset = _at(x, y, index * 0.11);
    worst = math.max(worst, math.max(offset.dx.abs(), offset.dy.abs()));
  }
  return worst;
}

void main() {
  test('the face barely moves so the approved identity holds', () {
    // 얼굴이 일렁이면 v3 전환으로 확정한 정체성이 무너진다.
    for (final x in <double>[0.35, 0.5, 0.65]) {
      for (final y in <double>[0.06, 0.12, 0.17]) {
        expect(
          _maxMagnitude(x, y),
          lessThanOrEqualTo(_limits.maxFace),
          reason: '얼굴 ($x, $y) 변위가 상한을 넘었다',
        );
      }
    }
  });

  test('the feet stay planted', () {
    // 접지가 흔들리면 인물이 떠 보인다.
    expect(_maxMagnitude(0.5, 1).abs(), lessThan(0.001));
    expect(_maxMagnitude(0.2, 0.995).abs(), lessThan(0.05));
    // 발목으로 갈수록 잦아든다.
    expect(_maxMagnitude(0.5, 0.99), lessThan(_maxMagnitude(0.5, 0.94)));
  });

  test('no vertex ever exceeds the global cap', () {
    for (var xi = 0; xi <= 8; xi += 1) {
      for (var yi = 0; yi <= 20; yi += 1) {
        final magnitude = _maxMagnitude(xi / 8, yi / 20, samples: 220);
        expect(
          magnitude,
          lessThanOrEqualTo(_limits.maxAny),
          reason: '(${xi / 8}, ${yi / 20}) 변위가 전역 상한을 넘었다',
        );
      }
    }
  });

  test('the skirt hem moves most and the thigh below it barely does', () {
    final hem = _maxMagnitude(0.12, (_bands.skirtStart + _bands.skirtEnd) / 2);
    final thigh = _maxMagnitude(0.12, _bands.skirtEnd + 0.12);
    final face = _maxMagnitude(0.5, 0.12);

    // 나팔거림은 치맛단에서 가장 크다.
    expect(hem, greaterThan(thigh));
    expect(hem, greaterThan(face));
    expect(hem, greaterThan(1));
    expect(hem, lessThanOrEqualTo(_limits.maxSkirt));
  });

  test('the hem flares outward instead of sliding as one block', () {
    // 가장자리가 중앙보다 더 움직여야 통째로 미끄러지지 않고 벌어진다.
    final y = (_bands.skirtStart + _bands.skirtEnd) / 2;
    expect(_maxMagnitude(0.04, y), greaterThan(_maxMagnitude(0.5, y)));
    expect(_maxMagnitude(0.96, y), greaterThan(_maxMagnitude(0.5, y)));
    // 좌우 가장자리는 서로 반대편으로 벌어진다.
    var sawOpposite = false;
    for (var index = 0; index < 400; index += 1) {
      final seconds = index * 0.17;
      final left = _at(0.04, y, seconds).dx;
      final right = _at(0.96, y, seconds).dx;
      if (left < -0.2 && right > 0.2) sawOpposite = true;
    }
    expect(sawOpposite, isTrue, reason: '치맛단이 바깥으로 벌어지는 순간이 없다');
  });

  test('the hem lags the body so the cloth reads as inertia', () {
    // 지연이 없으면 천이 몸과 붙어 움직여 뻣뻣해 보인다.
    expect(_timing.hemLagSeconds, greaterThan(0));
    final hemY = (_bands.skirtStart + _bands.skirtEnd) / 2;
    var sawDivergence = false;
    for (var index = 0; index < 400; index += 1) {
      final seconds = index * 0.13;
      final torso = _at(0.12, 0.4, seconds).dx;
      final hem = _at(0.12, hemY, seconds).dx;
      if (torso.sign != hem.sign && hem.abs() > 0.4) sawDivergence = true;
    }
    expect(sawDivergence, isTrue, reason: '치맛단이 몸통과 같은 방향으로만 움직인다');
  });

  test('breathing is asymmetric, not a plain sine', () {
    // 들숨이 빠르고 날숨이 느려야 기계적으로 읽히지 않는다.
    final period = 1 / _timing.breathHz;
    var risingSamples = 0;
    var fallingSamples = 0;
    var previous = asymmetricBreath(0, _timing);
    for (var index = 1; index <= 400; index += 1) {
      final seconds = index / 400 * period;
      final value = asymmetricBreath(seconds, _timing);
      if (value > previous) {
        risingSamples += 1;
      } else if (value < previous) {
        fallingSamples += 1;
      }
      previous = value;
    }
    expect(risingSamples, greaterThan(0));
    expect(fallingSamples, greaterThan(0));
    expect(
      risingSamples,
      lessThan(fallingSamples),
      reason: '들숨 구간이 날숨보다 짧아야 한다',
    );
    // 값 범위는 -1..1 안이다.
    for (var index = 0; index <= 200; index += 1) {
      final value = asymmetricBreath(index * 0.37, _timing);
      expect(value, inInclusiveRange(-1.0001, 1.0001));
    }
  });

  test('composite motion does not repeat on the breath period', () {
    // 세 주기가 무리수 관계라 한 호흡 뒤에 같은 자리로 돌아오지 않는다.
    final period = 1 / _timing.breathHz;
    final first = _at(0.1, 0.63, 12);
    final later = _at(0.1, 0.63, 12 + period);
    expect((first.dx - later.dx).abs(), greaterThan(0.01));
  });

  test('each character keeps her own phase', () {
    // 여러 명이 같이 보일 때 동기화되면 인형처럼 보인다.
    final phases = <double>{
      for (final id in <String>[
        'kim_seoa',
        'lee_jian',
        'choi_iseo',
        'jung_arin',
        'park_haeun',
        'han_sua',
        'oh_jiwoo',
        'yoon_chaea',
      ])
        characterPhaseOffset(id),
    };
    expect(phases, hasLength(8));
    for (final phase in phases) {
      expect(phase, inInclusiveRange(0, 2 * math.pi));
    }
  });

  test('region weights fall from the hem to the feet without a jump', () {
    var previous = regionWeightAt(_bands.skirtEnd);
    for (var y = _bands.skirtEnd; y <= 1.0; y += 0.01) {
      final weight = regionWeightAt(y);
      expect(
        weight,
        lessThanOrEqualTo(previous + 0.001),
        reason: 'y=$y에서 되올랐다',
      );
      previous = weight;
    }
    expect(regionWeightAt(1), lessThan(0.001));
  });

  test('intensity zero freezes the portrait for reduced motion', () {
    // 모션 감소 설정에서 완전히 멈출 수 있어야 한다.
    for (var index = 0; index < 40; index += 1) {
      final offset = characterVertexOffset(
        normalizedX: 0.12,
        normalizedY: 0.63,
        seconds: index * 0.31,
        seed: 'han_sua',
        intensity: 0,
      );
      expect(offset.dx.abs(), lessThan(0.001));
      expect(offset.dy.abs(), lessThan(0.001));
    }
  });
}
