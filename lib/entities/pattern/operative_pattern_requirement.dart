import 'operative_pattern_point.dart';

enum OperativePatternRequirementKind {
  firstPoint,
  middlePoint,
  lastPoint,
  rightAngle,
  straightAngle,
  exactShape,
}

enum OperativePatternShapeKind {
  literal,
  square,
  diamond,
  hourglass,
  zigzag,
}

class OperativePatternRequirement {
  static const int maxExactShapePoints = 12;

  final OperativePatternRequirementKind kind;
  final List<OperativePatternPoint> shapePoints;
  final OperativePatternShapeKind shapeKind;
  final String? labelOverride;

  const OperativePatternRequirement.first()
      : kind = OperativePatternRequirementKind.firstPoint,
        shapePoints = const <OperativePatternPoint>[],
        shapeKind = OperativePatternShapeKind.literal,
        labelOverride = null;

  const OperativePatternRequirement.middle()
      : kind = OperativePatternRequirementKind.middlePoint,
        shapePoints = const <OperativePatternPoint>[],
        shapeKind = OperativePatternShapeKind.literal,
        labelOverride = null;

  const OperativePatternRequirement.last()
      : kind = OperativePatternRequirementKind.lastPoint,
        shapePoints = const <OperativePatternPoint>[],
        shapeKind = OperativePatternShapeKind.literal,
        labelOverride = null;

  const OperativePatternRequirement.rightAngle()
      : kind = OperativePatternRequirementKind.rightAngle,
        shapePoints = const <OperativePatternPoint>[],
        shapeKind = OperativePatternShapeKind.literal,
        labelOverride = null;

  const OperativePatternRequirement.straightAngle()
      : kind = OperativePatternRequirementKind.straightAngle,
        shapePoints = const <OperativePatternPoint>[],
        shapeKind = OperativePatternShapeKind.literal,
        labelOverride = null;

  const OperativePatternRequirement.exactShape({
    required this.shapePoints,
    this.shapeKind = OperativePatternShapeKind.literal,
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
            sequence.contains(itemPoint),
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
    return switch (shapeKind) {
      OperativePatternShapeKind.square ||
      OperativePatternShapeKind.diamond =>
        _matchesSquareLike(sequence),
      OperativePatternShapeKind.hourglass => _matchesHourglassLike(sequence),
      OperativePatternShapeKind.zigzag ||
      OperativePatternShapeKind.literal =>
        _matchesLiteralExactShape(sequence),
    };
  }

  bool _matchesLiteralExactShape(List<OperativePatternPoint> sequence) {
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

  bool _matchesSquareLike(List<OperativePatternPoint> sequence) {
    final corners = _compressedClosedCorners(sequence);
    if (corners.length != 4) return false;

    final vectors = _closedEdgeVectors(corners);
    if (vectors.any(_isZeroVector)) return false;

    final sideLength = _lengthSquared(vectors.first);
    if (sideLength <= 0) return false;
    if (vectors.any((vector) => _lengthSquared(vector) != sideLength)) {
      return false;
    }

    for (var index = 0; index < vectors.length; index++) {
      final nextIndex = (index + 1) % vectors.length;
      if (_dot(vectors[index], vectors[nextIndex]) != 0) return false;
    }

    return true;
  }

  bool _matchesHourglassLike(List<OperativePatternPoint> sequence) {
    final corners = _compressedClosedCorners(sequence);
    if (corners.length != 4) return false;

    final firstTop = _vectorBetween(corners[0], corners[1]);
    final secondBase = _vectorBetween(corners[2], corners[3]);
    if (_isZeroVector(firstTop) || _isZeroVector(secondBase)) return false;
    if (_cross(firstTop, secondBase) != 0) return false;
    if (_lengthSquared(firstTop) != _lengthSquared(secondBase)) return false;

    return _segmentsIntersect(
      corners[1],
      corners[2],
      corners[3],
      corners[0],
    );
  }

  List<OperativePatternPoint> _compressedClosedCorners(
    List<OperativePatternPoint> sequence,
  ) {
    final deduped = _removeConsecutiveDuplicates(sequence);
    if (deduped.length <= 2) return deduped;

    final corners = <OperativePatternPoint>[];
    for (var index = 0; index < deduped.length; index++) {
      final previous = deduped[(index - 1 + deduped.length) % deduped.length];
      final current = deduped[index];
      final next = deduped[(index + 1) % deduped.length];
      final incoming = _vectorBetween(previous, current);
      final outgoing = _vectorBetween(current, next);
      if (_isZeroVector(incoming) || _isZeroVector(outgoing)) continue;
      if (_cross(incoming, outgoing) == 0 && _dot(incoming, outgoing) > 0) {
        continue;
      }
      corners.add(current);
    }

    return List<OperativePatternPoint>.unmodifiable(corners);
  }

  List<OperativePatternPoint> _removeConsecutiveDuplicates(
    List<OperativePatternPoint> points,
  ) {
    final deduped = <OperativePatternPoint>[];
    for (final point in points) {
      if (deduped.isNotEmpty && deduped.last == point) continue;
      deduped.add(point);
    }
    return List<OperativePatternPoint>.unmodifiable(deduped);
  }

  List<OperativePatternPoint> _closedEdgeVectors(
    List<OperativePatternPoint> points,
  ) {
    return List<OperativePatternPoint>.unmodifiable([
      for (var index = 0; index < points.length; index++)
        _vectorBetween(points[index], points[(index + 1) % points.length]),
    ]);
  }

  OperativePatternPoint _vectorBetween(
    OperativePatternPoint from,
    OperativePatternPoint to,
  ) {
    return OperativePatternPoint(
      x: to.x - from.x,
      y: to.y - from.y,
    );
  }

  bool _isZeroVector(OperativePatternPoint vector) {
    return vector.x == 0 && vector.y == 0;
  }

  int _dot(OperativePatternPoint a, OperativePatternPoint b) {
    return a.x * b.x + a.y * b.y;
  }

  int _cross(OperativePatternPoint a, OperativePatternPoint b) {
    return a.x * b.y - a.y * b.x;
  }

  int _lengthSquared(OperativePatternPoint vector) {
    return vector.x * vector.x + vector.y * vector.y;
  }

  bool _segmentsIntersect(
    OperativePatternPoint a,
    OperativePatternPoint b,
    OperativePatternPoint c,
    OperativePatternPoint d,
  ) {
    final ab = _vectorBetween(a, b);
    final ac = _vectorBetween(a, c);
    final ad = _vectorBetween(a, d);
    final cd = _vectorBetween(c, d);
    final ca = _vectorBetween(c, a);
    final cb = _vectorBetween(c, b);
    final firstSide = _cross(ab, ac);
    final secondSide = _cross(ab, ad);
    final thirdSide = _cross(cd, ca);
    final fourthSide = _cross(cd, cb);

    return firstSide.sign != secondSide.sign &&
        thirdSide.sign != fourthSide.sign;
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
