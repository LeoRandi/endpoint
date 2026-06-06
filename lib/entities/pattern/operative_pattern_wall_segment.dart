import 'dart:math' as math;

import 'operative_pattern_point.dart';

/// Barrera lineal entre dos puntos del Patron que impide cruzar ese tramo.
class OperativePatternWallSegment {
  static const double baseHalfLength = 0.45;
  static const double connectedHalfLength = 0.56;

  final OperativePatternPoint a;
  final OperativePatternPoint b;

  /// Crea una pared entre dos puntos del Patron operativo.
  const OperativePatternWallSegment({
    required this.a,
    required this.b,
  });

  /// Devuelve una clave estable independiente del orden de los extremos.
  String get key {
    final keys = [a.key, b.key]..sort();
    return '${keys.first}|${keys.last}';
  }

  /// Indica si el movimiento entre [from] y [to] atraviesa esta pared.
  ///
  /// Las paredes conectadas se vuelven ligeramente mas largas para cubrir
  /// uniones visuales entre segmentos adyacentes.
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

  /// Punto central desde el que se proyecta el tramo visible de bloqueo.
  _PatternVector get _midpoint {
    return _PatternVector(
      (a.x + b.x) / 2,
      (a.y + b.y) / 2,
    );
  }

  /// Vector perpendicular normalizado usado para dibujar la pared.
  _PatternVector get _normal {
    final dx = (b.x - a.x).toDouble();
    final dy = (b.y - a.y).toDouble();
    final length = math.sqrt((dx * dx) + (dy * dy));
    if (length == 0) return const _PatternVector(0, 0);

    return _PatternVector(-dy / length, dx / length);
  }

  /// Devuelve la media longitud efectiva segun si la pared esta conectada.
  double _halfLength({required bool isConnected}) {
    return isConnected ? connectedHalfLength : baseHalfLength;
  }

  /// Calcula el extremo inicial del segmento de bloqueo.
  _PatternVector _start({required bool isConnected}) {
    return _midpoint - (_normal * _halfLength(isConnected: isConnected));
  }

  /// Calcula el extremo final del segmento de bloqueo.
  _PatternVector _end({required bool isConnected}) {
    return _midpoint + (_normal * _halfLength(isConnected: isConnected));
  }

  /// Comprueba interseccion entre dos segmentos con tolerancia numerica.
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

  /// Indica si [point] cae dentro del rectangulo minimo definido por [a] y [b].
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

  /// Calcula el producto cruzado de dos vectores 2D.
  static double _cross(_PatternVector a, _PatternVector b) {
    return (a.x * b.y) - (a.y * b.x);
  }

  /// Devuelve el menor de dos valores evitando importar helpers extra.
  static double _min(double a, double b) => a < b ? a : b;

  /// Devuelve el mayor de dos valores evitando importar helpers extra.
  static double _max(double a, double b) => a > b ? a : b;

  /// Compara paredes por su clave estable y no por la orientacion declarada.
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is OperativePatternWallSegment && other.key == key;
  }

  /// Usa la misma clave estable que la igualdad para funcionar en sets.
  @override
  int get hashCode => key.hashCode;
}

/// Vector 2D ligero para calculos de interseccion de paredes.
class _PatternVector {
  final double x;
  final double y;

  /// Crea un vector con coordenadas de precision doble.
  const _PatternVector(this.x, this.y);

  /// Suma dos vectores componente a componente.
  _PatternVector operator +(_PatternVector other) {
    return _PatternVector(x + other.x, y + other.y);
  }

  /// Resta dos vectores componente a componente.
  _PatternVector operator -(_PatternVector other) {
    return _PatternVector(x - other.x, y - other.y);
  }

  /// Escala el vector por un factor numerico.
  _PatternVector operator *(double factor) {
    return _PatternVector(x * factor, y * factor);
  }
}
