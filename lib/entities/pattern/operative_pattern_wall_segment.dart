import 'dart:math' as math;

import 'operative_pattern_point.dart';

/// Barrera lineal entre dos puntos del Patron que impide cruzar ese tramo.
class OperativePatternWallSegment {
  static const double baseHalfLength = 0.45;
  static const double connectedHalfLength = 0.56;

  final OperativePatternPoint a;
  final OperativePatternPoint b;

  const OperativePatternWallSegment({
    required this.a,
    required this.b,
  });

  String get key {
    final keys = [a.key, b.key]..sort();
    return '${keys.first}|${keys.last}';
  }

  bool blocks(
    OperativePatternPoint from,
    OperativePatternPoint to, {
    bool isConnected = false,
  }) {
    return _segmentsIntersect(
      _PatternVector(from.x.toDouble(), from.y.toDouble()),
      _PatternVector(to.x.toDouble(), to.y.toDouble()),
      _start(isConnected: isConnected),
      _end(isConnected: isConnected),
    );
  }

  _PatternVector get _midpoint {
    return _PatternVector(
      (a.x + b.x) / 2,
      (a.y + b.y) / 2,
    );
  }

  _PatternVector get _normal {
    final dx = (b.x - a.x).toDouble();
    final dy = (b.y - a.y).toDouble();
    final length = math.sqrt((dx * dx) + (dy * dy));
    if (length == 0) return const _PatternVector(0, 0);

    return _PatternVector(-dy / length, dx / length);
  }

  double _halfLength({required bool isConnected}) {
    return isConnected ? connectedHalfLength : baseHalfLength;
  }

  _PatternVector _start({required bool isConnected}) {
    return _midpoint - (_normal * _halfLength(isConnected: isConnected));
  }

  _PatternVector _end({required bool isConnected}) {
    return _midpoint + (_normal * _halfLength(isConnected: isConnected));
  }

  static bool _segmentsIntersect(
    _PatternVector a,
    _PatternVector b,
    _PatternVector c,
    _PatternVector d,
  ) {
    final abC = _cross(b - a, c - a);
    final abD = _cross(b - a, d - a);
    final cdA = _cross(d - c, a - c);
    final cdB = _cross(d - c, b - c);

    const epsilon = 0.000001;
    if (abC.abs() <= epsilon && _isBetween(a, c, b)) return true;
    if (abD.abs() <= epsilon && _isBetween(a, d, b)) return true;
    if (cdA.abs() <= epsilon && _isBetween(c, a, d)) return true;
    if (cdB.abs() <= epsilon && _isBetween(c, b, d)) return true;

    return (abC > 0) != (abD > 0) && (cdA > 0) != (cdB > 0);
  }

  static bool _isBetween(
    _PatternVector a,
    _PatternVector point,
    _PatternVector b,
  ) {
    return point.x >= _min(a.x, b.x) &&
        point.x <= _max(a.x, b.x) &&
        point.y >= _min(a.y, b.y) &&
        point.y <= _max(a.y, b.y);
  }

  static double _cross(_PatternVector a, _PatternVector b) {
    return (a.x * b.y) - (a.y * b.x);
  }

  static double _min(double a, double b) => a < b ? a : b;
  static double _max(double a, double b) => a > b ? a : b;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is OperativePatternWallSegment && other.key == key;
  }

  @override
  int get hashCode => key.hashCode;
}

class _PatternVector {
  final double x;
  final double y;

  const _PatternVector(this.x, this.y);

  _PatternVector operator +(_PatternVector other) {
    return _PatternVector(x + other.x, y + other.y);
  }

  _PatternVector operator -(_PatternVector other) {
    return _PatternVector(x - other.x, y - other.y);
  }

  _PatternVector operator *(double factor) {
    return _PatternVector(x * factor, y * factor);
  }
}
