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
