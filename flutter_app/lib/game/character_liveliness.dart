import 'dart:math' as math;

/// 가만히 서 있는 승인 초상에 생동감을 주는 변형 규칙이다.
///
/// 리깅 없이 평면 PNG 한 장에 격자를 씌우고 정점만 변위시킨다. 그래서 승인된 72장의
/// 픽셀을 다시 그리지 않고도 부위별로 다르게 움직인다.
///
/// 규칙 셋을 지킨다.
/// * **얼굴은 거의 고정한다.** 얼굴이 일렁이면 v3 전환으로 확정한 정체성이 무너진다.
/// * **발은 완전히 고정한다.** 접지가 흔들리면 인물이 떠 보인다.
/// * **진폭 상한을 넘기지 않는다.** 크게 주면 천이 아니라 물결처럼 보여 싸구려가 된다.
///
/// 좌표는 승인 규격(`1024×1536`, 머리 `y=20`, 발 마지막 픽셀 `y=1516`)을 정규화한
/// 0~1 값을 쓴다. 0이 머리 위, 1이 발끝이다.
/// 부위별 변위 가중. 값이 클수록 많이 움직인다.
class CharacterRegionWeights {
  const CharacterRegionWeights({
    this.face = 0.05,
    this.hair = 0.5,
    this.torso = 0.25,
    this.skirt = 1,
    this.leg = 0.15,
    this.foot = 0,
  });

  /// 얼굴·눈. 정체성 보호를 위해 0에 가깝게 둔다.
  final double face;

  /// 머리끝. 실루엣 가장자리에서 체중 이동에 늦게 따라온다.
  final double hair;

  /// 어깨·몸통. 호흡으로만 미세하게 커진다.
  final double torso;

  /// 치맛단. 가장 크게 움직이며 바깥으로 벌어진다.
  final double skirt;

  /// 다리. 거의 움직이지 않는다.
  final double leg;

  /// 발. 접지를 고정하므로 항상 0이다.
  final double foot;
}

/// 정규 Y 구간 경계.
class CharacterRegionBands {
  const CharacterRegionBands({
    this.faceEnd = 0.18,
    this.hairStart = 0.05,
    this.hairEnd = 0.35,
    this.torsoEnd = 0.55,
    this.skirtStart = 0.55,
    this.skirtEnd = 0.72,
    this.legEnd = 0.93,
  });

  final double faceEnd;
  final double hairStart;
  final double hairEnd;
  final double torsoEnd;
  final double skirtStart;
  final double skirtEnd;
  final double legEnd;
}

/// 변위 상한. 논리 픽셀 단위이며 이 값을 넘기면 천이 아니라 물결로 보인다.
class CharacterLivelinessLimits {
  const CharacterLivelinessLimits({
    this.maxFace = 0.6,
    this.maxTorso = 2,
    this.maxHair = 3.4,
    this.maxSkirt = 4,
    this.maxAny = 4,
  });

  final double maxFace;
  final double maxTorso;
  final double maxHair;
  final double maxSkirt;

  /// 어떤 정점도 이 값을 넘지 않는다.
  final double maxAny;
}

/// 서로 무리수 관계인 주기들. 합성 파형이 반복되지 않아 루프가 감지되지 않는다.
class CharacterLivelinessTiming {
  const CharacterLivelinessTiming({
    this.breathHz = 0.23,
    this.swayHz = 0.077,
    this.driftHz = 0.031,
    this.hemLagSeconds = 0.42,
    this.flareHz = 0.13,
    this.inhaleRatio = 0.4,
  });

  /// 호흡. 14살 안정 호흡을 분당 약 14회로 본다.
  final double breathHz;

  /// 체중 이동.
  final double swayHz;

  /// 미세 드리프트.
  final double driftHz;

  /// 치맛단이 몸을 따라오는 지연. 천의 관성이다.
  final double hemLagSeconds;

  /// 치맛단이 벌어지고 닫히는 주기. 좌우 스치기와 따로 돌아야 나팔거린다.
  final double flareHz;

  /// 들숨이 한 주기에서 차지하는 비율. 사람은 들숨이 빠르고 날숨이 느리다.
  final double inhaleRatio;
}

/// 한 정점의 변위.
class CharacterVertexOffset {
  const CharacterVertexOffset(this.dx, this.dy);

  final double dx;
  final double dy;
}

/// 들숨은 빠르고 날숨은 느린 비대칭 호흡 곡선. -1에서 1 사이를 돈다.
///
/// `math.sin`은 대칭이라 기계적으로 읽힌다. 들숨 구간을 압축해 사람의 호흡에 맞춘다.
double asymmetricBreath(double seconds, CharacterLivelinessTiming timing) {
  final period = 1 / timing.breathHz;
  final phase = (seconds % period) / period;
  final inhale = timing.inhaleRatio.clamp(0.05, 0.95);
  final shaped = phase < inhale
      ? phase / inhale * 0.5
      : 0.5 + (phase - inhale) / (1 - inhale) * 0.5;
  return -math.cos(shaped * 2 * math.pi);
}

/// 인물마다 위상을 다르게 해 여러 명이 같이 보일 때 동기화되지 않게 한다.
double characterPhaseOffset(String seed) {
  var hash = 0;
  for (final unit in seed.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return hash % 1000 / 1000 * 2 * math.pi;
}

/// 정규 Y에 해당하는 부위 가중을 구간 사이에서 부드럽게 섞는다.
double regionWeightAt(
  double normalizedY, {
  CharacterRegionWeights weights = const CharacterRegionWeights(),
  CharacterRegionBands bands = const CharacterRegionBands(),
}) {
  final y = normalizedY.clamp(0.0, 1.0);
  double blend(double from, double to, double a, double b) {
    if (b <= a) return to;
    final t = ((y - a) / (b - a)).clamp(0.0, 1.0);
    return from + (to - from) * t;
  }

  if (y <= bands.faceEnd) {
    // 얼굴 안에서도 위로 갈수록(머리) 조금 더 움직인다.
    return blend(weights.hair * 0.35, weights.face, 0, bands.faceEnd);
  }
  if (y <= bands.torsoEnd) {
    return blend(weights.face, weights.torso, bands.faceEnd, bands.torsoEnd);
  }
  if (y <= bands.skirtEnd) {
    return blend(
      weights.torso,
      weights.skirt,
      bands.skirtStart,
      bands.skirtEnd,
    );
  }
  if (y <= bands.legEnd) {
    return blend(weights.skirt, weights.leg, bands.skirtEnd, bands.legEnd);
  }
  return blend(weights.leg, weights.foot, bands.legEnd, 1);
}

/// 실루엣 가장자리로 갈수록 커지는 가로 감쇠.
///
/// 이게 없으면 치마가 통째로 미끄러진다. 가장자리를 더 밀어야 바깥으로 벌어진다.
double edgeFalloff(double normalizedX) {
  final distance = ((normalizedX.clamp(0.0, 1.0)) - 0.5).abs() * 2;
  return distance * distance;
}

/// 격자 한 정점의 변위를 구한다.
///
/// [seconds]는 시작부터의 경과 시간이고 [seed]는 인물 구분자다. 같은 입력이면 항상
/// 같은 결과가 나오므로 프레임이 밀려도 튀지 않는다.
CharacterVertexOffset characterVertexOffset({
  required double normalizedX,
  required double normalizedY,
  required double seconds,
  required String seed,
  CharacterLivelinessTiming timing = const CharacterLivelinessTiming(),
  CharacterRegionWeights weights = const CharacterRegionWeights(),
  CharacterRegionBands bands = const CharacterRegionBands(),
  CharacterLivelinessLimits limits = const CharacterLivelinessLimits(),
  double intensity = 1,
}) {
  final phase = characterPhaseOffset(seed);
  final breath = asymmetricBreath(seconds + phase, timing);
  final sway = math.sin(seconds * timing.swayHz * 2 * math.pi + phase);
  final drift = math.sin(seconds * timing.driftHz * 2 * math.pi + phase * 1.7);
  // 치맛단은 체중 이동을 늦게 따라온다. 이 지연이 천의 관성이다.
  final hemSway = math.sin(
    (seconds - timing.hemLagSeconds) * timing.swayHz * 2 * math.pi + phase,
  );

  final weight = regionWeightAt(normalizedY, weights: weights, bands: bands);
  final falloff = edgeFalloff(normalizedX);
  final inSkirt =
      normalizedY >= bands.skirtStart && normalizedY <= bands.skirtEnd;
  final side = normalizedX >= 0.5 ? 1.0 : -1.0;

  // 호흡은 세로로, 체중 이동은 가로로 작용한다.
  var dx = (sway * 1.1 + drift * 0.5) * weight * intensity;
  var dy = -breath.abs() * 1.4 * weight * intensity;

  if (inSkirt) {
    // 나팔거림은 두 성분이 겹친 것이다.
    //
    // 하나는 좌우 공통 스치기다. 몸이 체중을 옮기면 치맛단이 같은 방향으로 늦게 쓸린다.
    // 다른 하나는 벌어짐이다. 좌우 가장자리가 서로 **반대쪽**으로 열리고 닫힌다.
    //
    // 벌어짐이 스치기보다 커야 나팔로 읽힌다. 반대면 치마가 통째로 미끄러진다.
    // 그래서 벌어짐에는 좌우 스치기와 무리수 관계인 독립 주기를 준다.
    final flarePhase = math.sin(
      (seconds - timing.hemLagSeconds) * timing.flareHz * 2 * math.pi +
          phase * 2.3,
    );
    final brush = hemSway * (0.35 + falloff * 0.45);
    final flare = side * falloff * flarePhase * 2.6;
    dx += (brush + flare) * weights.skirt * intensity;
    // 벌어질 때 살짝 들린다. 닫힐 때보다 열릴 때가 빠르다.
    dy -= flarePhase.abs() * 0.8 * weights.skirt * intensity;
  } else {
    // 머리끝도 가장자리에서 더 흔들린다.
    dx += sway * falloff * 0.8 * weight * intensity;
  }

  final cap = normalizedY <= bands.faceEnd
      ? limits.maxFace
      : inSkirt
      ? limits.maxSkirt
      : normalizedY <= bands.hairEnd
      ? limits.maxHair
      : limits.maxTorso;
  final bound = math.min(cap, limits.maxAny);

  // 발은 접지를 고정한다.
  if (normalizedY >= bands.legEnd) {
    final settle = ((1 - normalizedY) / (1 - bands.legEnd)).clamp(0.0, 1.0);
    dx *= settle;
    dy *= settle;
  }

  return CharacterVertexOffset(
    dx.clamp(-bound, bound),
    dy.clamp(-bound, bound),
  );
}
