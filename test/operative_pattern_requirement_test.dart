import 'package:endpoint/entities/_exports.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OperativePatternWallSegment', () {
    test('blocks collinear segments that cross the wall', () {
      const wall = OperativePatternWallSegment(
        a: OperativePatternPoint(x: -1, y: 0),
        b: OperativePatternPoint(x: 0, y: 0),
      );

      expect(
        wall.blocks(
          const OperativePatternPoint(x: -1, y: 0),
          const OperativePatternPoint(x: 0, y: 0),
        ),
        isTrue,
      );
      expect(
        wall.blocks(
          const OperativePatternPoint(x: -1, y: 0),
          const OperativePatternPoint(x: 1, y: 0),
        ),
        isTrue,
      );
      expect(
        wall.blocks(
          const OperativePatternPoint(x: -1, y: 1),
          const OperativePatternPoint(x: 1, y: 1),
        ),
        isFalse,
      );
      expect(
        wall.blocks(
          const OperativePatternPoint(x: -1, y: -1),
          const OperativePatternPoint(x: 0, y: 1),
        ),
        isTrue,
      );
      expect(
        wall.blocks(
          const OperativePatternPoint(x: -1, y: 0),
          const OperativePatternPoint(x: -1, y: 1),
        ),
        isFalse,
      );
    });

    test('connected perpendicular walls do not leave a diagonal gap', () {
      const walls = [
        OperativePatternWallSegment(
          a: OperativePatternPoint(x: -1, y: 0),
          b: OperativePatternPoint(x: 0, y: 0),
        ),
        OperativePatternWallSegment(
          a: OperativePatternPoint(x: 0, y: 0),
          b: OperativePatternPoint(x: 0, y: 1),
        ),
      ];

      final isBlocked = walls.any(
        (wall) => wall.blocks(
          const OperativePatternPoint(x: -1, y: 1),
          const OperativePatternPoint(x: 0, y: 0),
          isConnected: true,
        ),
      );

      expect(isBlocked, isTrue);
    });

    test('lone walls keep their shorter collision length', () {
      const wall = OperativePatternWallSegment(
        a: OperativePatternPoint(x: -1, y: 0),
        b: OperativePatternPoint(x: 0, y: 0),
      );

      expect(
        wall.blocks(
          const OperativePatternPoint(x: -1, y: 1),
          const OperativePatternPoint(x: 0, y: 0),
        ),
        isFalse,
      );
    });
  });

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
