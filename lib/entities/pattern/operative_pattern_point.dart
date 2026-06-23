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

class OperativePatternPoint {
  final int x;
  final int y;

  /// Crea un punto por coordenadas logicas del tablero.
  const OperativePatternPoint({
    required this.x,
    required this.y,
  });

  /// Devuelve una representacion corta y no localizada para diagnostico.
  String get debugLabel => '[$x, $y]';

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
