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
