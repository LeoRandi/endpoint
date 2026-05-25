import 'package:endpoint/entities/_exports.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OperativePatternRequirement exact shape matching', () {
    test('square accepts extra collinear points along its sides', () {
      const requirement = OperativePatternRequirement.exactShape(
        labelOverride: 'Cuadrado',
        shapeKind: OperativePatternShapeKind.square,
        shapePoints: <OperativePatternPoint>[
          OperativePatternPoint(x: 0, y: 0),
          OperativePatternPoint(x: 2, y: 0),
          OperativePatternPoint(x: 2, y: 2),
          OperativePatternPoint(x: 0, y: 2),
        ],
      );
      const itemPoint = OperativePatternPoint(x: 0, y: 0);
      const patternPoints = <OperativePatternPoint>[
        OperativePatternPoint(x: 0, y: 0),
        OperativePatternPoint(x: 1, y: 0),
        OperativePatternPoint(x: 2, y: 0),
        OperativePatternPoint(x: 2, y: 2),
        OperativePatternPoint(x: 1, y: 2),
        OperativePatternPoint(x: 0, y: 2),
        OperativePatternPoint(x: 0, y: 0),
      ];

      expect(
        requirement.isSatisfiedBy(
          patternPoints: patternPoints,
          itemPoint: itemPoint,
        ),
        isTrue,
      );
    });
  });
}
