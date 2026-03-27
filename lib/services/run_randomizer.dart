import '_imports.dart';

class RunRandomizer {
  final Random _random;

  RunRandomizer({
    int? seed,
  }) : _random = seed == null ? Random() : Random(seed);

  int nextInt(int max) => _random.nextInt(max);

  double nextDouble() => _random.nextDouble();

  bool chance(double probability) => nextDouble() <= probability;

  List<T> pickDistinct<T>(Iterable<T> items, int count) {
    final remaining = List<T>.from(items);
    final pickedItems = <T>[];

    while (pickedItems.length < count && remaining.isNotEmpty) {
      pickedItems.add(remaining.removeAt(nextInt(remaining.length)));
    }

    return List<T>.unmodifiable(pickedItems);
  }
}
