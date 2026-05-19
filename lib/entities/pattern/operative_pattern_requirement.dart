import 'operative_pattern_point.dart';

enum OperativePatternRequirementKind {
  firstPoint,
  middlePoint,
  lastPoint,
  rightAngle,
  straightAngle,
  exactShape,
}

class OperativePatternRequirement {
  static const int maxExactShapePoints = 6;

  final OperativePatternRequirementKind kind;
  final List<OperativePatternPoint> shapePoints;
  final String? labelOverride;

  const OperativePatternRequirement.first()
      : kind = OperativePatternRequirementKind.firstPoint,
        shapePoints = const <OperativePatternPoint>[],
        labelOverride = null;

  const OperativePatternRequirement.middle()
      : kind = OperativePatternRequirementKind.middlePoint,
        shapePoints = const <OperativePatternPoint>[],
        labelOverride = null;

  const OperativePatternRequirement.last()
      : kind = OperativePatternRequirementKind.lastPoint,
        shapePoints = const <OperativePatternPoint>[],
        labelOverride = null;

  const OperativePatternRequirement.rightAngle()
      : kind = OperativePatternRequirementKind.rightAngle,
        shapePoints = const <OperativePatternPoint>[],
        labelOverride = null;

  const OperativePatternRequirement.straightAngle()
      : kind = OperativePatternRequirementKind.straightAngle,
        shapePoints = const <OperativePatternPoint>[],
        labelOverride = null;

  const OperativePatternRequirement.exactShape({
    required this.shapePoints,
    this.labelOverride,
  }) : kind = OperativePatternRequirementKind.exactShape;

  String get label {
    final override = labelOverride;
    if (override != null && override.isNotEmpty) return override;

    return switch (kind) {
      OperativePatternRequirementKind.firstPoint => 'Inicio',
      OperativePatternRequirementKind.middlePoint => 'Centro',
      OperativePatternRequirementKind.lastPoint => 'Final',
      OperativePatternRequirementKind.rightAngle => 'Angulo 90',
      OperativePatternRequirementKind.straightAngle => 'Angulo 180',
      OperativePatternRequirementKind.exactShape => 'Figura',
    };
  }

  String get shortLabel {
    return switch (kind) {
      OperativePatternRequirementKind.firstPoint => 'INI',
      OperativePatternRequirementKind.middlePoint => 'MED',
      OperativePatternRequirementKind.lastPoint => 'FIN',
      OperativePatternRequirementKind.rightAngle => '90',
      OperativePatternRequirementKind.straightAngle => '180',
      OperativePatternRequirementKind.exactShape => _shortExactShapeLabel,
    };
  }

  String get description {
    return switch (kind) {
      OperativePatternRequirementKind.firstPoint =>
        'Debe ser el primer punto del trazo.',
      OperativePatternRequirementKind.middlePoint =>
        'Debe quedar en una posicion central del recorrido.',
      OperativePatternRequirementKind.lastPoint =>
        'Debe ser el ultimo vertice antes de cerrar.',
      OperativePatternRequirementKind.rightAngle =>
        'Debe ser el vertice de un angulo recto.',
      OperativePatternRequirementKind.straightAngle =>
        'Debe ser el vertice de un angulo llano de 180 grados.',
      OperativePatternRequirementKind.exactShape =>
        'El dibujo debe seguir esta figura en el orden indicado.',
    };
  }

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
      OperativePatternRequirementKind.exactShape =>
        isClosedPattern(patternPoints) &&
            _matchesExactShape(sequence) &&
            shapePoints.contains(itemPoint),
    };
  }

  static bool isClosedPattern(List<OperativePatternPoint> patternPoints) {
    return patternPoints.length >= 4 &&
        patternPoints.first == patternPoints.last;
  }

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

  static int distinctPointCount(List<OperativePatternPoint> patternPoints) {
    return normalizedSequence(patternPoints).toSet().length;
  }

  String get _shortExactShapeLabel {
    final compactLabel = label.replaceAll(' ', '');
    if (compactLabel.length <= 3) return compactLabel.toUpperCase();
    return compactLabel.substring(0, 3).toUpperCase();
  }

  bool _matchesExactShape(List<OperativePatternPoint> sequence) {
    if (sequence.length != shapePoints.length) return false;

    return _matchesCyclicShape(sequence, shapePoints) ||
        _matchesCyclicShape(
          sequence,
          shapePoints.reversed.toList(growable: false),
        );
  }

  bool _matchesCyclicShape(
    List<OperativePatternPoint> sequence,
    List<OperativePatternPoint> candidateShape,
  ) {
    for (var startIndex = 0; startIndex < candidateShape.length; startIndex++) {
      var didMatch = true;
      for (var index = 0; index < sequence.length; index++) {
        final candidateIndex = (startIndex + index) % candidateShape.length;
        if (sequence[index] != candidateShape[candidateIndex]) {
          didMatch = false;
          break;
        }
      }
      if (didMatch) return true;
    }

    return false;
  }

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
