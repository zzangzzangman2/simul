/// Multiplies a 31-bit hash by the FNV prime exactly on Dart VM and Web.
///
/// JavaScript numbers cannot exactly represent the direct 32-bit product.
/// Splitting the value into 16-bit limbs keeps every intermediate below 2^53.
int multiplyFnvPrime31Exact(int value) {
  final low = value & 0xffff;
  final high = (value ~/ 0x10000) & 0xffff;
  final lowProduct = low * 0x0193;
  final crossProduct = low * 0x0100 + high * 0x0193;
  return (lowProduct + (crossProduct & 0x7fff) * 0x10000) & 0x7fffffff;
}

int stableHash31(String value) {
  var hash = 0x811c9dc5 & 0x7fffffff;
  for (final unit in value.codeUnits) {
    hash ^= unit;
    hash = multiplyFnvPrime31Exact(hash);
  }
  return hash & 0x7fffffff;
}

/// Multiplies two 31-bit integers modulo 2^31 without exceeding JavaScript's
/// exact integer range. This keeps deterministic random streams identical on
/// the Dart VM and Flutter Web.
int multiply31Exact(int left, int right) {
  final leftLow = left & 0xffff;
  final leftHigh = (left >> 16) & 0x7fff;
  final rightLow = right & 0xffff;
  final rightHigh = (right >> 16) & 0x7fff;
  final lowProduct = leftLow * rightLow;
  final crossProduct = leftLow * rightHigh + leftHigh * rightLow;
  return (lowProduct + (crossProduct & 0x7fff) * 0x10000) & 0x7fffffff;
}

int _avalanche31(int value) {
  var mixed = value & 0x7fffffff;
  mixed ^= mixed >> 16;
  mixed = multiply31Exact(mixed, 0x05ebca6b);
  mixed ^= mixed >> 13;
  mixed = multiply31Exact(mixed, 0x42b2ae35);
  mixed ^= mixed >> 16;
  return mixed & 0x7fffffff;
}

int _rotateLeft31(int value, int shift) {
  final amount = shift % 31;
  final masked = value & 0x7fffffff;
  if (amount == 0) return masked;
  return ((masked << amount) | (masked >> (31 - amount))) & 0x7fffffff;
}

/// Produces a strongly diffused deterministic 31-bit word.
///
/// Two directionally different FNV passes are combined before a Murmur-style
/// avalanche. This avoids exposing FNV's weak low-bit patterns when nearby
/// sequence numbers are used as keys.
int stableRandomWord31(String key, {int nonce = 0}) {
  final forward = stableHash31('random-v2:$nonce:$key');
  final reverse = stableHash31('$key:$nonce:2v-modnar');
  return _avalanche31(forward ^ _rotateLeft31(reverse, 11) ^ 0x6d2b79f5);
}

/// Returns an unbiased deterministic integer in `[0, upperBound)`.
///
/// Rejection sampling prevents modulo bias. Domain-separate independent game
/// streams in [key] instead of consuming adjacent bits from the same word.
int stableRandomInt(String key, int upperBound) {
  if (upperBound <= 0 || upperBound > 0x7fffffff) {
    throw RangeError.range(upperBound, 1, 0x7fffffff, 'upperBound');
  }
  const range = 0x80000000;
  final acceptedRange = range - (range % upperBound);
  for (var nonce = 0; ; nonce++) {
    final value = stableRandomWord31(key, nonce: nonce);
    if (value < acceptedRange) return value % upperBound;
  }
}
