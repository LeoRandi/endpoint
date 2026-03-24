import '_imports.dart';

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

  const RarityTier({
    required this.accent,
    required this.label,
    required this.factor,
    required this.rollWeight,
  });
}
