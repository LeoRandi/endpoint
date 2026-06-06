import 'dart:ui';

const operativePatternPoints = <OperativePatternPoint>[
  OperativePatternPoint(x: -1, y: 1),
  OperativePatternPoint(x: 0, y: 1),
  OperativePatternPoint(x: 1, y: 1),
  OperativePatternPoint(x: -1, y: 0),
  OperativePatternPoint(x: 0, y: 0),
  OperativePatternPoint(x: 1, y: 0),
  OperativePatternPoint(x: -1, y: -1),
  OperativePatternPoint(x: 0, y: -1),
  OperativePatternPoint(x: 1, y: -1),
];

/// Serializa una coordenada de patron en una key estable para mapas y snapshots.
String operativePatternPointKey(int x, int y) => '$x,$y';

final Map<String, OperativePatternPoint> operativePatternPointsByKey =
    Map<String, OperativePatternPoint>.unmodifiable({
  for (final point in operativePatternPoints) point.key: point,
});

OperativePatternPoint? operativePatternPointAt({
  required int x,
  required int y,
}) {
  return operativePatternPointsByKey[operativePatternPointKey(x, y)];
}

Offset operativePatternPointCenter({
  required OperativePatternPoint point,
  required double boardSide,
}) {
  final cellSize = boardSide / 3;
  final column = point.x + 1;
  final row = 1 - point.y;

  return Offset(
    (column + 0.5) * cellSize,
    (row + 0.5) * cellSize,
  );
}

class OperativePatternPoint {
  final int x;
  final int y;

  /// Crea un punto por coordenadas logicas del tablero.
  const OperativePatternPoint({
    required this.x,
    required this.y,
  });

  /// Devuelve una etiqueta corta para debug y detalles de configuracion.
  String get label => '[$x, $y]';

  /// Devuelve la key persistible usada para asignaciones de items por punto.
  String get key => operativePatternPointKey(x, y);

  /// Compara puntos por coordenadas para que snapshots reconstruidos coincidan.
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is OperativePatternPoint && other.x == x && other.y == y;
  }

  /// Agrupa [x] e [y] para usar puntos como keys de mapas y sets.
  @override
  int get hashCode => Object.hash(x, y);
}
