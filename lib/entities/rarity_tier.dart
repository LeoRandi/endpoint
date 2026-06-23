import 'dart:math';

import 'package:flutter/material.dart';

/// Agrupa el color, el peso de aparicion y el factor economico de cada rareza.
enum RarityTier {
  gray(
    accent: Color(0xFF9EA7B3),
    label: 'GRIS',
    factor: 1,
    rollWeight: 1.45,
  ),
  green(
    accent: Color(0xFF5AF78E),
    label: 'VERDE',
    factor: 2,
    rollWeight: 1.1,
  ),
  blue(
    accent: Color(0xFF59B7FF),
    label: 'AZUL',
    factor: 3,
    rollWeight: 0.72,
  ),
  purple(
    accent: Color(0xFFBE7CFF),
    label: 'MORADO',
    factor: 4,
    rollWeight: 0.42,
  ),
  yellow(
    accent: Color(0xFFF3D35C),
    label: 'AMARILLO',
    factor: 5,
    rollWeight: 0.18,
  );

  final Color accent;
  final String label;
  final int factor;
  final double rollWeight;

  /// Crea una rareza con color, etiqueta, factor economico y peso de aparicion.
  const RarityTier({
    required this.accent,
    required this.label,
    required this.factor,
    required this.rollWeight,
  });

  /// Indica si esta rareza ya esta en el tope visual y no debe subir mas.
  bool get isMaxTier => this == RarityTier.yellow;

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
