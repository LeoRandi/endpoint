import '../entities/pattern/operative_pattern_point.dart';
import 'package:flutter/widgets.dart';

/// Converts a logical pattern coordinate into a Flutter canvas position.
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
