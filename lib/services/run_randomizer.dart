import '_imports.dart';

class RunRandomizer {
  static const int _stateMask = 0x7fffffff;
  static const int _defaultSeed = 0x13579BDF;

  final int seed;
  int _state;

  RunRandomizer({
    int? seed,
    int? state,
  }) : this._resolved(
          _sanitizeSeed(seed ?? Random().nextInt(_stateMask)),
          state,
        );

  RunRandomizer._resolved(int resolvedSeed, int? state)
      : seed = resolvedSeed,
        _state = _sanitizeSeed(state ?? resolvedSeed);

  int get state => _state;

  int nextInt(int max) {
    if (max <= 0) {
      throw RangeError.range(max, 1, null, 'max');
    }

    return _nextState() % max;
  }

  double nextDouble() => _nextState() / _stateMask;

  bool chance(double probability) => nextDouble() <= probability;

  List<T> pickDistinct<T>(Iterable<T> items, int count) {
    final remaining = List<T>.from(items);
    final pickedItems = <T>[];

    while (pickedItems.length < count && remaining.isNotEmpty) {
      pickedItems.add(remaining.removeAt(nextInt(remaining.length)));
    }

    return List<T>.unmodifiable(pickedItems);
  }

  int _nextState() {
    var value = _state;
    value ^= (value << 13) & _stateMask;
    value ^= value >> 17;
    value ^= (value << 5) & _stateMask;
    _state = _sanitizeSeed(value);
    return _state;
  }

  static int _sanitizeSeed(int rawValue) {
    final sanitizedValue = rawValue & _stateMask;
    return sanitizedValue == 0 ? _defaultSeed : sanitizedValue;
  }
}
