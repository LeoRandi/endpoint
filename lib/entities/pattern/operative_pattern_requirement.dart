import 'operative_pattern_point.dart';

/// Tipo de condicion espacial que debe cumplir un item dentro de un patron.
enum OperativePatternRequirementKind {
  firstPoint,
  middlePoint,
  lastPoint,
  rightAngle,
  straightAngle,
}

class OperativePatternRequirement {
  final OperativePatternRequirementKind kind;

  /// Requiere que el item este en el primer punto del trazo normalizado.
  const OperativePatternRequirement.first()
      : kind = OperativePatternRequirementKind.firstPoint;

  /// Requiere que el item ocupe el punto central del recorrido.
  const OperativePatternRequirement.middle()
      : kind = OperativePatternRequirementKind.middlePoint;

  /// Requiere que el item este en el ultimo punto antes del cierre.
  const OperativePatternRequirement.last()
      : kind = OperativePatternRequirementKind.lastPoint;

  /// Requiere que el item sea vertice de un angulo recto dentro del trazo.
  const OperativePatternRequirement.rightAngle()
      : kind = OperativePatternRequirementKind.rightAngle;

  const OperativePatternRequirement.straightAngle()
      : kind = OperativePatternRequirementKind.straightAngle;

  /// Comprueba si [itemPoint] satisface este requisito dentro del trazo actual.
  ///
  /// Los patrones cerrados llegan con el primer punto repetido al final; antes
  /// de validar se normaliza la secuencia para que los indices correspondan solo
  /// a vertices reales.
  bool isSatisfiedBy({
    required List<OperativePatternPoint> patternPoints,
    required OperativePatternPoint itemPoint,
  }) {
    final sequence = normalizedSequence(patternPoints);
    if (sequence.isEmpty || !sequence.contains(itemPoint)) return false;

    return switch (kind) {
      OperativePatternRequirementKind.firstPoint => sequence.first == itemPoint,
      OperativePatternRequirementKind.middlePoint =>
        _isMiddlePoint(sequence, itemPoint),
      OperativePatternRequirementKind.lastPoint => sequence.last == itemPoint,
      OperativePatternRequirementKind.rightAngle =>
        _isRightAngleVertex(sequence, itemPoint),
      OperativePatternRequirementKind.straightAngle =>
        _isStraightAngleVertex(sequence, itemPoint),
    };
  }

  /// Indica si la secuencia trae cierre explicito repitiendo el primer punto.
  static bool isClosedPattern(List<OperativePatternPoint> patternPoints) {
    return patternPoints.length >= 4 &&
        patternPoints.first == patternPoints.last;
  }

  /// Elimina el punto de cierre duplicado cuando existe.
  ///
  /// Devuelve siempre una lista inmodificable para que servicios y widgets no
  /// alteren accidentalmente la secuencia que estan validando.
  static List<OperativePatternPoint> normalizedSequence(
    List<OperativePatternPoint> patternPoints,
  ) {
    if (patternPoints.length >= 2 &&
        patternPoints.first == patternPoints.last) {
      return List<OperativePatternPoint>.unmodifiable(
        patternPoints.take(patternPoints.length - 1),
      );
    }

    return List<OperativePatternPoint>.unmodifiable(patternPoints);
  }

  /// Cuenta vertices distintos ignorando el punto de cierre duplicado.
  static int distinctPointCount(List<OperativePatternPoint> patternPoints) {
    return normalizedSequence(patternPoints).toSet().length;
  }

  /// Comprueba si el punto ocupa una posicion central del trazo normalizado.
  bool _isMiddlePoint(
    List<OperativePatternPoint> sequence,
    OperativePatternPoint itemPoint,
  ) {
    if (sequence.length == 1) return sequence.first == itemPoint;

    final middleIndex = sequence.length ~/ 2;
    if (sequence.length.isOdd) return sequence[middleIndex] == itemPoint;

    return sequence[middleIndex - 1] == itemPoint ||
        sequence[middleIndex] == itemPoint;
  }

  /// Determina si [itemPoint] forma un angulo recto con sus vecinos.
  ///
  /// El producto escalar de los vectores entrante y saliente debe ser cero; los
  /// segmentos degenerados se ignoran para evitar falsos positivos.
  bool _isRightAngleVertex(
    List<OperativePatternPoint> sequence,
    OperativePatternPoint itemPoint,
  ) {
    if (sequence.length < 3) return false;

    for (var index = 0; index < sequence.length; index++) {
      if (sequence[index] != itemPoint) continue;

      final previous =
          sequence[(index - 1 + sequence.length) % sequence.length];
      final next = sequence[(index + 1) % sequence.length];
      final incomingX = previous.x - itemPoint.x;
      final incomingY = previous.y - itemPoint.y;
      final outgoingX = next.x - itemPoint.x;
      final outgoingY = next.y - itemPoint.y;
      if ((incomingX == 0 && incomingY == 0) ||
          (outgoingX == 0 && outgoingY == 0)) {
        continue;
      }

      if ((incomingX * outgoingX) + (incomingY * outgoingY) == 0) {
        return true;
      }
    }

    return false;
  }

  /// Determina si [itemPoint] forma un angulo llano con sus vecinos.
  bool _isStraightAngleVertex(
    List<OperativePatternPoint> sequence,
    OperativePatternPoint itemPoint,
  ) {
    if (sequence.length < 3) return false;

    for (var index = 0; index < sequence.length; index++) {
      if (sequence[index] != itemPoint) continue;

      final previous =
          sequence[(index - 1 + sequence.length) % sequence.length];
      final next = sequence[(index + 1) % sequence.length];
      final incomingX = previous.x - itemPoint.x;
      final incomingY = previous.y - itemPoint.y;
      final outgoingX = next.x - itemPoint.x;
      final outgoingY = next.y - itemPoint.y;
      if ((incomingX == 0 && incomingY == 0) ||
          (outgoingX == 0 && outgoingY == 0)) {
        continue;
      }

      final cross = incomingX * outgoingY - incomingY * outgoingX;
      final dot = incomingX * outgoingX + incomingY * outgoingY;
      if (cross == 0 && dot < 0) {
        return true;
      }
    }

    return false;
  }
}
