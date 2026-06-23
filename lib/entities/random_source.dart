/// Minimal random source required by domain rules.
///
/// Concrete seeded state and platform entropy belong to the application
/// layer; entities depend only on this small deterministic contract.
abstract interface class RandomSource {
  int nextInt(int max);
  double nextDouble();
  bool chance(double probability);
  List<T> pickDistinct<T>(Iterable<T> items, int count);
}
