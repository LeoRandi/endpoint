import 'package:endpoint/widgets/path/operative_sketch_recognition_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const helper = OperativeSketchRecognitionHelper();

  test('recognizes scissors from a single continuous stroke', () {
    final stroke = _interpolatePolyline(
      <Offset>[
        const Offset(56, 56),
        const Offset(120, 132),
        const Offset(80, 232),
        const Offset(164, 232),
        const Offset(120, 132),
        const Offset(168, 60),
      ],
      samplesPerSegment: 10,
    );

    final result = helper.scan(
      strokes: <List<Offset>>[stroke],
      canvasSize: const Size(240, 300),
    );

    expect(result.kind, OperativeSketchRecognitionKind.scissors);
    expect(
      result.matches.any(
        (match) => match.kind == OperativeSketchRecognitionKind.scissors,
      ),
      isTrue,
    );
  });

  test('keeps recognizing a simple triangle as triangle', () {
    final stroke = _interpolatePolyline(
      <Offset>[
        const Offset(120, 54),
        const Offset(56, 212),
        const Offset(184, 212),
        const Offset(120, 54),
      ],
      samplesPerSegment: 10,
    );

    final result = helper.scan(
      strokes: <List<Offset>>[stroke],
      canvasSize: const Size(240, 300),
    );

    expect(result.kind, OperativeSketchRecognitionKind.triangle);
  });

  test('recognizes scissors drawn in multiple connected strokes', () {
    final triangleStroke = _interpolatePolyline(
      <Offset>[
        const Offset(120, 132),
        const Offset(84, 228),
        const Offset(164, 228),
        const Offset(120, 132),
      ],
      samplesPerSegment: 10,
    );
    final leftBranchStroke = _interpolatePolyline(
      <Offset>[
        const Offset(66, 68),
        const Offset(118, 136),
      ],
      samplesPerSegment: 10,
    );
    final rightBranchStroke = _interpolatePolyline(
      <Offset>[
        const Offset(172, 70),
        const Offset(122, 136),
      ],
      samplesPerSegment: 10,
    );

    final result = helper.scan(
      strokes: <List<Offset>>[
        triangleStroke,
        leftBranchStroke,
        rightBranchStroke,
      ],
      canvasSize: const Size(240, 300),
    );

    expect(result.kind, OperativeSketchRecognitionKind.scissors);
    expect(
      result.matches.any(
        (match) => match.kind == OperativeSketchRecognitionKind.scissors,
      ),
      isTrue,
    );
  });
}

List<Offset> _interpolatePolyline(
  List<Offset> vertices, {
  required int samplesPerSegment,
}) {
  final points = <Offset>[];
  for (int index = 0; index < vertices.length - 1; index++) {
    final start = vertices[index];
    final end = vertices[index + 1];
    for (int sample = 0; sample < samplesPerSegment; sample++) {
      final t = sample / samplesPerSegment;
      points.add(
        Offset.lerp(start, end, t)!,
      );
    }
  }
  points.add(vertices.last);
  return points;
}
