import 'dart:math';

class Rng {
  final Random _r;
  Rng([int? seed]) : _r = Random(seed);
  int range(int min, int max) => min + _r.nextInt((max - min) + 1);
}
