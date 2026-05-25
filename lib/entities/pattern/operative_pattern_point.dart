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

  const OperativePatternPoint({
    required this.x,
    required this.y,
  });

  String get label => '[$x, $y]';
  String get key => operativePatternPointKey(x, y);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is OperativePatternPoint && other.x == x && other.y == y;
  }

  @override
  int get hashCode => Object.hash(x, y);
}
