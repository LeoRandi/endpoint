import 'dart:math';

/// Agrupa el peso de aparicion y el factor economico de cada rareza.
enum RarityTier {
  gray(
    factor: 1,
    rollWeight: 1.45,
  ),
  green(
    factor: 2,
    rollWeight: 1.1,
  ),
  blue(
    factor: 3,
    rollWeight: 0.72,
  ),
  purple(
    factor: 4,
    rollWeight: 0.42,
  ),
  yellow(
    factor: 5,
    rollWeight: 0.18,
  );

  final int factor;
  final double rollWeight;

  /// Crea una rareza con su factor economico y peso de aparicion.
  const RarityTier({
    required this.factor,
    required this.rollWeight,
  });

  /// Indica si esta rareza ya esta en el tope y no debe subir mas.
  bool get isMaxTier => this == RarityTier.yellow;

  /// Compara esta rareza con [other] usando el orden canonico de tiers.
  int compareToTier(RarityTier other) {
    return index.compareTo(other.index);
  }

  /// Indica si esta rareza es estrictamente superior a [other].
  bool isAbove(RarityTier other) {
    return compareToTier(other) > 0;
  }

  /// Indica si esta rareza es estrictamente inferior a [other].
  bool isBelow(RarityTier other) {
    return compareToTier(other) < 0;
  }

  /// Indica si esta rareza es igual o superior a [other].
  bool isAtLeast(RarityTier other) {
    return compareToTier(other) >= 0;
  }

  /// Indica si esta rareza es igual o inferior a [other].
  bool isAtMost(RarityTier other) {
    return compareToTier(other) <= 0;
  }

  /// Devuelve cuantos pasos separan esta rareza de [other].
  ///
  /// Un valor positivo significa que [other] esta por encima de esta rareza.
  int distanceTo(RarityTier other) {
    return other.index - index;
  }

  /// Devuelve la siguiente rareza disponible sin sobrepasar amarillo.
  RarityTier get nextTier {
    if (isMaxTier) return this;

    return RarityTier.values[index + 1];
  }

  /// Avanza varios tiers seguidos respetando siempre el limite amarillo.
  RarityTier advanceBy(int steps) {
    if (steps <= 0) return this;

    final targetIndex = min(
      index + steps,
      RarityTier.values.length - 1,
    );
    return RarityTier.values[targetIndex];
  }
}
