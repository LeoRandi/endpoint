import '../_imports.dart';

enum OperativeSketchRecognitionKind {
  none,
  scissors,
  triangle,
  square,
  circle,
}

extension OperativeSketchRecognitionKindLabel
    on OperativeSketchRecognitionKind {
  String get label {
    switch (this) {
      case OperativeSketchRecognitionKind.none:
        return 'NINGUNA';
      case OperativeSketchRecognitionKind.scissors:
        return 'TIJERAS';
      case OperativeSketchRecognitionKind.triangle:
        return 'TRIANGULO';
      case OperativeSketchRecognitionKind.square:
        return 'CUADRADO';
      case OperativeSketchRecognitionKind.circle:
        return 'CIRCULO';
    }
  }
}

extension OperativeSketchRecognitionKindRecognitionPriority
    on OperativeSketchRecognitionKind {
  int get recognitionPriority {
    switch (this) {
      case OperativeSketchRecognitionKind.none:
        return -1;
      case OperativeSketchRecognitionKind.scissors:
        return 1;
      case OperativeSketchRecognitionKind.triangle:
      case OperativeSketchRecognitionKind.square:
      case OperativeSketchRecognitionKind.circle:
        return 0;
    }
  }
}

extension OperativeSketchRecognitionKindItemBonusShape
    on OperativeSketchRecognitionKind {
  ItemBonusShape? get itemBonusShape {
    switch (this) {
      case OperativeSketchRecognitionKind.none:
        return null;
      case OperativeSketchRecognitionKind.scissors:
        return null;
      case OperativeSketchRecognitionKind.triangle:
        return ItemBonusShape.triangle;
      case OperativeSketchRecognitionKind.square:
        return ItemBonusShape.square;
      case OperativeSketchRecognitionKind.circle:
        return ItemBonusShape.circle;
    }
  }
}

class OperativeSketchRecognitionMatch {
  final OperativeSketchRecognitionKind kind;
  final int count;

  const OperativeSketchRecognitionMatch({
    required this.kind,
    required this.count,
  });

  int get priority => kind.recognitionPriority;

  String get displayLabel => '${kind.label}:$count';
}

class OperativeSketchRecognitionResult {
  final OperativeSketchRecognitionKind kind;
  final int count;
  final List<OperativeSketchRecognitionMatch> matches;

  const OperativeSketchRecognitionResult({
    required this.kind,
    required this.count,
    this.matches = const <OperativeSketchRecognitionMatch>[],
  });

  bool get hasMatch => matches.isNotEmpty;

  int get totalCount {
    return matches.fold<int>(0, (sum, match) => sum + match.count);
  }

  List<String> get displayLabels {
    return matches.map((match) => match.displayLabel).toList(growable: false);
  }
}

class OperativeSketchRecognitionHelper {
  static const int _gridResolution = 96;
  static const int _minimumRegionCellCount = 10;
  static const double _minimumContourArea = 28;
  static const double _minimumContourPerimeter = 22;
  static const double _minimumContourShortSide = 8;
  static const double _minimumRawPointSpacing = 1.8;
  static const double _minimumResampleSpacing = 4;
  static const double _maximumResampleSpacing = 9.5;
  static const double _smoothingWeight = 0.28;
  static const double _minimumClosedStrokeDistance = 10;
  static const double _closedStrokeDistanceFactor = 0.07;
  static const double _minimumEndpointSnapDistance = 12;
  static const double _maximumEndpointSnapDistance = 28;
  static const double _endpointSnapDistanceFactor = 0.065;
  static const double _minimumInteriorIntersectionT = 0.04;
  static const double _minimumClassificationScore = 0.58;
  static const double _minimumClassificationMargin = 0.08;
  static const double _duplicateOverlapThreshold = 0.42;
  static const double _duplicateAreaRatioThreshold = 0.34;
  static const double _duplicateCenterFactor = 0.35;
  static const double _looseDuplicateOverlapThreshold = 0.18;
  static const double _looseDuplicateAreaRatioThreshold = 0.16;
  static const double _looseDuplicateCenterFactor = 0.62;
  static const double _minimumCornerSharpness = 26;
  static const double _strongCornerStrength = 0.62;
  static const double _minimumEndpointFacingDot = 0.16;
  static const double _minimumEndpointAxisAlignment = 0.58;
  static const double _minimumSegmentSnapAxisAlignment = 0.66;
  static const double _minimumRegionFallbackGeometryScore = 0.74;
  static const double _minimumPointCloudVerificationScore = 0.72;
  static const double _minimumScissorsTopologyScore = 0.72;
  static const double _minimumScissorsTemplateScore = 0.64;
  static const double _minimumScissorsInkTemplateScore = 0.7;
  static const double _minimumScissorsTriangleSupportScore = 0.7;
  static const double _minimumScissorsBranchSpreadScore = 0.42;
  static const int _minimumConnectedInkCellCount = 18;
  static const int _pointCloudSampleCount = 48;
  static const List<List<Offset>> _scissorsTemplateSegments = <List<Offset>>[
    <Offset>[
      Offset(-0.58, -0.72),
      Offset(0, 0),
    ],
    <Offset>[
      Offset(0.58, -0.72),
      Offset(0, 0),
    ],
    <Offset>[
      Offset(0, 0),
      Offset(-0.56, 0.78),
    ],
    <Offset>[
      Offset(0, 0),
      Offset(0.56, 0.78),
    ],
    <Offset>[
      Offset(-0.56, 0.78),
      Offset(0.56, 0.78),
    ],
  ];
  static final List<OperativeSketchRecognitionKind> _orderedRecognitionKinds =
      List<OperativeSketchRecognitionKind>.unmodifiable(
    OperativeSketchRecognitionKind.values
        .where((kind) => kind != OperativeSketchRecognitionKind.none)
        .toList(growable: false)
      ..sort(_compareRecognitionKinds),
  );

  static const OperativeSketchRecognitionResult _emptyResult =
      OperativeSketchRecognitionResult(
    kind: OperativeSketchRecognitionKind.none,
    count: 0,
    matches: <OperativeSketchRecognitionMatch>[],
  );

  const OperativeSketchRecognitionHelper();

  OperativeSketchRecognitionResult scan({
    required Iterable<List<Offset>> strokes,
    required Size canvasSize,
  }) {
    if (canvasSize.isEmpty) return _emptyResult;

    final processed = _preprocessStrokes(
      strokes: strokes,
      canvasSize: canvasSize,
    );
    if (processed.isEmpty) return _emptyResult;

    final graphReadyStrokes = _buildGraphReadyStrokes(
      strokes: processed,
      canvasSize: canvasSize,
    );

    final symbolDetections = <_SketchRecognitionDetection>[
      ..._scanGraphSymbols(
        strokes: graphReadyStrokes,
        canvasSize: canvasSize,
      ),
      ..._scanTriangleAnchoredSymbols(
        strokes: graphReadyStrokes,
        canvasSize: canvasSize,
      ),
    ];
    final vectorDetections = _scanVectorContours(
      strokes: graphReadyStrokes,
      canvasSize: canvasSize,
    );
    final regionSupports = _scanClosedRegions(
      strokes: graphReadyStrokes
          .map((stroke) => stroke.points)
          .toList(growable: false),
      canvasSize: canvasSize,
    );
    final connectedInkSupports = _scanConnectedInkSupports(
      strokes: graphReadyStrokes
          .map((stroke) => stroke.points)
          .toList(growable: false),
      canvasSize: canvasSize,
    );
    final inkSupportedScissorsDetections = _scanConnectedInkSupportedScissors(
      connectedInkSupports,
    );
    final supportedVectorDetections = _applyClosedRegionSupport(
      detections: vectorDetections,
      regionSupports: regionSupports,
    );
    final regionFallbackDetections = _buildRegionFallbackDetections(
      regionSupports: regionSupports,
      existingDetections: supportedVectorDetections,
    );
    final mergedDetections = _mergeDetections(
      primaryDetections: [
        ...symbolDetections,
        ...inkSupportedScissorsDetections,
        ...supportedVectorDetections,
      ],
      secondaryDetections: regionFallbackDetections,
    );
    final prioritizedDetections = _suppressLowerPriorityDetections(
      mergedDetections,
    );
    return _resultFromCounts(_countDetections(prioritizedDetections));
  }

  Map<OperativeSketchRecognitionKind, int> _emptyCounts() {
    return <OperativeSketchRecognitionKind, int>{
      for (final kind in _orderedRecognitionKinds) kind: 0,
    };
  }

  OperativeSketchRecognitionResult _resultFromCounts(
    Map<OperativeSketchRecognitionKind, int> counts,
  ) {
    final matches = _orderedRecognitionKinds
        .where((kind) => (counts[kind] ?? 0) > 0)
        .map(
          (kind) => OperativeSketchRecognitionMatch(
            kind: kind,
            count: counts[kind] ?? 0,
          ),
        )
        .toList(growable: false);
    if (matches.isEmpty) return _emptyResult;

    final dominantKind = _pickDominantKind(counts);
    return OperativeSketchRecognitionResult(
      kind: dominantKind,
      count: counts[dominantKind] ?? 0,
      matches: matches,
    );
  }

  OperativeSketchRecognitionKind _pickDominantKind(
    Map<OperativeSketchRecognitionKind, int> counts,
  ) {
    var bestKind = OperativeSketchRecognitionKind.none;
    var bestCount = 0;
    for (final kind in _orderedRecognitionKinds) {
      final count = counts[kind] ?? 0;
      if (count > bestCount) {
        bestKind = kind;
        bestCount = count;
      }
    }
    return bestKind;
  }

  List<_ProcessedStroke> _preprocessStrokes({
    required Iterable<List<Offset>> strokes,
    required Size canvasSize,
  }) {
    final minCanvasSide = min(canvasSize.width, canvasSize.height).toDouble();
    final resampleSpacing = _clampDouble(
      minCanvasSide * 0.018,
      _minimumResampleSpacing,
      _maximumResampleSpacing,
    );

    final processed = <_ProcessedStroke>[];
    var nextStrokeId = 0;
    for (final rawStroke in strokes) {
      var points = _deduplicateSequentialPoints(
        rawStroke,
        minimumDistance: _minimumRawPointSpacing,
      );
      if (points.length < 2) continue;

      final rawLength = _pathLength(points, closed: false);
      if (rawLength < _minimumContourPerimeter * 0.42) continue;

      final closedHint = _isStrokeLikelyClosed(points);
      points = _resamplePolyline(points, resampleSpacing, closed: closedHint);
      points = _smoothPolyline(
        points,
        closed: closedHint,
        passes: closedHint ? 2 : 1,
      );
      points = _resamplePolyline(
        points,
        max(_minimumResampleSpacing, resampleSpacing * 0.85),
        closed: closedHint,
      );
      points = _deduplicateSequentialPoints(
        points,
        minimumDistance: max(0.9, resampleSpacing * 0.24),
      );
      if (points.length < (closedHint ? 6 : 2)) continue;

      final length = _pathLength(points, closed: false);
      final bounds = _computeBounds(points);
      final shortestSide = min(bounds.width, bounds.height).toDouble();
      if (length < _minimumContourPerimeter * 0.55 ||
          (bounds.width < 4 && bounds.height < 4) ||
          shortestSide < 2.2) {
        continue;
      }

      processed.add(
        _ProcessedStroke(
          id: nextStrokeId++,
          points: points,
          length: length,
          bounds: bounds,
          isClosed: _isStrokeLikelyClosed(points),
        ),
      );
    }

    return processed;
  }

  List<_ProcessedStroke> _buildGraphReadyStrokes({
    required List<_ProcessedStroke> strokes,
    required Size canvasSize,
  }) {
    if (strokes.isEmpty) {
      return strokes;
    }

    final mutableStrokes = strokes
        .map(
          (stroke) => _MutableStrokeGeometry(
            id: stroke.id,
            points: List<Offset>.from(stroke.points),
            isClosed: stroke.isClosed,
          ),
        )
        .toList(growable: false);
    final minCanvasSide = min(canvasSize.width, canvasSize.height).toDouble();
    final snapDistance = _clampDouble(
      minCanvasSide * (_endpointSnapDistanceFactor * 0.9),
      _minimumEndpointSnapDistance,
      _maximumEndpointSnapDistance,
    );
    final insertionsByStrokeId = <int, List<_StrokePointInsertion>>{};
    final endpointNodes = <_EndpointNode>[];
    final endpointStrokesByNodeId = <int, List<_MutableStrokeGeometry>>{};
    final endpointStartFlagsByNodeId = <int, List<bool>>{};
    var nextEndpointNodeId = 0;

    _EndpointNode resolveEndpointNode(_EndpointAttachment attachment) {
      for (final node in endpointNodes) {
        if (_canMergeEndpointIntoNode(
          node: node,
          candidate: attachment,
          snapDistance: snapDistance,
        )) {
          node.addAttachment(attachment);
          return node;
        }
      }

      final node = _EndpointNode(
        id: nextEndpointNodeId++,
        position: attachment.position,
      );
      node.addAttachment(attachment);
      endpointNodes.add(node);
      return node;
    }

    for (final stroke in mutableStrokes.where((stroke) => !stroke.isClosed)) {
      for (final isStart in const <bool>[true, false]) {
        final attachment = _buildEndpointAttachment(
          strokeId: stroke.id,
          points: stroke.points,
          isStart: isStart,
        );
        final node = resolveEndpointNode(attachment);
        endpointStrokesByNodeId
            .putIfAbsent(node.id, () => <_MutableStrokeGeometry>[])
            .add(stroke);
        endpointStartFlagsByNodeId
            .putIfAbsent(node.id, () => <bool>[])
            .add(isStart);
      }
    }

    for (final node in endpointNodes) {
      final nodeStrokes =
          endpointStrokesByNodeId[node.id] ?? const <_MutableStrokeGeometry>[];
      final startFlags = endpointStartFlagsByNodeId[node.id] ?? const <bool>[];
      if (nodeStrokes.length < 2) {
        continue;
      }
      if (nodeStrokes.map((stroke) => stroke.id).toSet().length < 2) {
        continue;
      }

      for (int index = 0; index < nodeStrokes.length; index++) {
        final stroke = nodeStrokes[index];
        final isStart = startFlags[index];
        if (isStart) {
          stroke.points[0] = node.position;
        } else {
          stroke.points[stroke.points.length - 1] = node.position;
        }
      }
    }

    for (final sourceStroke
        in mutableStrokes.where((stroke) => !stroke.isClosed)) {
      for (final isStart in const <bool>[true, false]) {
        final endpointAttachment = _buildEndpointAttachment(
          strokeId: sourceStroke.id,
          points: sourceStroke.points,
          isStart: isStart,
        );
        final endpoint = endpointAttachment.position;
        _EndpointSegmentSnap? bestSnap;

        for (final targetStroke in mutableStrokes) {
          if (targetStroke.id == sourceStroke.id ||
              targetStroke.points.length < 2) {
            continue;
          }

          for (int segmentIndex = 0;
              segmentIndex < targetStroke.points.length - 1;
              segmentIndex++) {
            final projection = _projectPointOntoSegment(
              point: endpoint,
              start: targetStroke.points[segmentIndex],
              end: targetStroke.points[segmentIndex + 1],
            );
            if (projection.distance > snapDistance) {
              continue;
            }
            if (!_isEndpointSegmentSnapCompatible(
              endpointAttachment: endpointAttachment,
              projectedPoint: projection.point,
              segmentStart: targetStroke.points[segmentIndex],
              segmentEnd: targetStroke.points[segmentIndex + 1],
            )) {
              continue;
            }

            if (bestSnap == null || projection.distance < bestSnap.distance) {
              bestSnap = _EndpointSegmentSnap(
                sourceStrokeId: sourceStroke.id,
                isSourceStart: isStart,
                targetStrokeId: targetStroke.id,
                targetSegmentIndex: segmentIndex,
                targetSegmentT: projection.t,
                point: projection.point,
                distance: projection.distance,
              );
            }
          }
        }

        if (bestSnap == null) {
          continue;
        }

        if (bestSnap.isSourceStart) {
          sourceStroke.points[0] = bestSnap.point;
        } else {
          sourceStroke.points[sourceStroke.points.length - 1] = bestSnap.point;
        }
        insertionsByStrokeId
            .putIfAbsent(
                bestSnap.targetStrokeId, () => <_StrokePointInsertion>[])
            .add(
              _StrokePointInsertion(
                segmentIndex: bestSnap.targetSegmentIndex,
                t: bestSnap.targetSegmentT,
                point: bestSnap.point,
              ),
            );
      }
    }

    for (int firstStrokeIndex = 0;
        firstStrokeIndex < mutableStrokes.length;
        firstStrokeIndex++) {
      final firstStroke = mutableStrokes[firstStrokeIndex];
      for (int secondStrokeIndex = firstStrokeIndex + 1;
          secondStrokeIndex < mutableStrokes.length;
          secondStrokeIndex++) {
        final secondStroke = mutableStrokes[secondStrokeIndex];
        for (int firstSegmentIndex = 0;
            firstSegmentIndex < firstStroke.points.length - 1;
            firstSegmentIndex++) {
          final firstStart = firstStroke.points[firstSegmentIndex];
          final firstEnd = firstStroke.points[firstSegmentIndex + 1];
          for (int secondSegmentIndex = 0;
              secondSegmentIndex < secondStroke.points.length - 1;
              secondSegmentIndex++) {
            final secondStart = secondStroke.points[secondSegmentIndex];
            final secondEnd = secondStroke.points[secondSegmentIndex + 1];
            final intersection = _segmentIntersectionPoint(
              firstStart,
              firstEnd,
              secondStart,
              secondEnd,
            );
            if (intersection == null) {
              continue;
            }

            insertionsByStrokeId
                .putIfAbsent(firstStroke.id, () => <_StrokePointInsertion>[])
                .add(
                  _StrokePointInsertion(
                    segmentIndex: firstSegmentIndex,
                    t: intersection.firstT,
                    point: intersection.point,
                  ),
                );
            insertionsByStrokeId
                .putIfAbsent(secondStroke.id, () => <_StrokePointInsertion>[])
                .add(
                  _StrokePointInsertion(
                    segmentIndex: secondSegmentIndex,
                    t: intersection.secondT,
                    point: intersection.point,
                  ),
                );
          }
        }
      }
    }

    for (final stroke in mutableStrokes.where((stroke) => !stroke.isClosed)) {
      for (int firstSegmentIndex = 0;
          firstSegmentIndex < stroke.points.length - 1;
          firstSegmentIndex++) {
        final firstStart = stroke.points[firstSegmentIndex];
        final firstEnd = stroke.points[firstSegmentIndex + 1];
        for (int secondSegmentIndex = firstSegmentIndex + 2;
            secondSegmentIndex < stroke.points.length - 1;
            secondSegmentIndex++) {
          final secondStart = stroke.points[secondSegmentIndex];
          final secondEnd = stroke.points[secondSegmentIndex + 1];
          final intersection = _segmentIntersectionPoint(
            firstStart,
            firstEnd,
            secondStart,
            secondEnd,
          );
          if (intersection == null ||
              !_isInteriorIntersectionT(intersection.firstT) ||
              !_isInteriorIntersectionT(intersection.secondT)) {
            continue;
          }

          insertionsByStrokeId
              .putIfAbsent(stroke.id, () => <_StrokePointInsertion>[])
              .add(
                _StrokePointInsertion(
                  segmentIndex: firstSegmentIndex,
                  t: intersection.firstT,
                  point: intersection.point,
                ),
              );
          insertionsByStrokeId[stroke.id]!.add(
            _StrokePointInsertion(
              segmentIndex: secondSegmentIndex,
              t: intersection.secondT,
              point: intersection.point,
            ),
          );
        }
      }
    }

    final graphReadyStrokes = <_ProcessedStroke>[];
    var nextGeneratedStrokeId = 100000;
    for (final stroke in mutableStrokes) {
      final augmentation = _augmentStrokePoints(
        points: stroke.points,
        insertions:
            insertionsByStrokeId[stroke.id] ?? const <_StrokePointInsertion>[],
      );
      final rawAugmentedPoints = augmentation.points;
      if (rawAugmentedPoints.length < 2) {
        continue;
      }

      if (stroke.isClosed) {
        final augmentedPoints = _deduplicateSequentialPoints(
          rawAugmentedPoints,
          minimumDistance: 0.7,
        );
        graphReadyStrokes.add(
          _ProcessedStroke(
            id: stroke.id,
            points: augmentedPoints,
            length: _pathLength(augmentedPoints, closed: false),
            bounds: _computeBounds(augmentedPoints),
            isClosed: _isStrokeLikelyClosed(augmentedPoints),
          ),
        );
        continue;
      }

      final splitIndices = <int>{
        ...augmentation.splitIndices,
        ..._collectRevisitedPointSplitIndices(
          rawAugmentedPoints,
          proximityThreshold: max(4.0, snapDistance * 0.32),
          minimumIndexGap: 6,
        ),
      }.toList()
        ..sort();
      if (splitIndices.length < 2) {
        continue;
      }

      for (int index = 0; index < splitIndices.length - 1; index++) {
        final startIndex = splitIndices[index];
        final endIndex = splitIndices[index + 1];
        if (endIndex <= startIndex) {
          continue;
        }

        final segmentPoints = _deduplicateSequentialPoints(
          rawAugmentedPoints.sublist(startIndex, endIndex + 1),
          minimumDistance: 0.7,
        );
        if (segmentPoints.length < 2) {
          continue;
        }

        graphReadyStrokes.add(
          _ProcessedStroke(
            id: nextGeneratedStrokeId++,
            points: segmentPoints,
            length: _pathLength(segmentPoints, closed: false),
            bounds: _computeBounds(segmentPoints),
            isClosed: _isStrokeLikelyClosed(segmentPoints),
          ),
        );
      }
    }

    return graphReadyStrokes.isEmpty ? strokes : graphReadyStrokes;
  }

  _AugmentedStrokeGeometry _augmentStrokePoints({
    required List<Offset> points,
    required List<_StrokePointInsertion> insertions,
  }) {
    if (points.length < 2) {
      return const _AugmentedStrokeGeometry(
        points: <Offset>[],
        splitIndices: <int>{},
      );
    }

    final insertionsBySegment = <int, List<_StrokePointInsertion>>{};
    for (final insertion in insertions) {
      insertionsBySegment
          .putIfAbsent(insertion.segmentIndex, () => <_StrokePointInsertion>[])
          .add(insertion);
    }

    final augmentedPoints = <Offset>[points.first];
    final splitIndices = <int>{0};
    for (int segmentIndex = 0;
        segmentIndex < points.length - 1;
        segmentIndex++) {
      final segmentInsertions = List<_StrokePointInsertion>.from(
        insertionsBySegment[segmentIndex] ?? const <_StrokePointInsertion>[],
      )..sort((left, right) => left.t.compareTo(right.t));

      for (final insertion in segmentInsertions) {
        if ((insertion.point - augmentedPoints.last).distance > 0.6) {
          augmentedPoints.add(insertion.point);
        }
        splitIndices.add(augmentedPoints.length - 1);
      }

      final nextPoint = points[segmentIndex + 1];
      if ((nextPoint - augmentedPoints.last).distance > 0.6) {
        augmentedPoints.add(nextPoint);
      }
      if (segmentIndex + 1 == points.length - 1) {
        splitIndices.add(augmentedPoints.length - 1);
      }
    }

    return _AugmentedStrokeGeometry(
      points: augmentedPoints,
      splitIndices: splitIndices,
    );
  }

  Set<int> _collectRevisitedPointSplitIndices(
    List<Offset> points, {
    required double proximityThreshold,
    required int minimumIndexGap,
  }) {
    if (points.length < 4) {
      return const <int>{};
    }

    final splitIndices = <int>{};
    for (int firstIndex = 1; firstIndex < points.length - 1; firstIndex++) {
      for (int secondIndex = firstIndex + minimumIndexGap;
          secondIndex < points.length - 1;
          secondIndex++) {
        if ((points[firstIndex] - points[secondIndex]).distance >
            proximityThreshold) {
          continue;
        }

        final firstDirection = _localStrokeDirection(points, firstIndex);
        final secondDirection = _localStrokeDirection(points, secondIndex);
        final normalizedFirst = _normalizeVector(firstDirection);
        final normalizedSecond = _normalizeVector(secondDirection);
        if (normalizedFirst == Offset.zero || normalizedSecond == Offset.zero) {
          continue;
        }

        final alignment = _dotProduct(normalizedFirst, normalizedSecond).abs();
        if (alignment > 0.9 &&
            (points[firstIndex] - points[secondIndex]).distance >
                proximityThreshold * 0.4) {
          continue;
        }

        splitIndices.add(firstIndex);
        splitIndices.add(secondIndex);
      }
    }

    return splitIndices;
  }

  Offset _localStrokeDirection(List<Offset> points, int index) {
    final previousIndex = max(0, index - 1);
    final nextIndex = min(points.length - 1, index + 1);
    if (previousIndex == nextIndex) {
      return Offset.zero;
    }
    return points[nextIndex] - points[previousIndex];
  }

  _SegmentProjection _projectPointOntoSegment({
    required Offset point,
    required Offset start,
    required Offset end,
  }) {
    final segment = end - start;
    final segmentLengthSquared =
        (segment.dx * segment.dx) + (segment.dy * segment.dy);
    if (segmentLengthSquared <= 0.000001) {
      return _SegmentProjection(
        point: start,
        t: 0.0,
        distance: (point - start).distance,
      );
    }

    final rawT = (((point.dx - start.dx) * segment.dx) +
            ((point.dy - start.dy) * segment.dy)) /
        segmentLengthSquared;
    final t = rawT.clamp(0.0, 1.0).toDouble();
    final projectedPoint = Offset(
      start.dx + (segment.dx * t),
      start.dy + (segment.dy * t),
    );
    return _SegmentProjection(
      point: projectedPoint,
      t: t,
      distance: (point - projectedPoint).distance,
    );
  }

  _SegmentIntersection? _segmentIntersectionPoint(
    Offset firstStart,
    Offset firstEnd,
    Offset secondStart,
    Offset secondEnd,
  ) {
    final firstDirection = firstEnd - firstStart;
    final secondDirection = secondEnd - secondStart;
    final denominator = (firstDirection.dx * secondDirection.dy) -
        (firstDirection.dy * secondDirection.dx);
    if (denominator.abs() <= 0.00001) {
      return null;
    }

    final betweenStarts = secondStart - firstStart;
    final firstT = ((betweenStarts.dx * secondDirection.dy) -
            (betweenStarts.dy * secondDirection.dx)) /
        denominator;
    final secondT = ((betweenStarts.dx * firstDirection.dy) -
            (betweenStarts.dy * firstDirection.dx)) /
        denominator;
    if (firstT < -0.001 ||
        firstT > 1.001 ||
        secondT < -0.001 ||
        secondT > 1.001) {
      return null;
    }

    final point = Offset(
      firstStart.dx + (firstDirection.dx * firstT),
      firstStart.dy + (firstDirection.dy * firstT),
    );
    return _SegmentIntersection(
      point: point,
      firstT: firstT.clamp(0.0, 1.0).toDouble(),
      secondT: secondT.clamp(0.0, 1.0).toDouble(),
    );
  }

  bool _isInteriorIntersectionT(double t) {
    return t >= _minimumInteriorIntersectionT &&
        t <= 1 - _minimumInteriorIntersectionT;
  }

  List<_SketchRecognitionDetection> _scanGraphSymbols({
    required List<_ProcessedStroke> strokes,
    required Size canvasSize,
  }) {
    final graph = _buildEndpointGraph(
      strokes: strokes,
      canvasSize: canvasSize,
    );
    if (graph.edges.length < 5 || graph.components.isEmpty) {
      return const <_SketchRecognitionDetection>[];
    }

    final detections = <_SketchRecognitionDetection>[];
    for (final componentNodeIds in graph.components) {
      final componentEdges = graph.edges
          .where(
            (edge) =>
                componentNodeIds.contains(edge.startNodeId) &&
                componentNodeIds.contains(edge.endNodeId),
          )
          .toList(growable: false);
      final detection = _buildScissorsDetection(
        componentNodeIds: componentNodeIds,
        componentEdges: componentEdges,
        nodesById: graph.nodesById,
      );
      if (detection != null) {
        detections.add(detection);
      }
    }

    return detections;
  }

  List<_SketchRecognitionDetection> _scanTriangleAnchoredSymbols({
    required List<_ProcessedStroke> strokes,
    required Size canvasSize,
  }) {
    final closedStrokes = strokes.where((stroke) => stroke.isClosed).toList();
    final openStrokes = strokes.where((stroke) => !stroke.isClosed).toList();
    if (closedStrokes.isEmpty || openStrokes.length < 2) {
      return const <_SketchRecognitionDetection>[];
    }

    final minCanvasSide = min(canvasSize.width, canvasSize.height).toDouble();
    final anchorDistanceThreshold = _clampDouble(
      minCanvasSide * (_endpointSnapDistanceFactor * 0.95),
      _minimumEndpointSnapDistance,
      _maximumEndpointSnapDistance,
    );
    final detections = <_SketchRecognitionDetection>[];

    for (final closedStroke in closedStrokes) {
      final triangleSupport = _buildContourDetection(
        contour: closedStroke.points,
        source: _SketchRecognitionSource.stroke,
      );
      if (triangleSupport == null ||
          triangleSupport.kind != OperativeSketchRecognitionKind.triangle ||
          triangleSupport.score < _minimumScissorsTriangleSupportScore) {
        continue;
      }

      final triangleVertices = _estimateTriangleVertices(closedStroke.points);
      if (triangleVertices == null) {
        continue;
      }

      final anchoredEndpoints = <_AnchoredStrokeEndpoint>[];
      for (final openStroke in openStrokes) {
        final startAnchor = _buildAnchoredStrokeEndpoint(
          stroke: openStroke,
          anchorDistanceThreshold: anchorDistanceThreshold,
          contour: closedStroke.points,
          isStart: true,
        );
        if (startAnchor != null) {
          anchoredEndpoints.add(startAnchor);
        }

        final endAnchor = _buildAnchoredStrokeEndpoint(
          stroke: openStroke,
          anchorDistanceThreshold: anchorDistanceThreshold,
          contour: closedStroke.points,
          isStart: false,
        );
        if (endAnchor != null) {
          anchoredEndpoints.add(endAnchor);
        }
      }
      if (anchoredEndpoints.length < 2) {
        continue;
      }

      for (final cluster in _clusterAnchoredEndpoints(
        anchoredEndpoints,
        clusterDistanceThreshold: anchorDistanceThreshold * 0.72,
      )) {
        final detection = _buildTriangleAnchoredScissorsDetection(
          triangleStroke: closedStroke,
          triangleSupport: triangleSupport,
          triangleVertices: triangleVertices,
          cluster: cluster,
          anchorDistanceThreshold: anchorDistanceThreshold,
        );
        if (detection != null) {
          detections.add(detection);
        }
      }
    }

    return detections;
  }

  _AnchoredStrokeEndpoint? _buildAnchoredStrokeEndpoint({
    required _ProcessedStroke stroke,
    required double anchorDistanceThreshold,
    required List<Offset> contour,
    required bool isStart,
  }) {
    if (stroke.points.length < 2) {
      return null;
    }

    final endpoint = isStart ? stroke.points.first : stroke.points.last;
    final projection = _projectPointOntoContour(
      point: endpoint,
      contour: contour,
    );
    if (projection == null || projection.distance > anchorDistanceThreshold) {
      return null;
    }

    final direction = isStart
        ? stroke.points[1] - stroke.points.first
        : stroke.points[stroke.points.length - 2] - stroke.points.last;
    if (_normalizeVector(direction) == Offset.zero) {
      return null;
    }

    return _AnchoredStrokeEndpoint(
      strokeId: stroke.id,
      anchorPoint: projection.point,
      outwardDirection: direction,
      length: stroke.length,
      points: List<Offset>.unmodifiable(stroke.points),
    );
  }

  _SegmentProjection? _projectPointOntoContour({
    required Offset point,
    required List<Offset> contour,
  }) {
    if (contour.length < 2) {
      return null;
    }

    _SegmentProjection? bestProjection;
    for (int segmentIndex = 0; segmentIndex < contour.length; segmentIndex++) {
      final start = contour[segmentIndex];
      final end = contour[(segmentIndex + 1) % contour.length];
      final projection = _projectPointOntoSegment(
        point: point,
        start: start,
        end: end,
      );
      if (bestProjection == null ||
          projection.distance < bestProjection.distance) {
        bestProjection = projection;
      }
    }

    return bestProjection;
  }

  List<List<_AnchoredStrokeEndpoint>> _clusterAnchoredEndpoints(
    List<_AnchoredStrokeEndpoint> endpoints, {
    required double clusterDistanceThreshold,
  }) {
    final clusters = <List<_AnchoredStrokeEndpoint>>[];
    for (final endpoint in endpoints) {
      var assigned = false;
      for (final cluster in clusters) {
        final averageAnchor = _averageAnchorPoint(cluster);
        if ((averageAnchor - endpoint.anchorPoint).distance >
            clusterDistanceThreshold) {
          continue;
        }
        cluster.add(endpoint);
        assigned = true;
        break;
      }

      if (!assigned) {
        clusters.add(<_AnchoredStrokeEndpoint>[endpoint]);
      }
    }

    return clusters;
  }

  Offset _averageAnchorPoint(List<_AnchoredStrokeEndpoint> endpoints) {
    if (endpoints.isEmpty) {
      return Offset.zero;
    }

    var sumX = 0.0;
    var sumY = 0.0;
    for (final endpoint in endpoints) {
      sumX += endpoint.anchorPoint.dx;
      sumY += endpoint.anchorPoint.dy;
    }
    return Offset(sumX / endpoints.length, sumY / endpoints.length);
  }

  List<Offset>? _estimateTriangleVertices(List<Offset> contour) {
    final normalizedContour = _normalizeClosedContour(
      contour,
      smoothingPasses: 1,
    );
    if (normalizedContour.length < 3) {
      return null;
    }

    final profile = _buildContourProfile(normalizedContour);
    if (profile == null) {
      return null;
    }
    final candidates = _buildPolygonCandidates(profile.contour, 3);
    if (candidates.isEmpty) {
      return null;
    }

    List<Offset>? bestPolygon;
    var bestScore = 0.0;
    for (final polygon in candidates) {
      final fit = _scorePolygonFit(profile, polygon);
      final closureScore = _scoreThreeSideClosure(profile, polygon);
      final cornerCoverage = _weightedAverage(
        <double>[
          profile.triangleCornerScore,
          fit.score,
          closureScore,
        ],
        const <double>[0.45, 0.35, 0.2],
      );
      if (cornerCoverage > bestScore) {
        bestScore = cornerCoverage;
        bestPolygon = polygon;
      }
    }

    return bestScore >= 0.52 ? bestPolygon : null;
  }

  _SketchRecognitionDetection? _buildTriangleAnchoredScissorsDetection({
    required _ProcessedStroke triangleStroke,
    required _SketchRecognitionDetection triangleSupport,
    required List<Offset> triangleVertices,
    required List<_AnchoredStrokeEndpoint> cluster,
    required double anchorDistanceThreshold,
  }) {
    final distinctStrokeIds =
        cluster.map((endpoint) => endpoint.strokeId).toSet();
    if (distinctStrokeIds.length < 2) {
      return null;
    }

    final orderedCluster = List<_AnchoredStrokeEndpoint>.from(cluster)
      ..sort((left, right) => right.length.compareTo(left.length));
    final primary = orderedCluster[0];
    final secondary = orderedCluster.firstWhere(
      (endpoint) => endpoint.strokeId != primary.strokeId,
      orElse: () => primary,
    );
    if (primary.strokeId == secondary.strokeId) {
      return null;
    }

    final spreadScore = _pairSpreadScore(
      primary.outwardDirection,
      secondary.outwardDirection,
    );
    if (spreadScore < _minimumScissorsBranchSpreadScore) {
      return null;
    }

    final anchorPoint = _averageAnchorPoint(cluster);
    final nearestVertexDistance = triangleVertices
        .map((vertex) => (vertex - anchorPoint).distance)
        .reduce(min);
    if (nearestVertexDistance >
        max(
          anchorDistanceThreshold * 1.15,
          _rectDiagonal(triangleSupport.bounds) * 0.14,
        )) {
      return null;
    }

    final branchLengthBalance = min(primary.length, secondary.length) /
        max(primary.length, secondary.length);
    final minimumBranchLength = max(
      16.0,
      min(triangleSupport.bounds.width, triangleSupport.bounds.height) * 0.24,
    );
    if (primary.length < minimumBranchLength ||
        secondary.length < minimumBranchLength) {
      return null;
    }

    final pointCloud = _normalizePointCloud(
      <Offset>[
        ...triangleStroke.points,
        ...primary.points,
        ...secondary.points,
      ],
    );
    final templateScore = _scoreScissorsTemplate(pointCloud);
    final combinedBounds = _computeBounds(
      <Offset>[
        ...triangleStroke.points,
        ...primary.points,
        ...secondary.points,
      ],
    );
    final combinedScore = _clampDouble(
      _weightedAverage(
        <double>[
          triangleSupport.score,
          spreadScore,
          branchLengthBalance,
          templateScore,
        ],
        const <double>[0.34, 0.24, 0.16, 0.26],
      ),
      0.0,
      1.0,
    );
    if (templateScore < _minimumScissorsTemplateScore ||
        combinedScore < _minimumScissorsTemplateScore) {
      return null;
    }

    return _SketchRecognitionDetection(
      kind: OperativeSketchRecognitionKind.scissors,
      source: _SketchRecognitionSource.graph,
      bounds: combinedBounds,
      area: max(1.0, triangleSupport.area),
      center: combinedBounds.center,
      score: combinedScore,
    );
  }

  List<_SketchRecognitionDetection> _scanVectorContours({
    required List<_ProcessedStroke> strokes,
    required Size canvasSize,
  }) {
    final detections = <_SketchRecognitionDetection>[];

    for (final stroke in strokes) {
      if (!stroke.isClosed) continue;
      final detection = _buildContourDetection(
        contour: stroke.points,
        source: _SketchRecognitionSource.stroke,
      );
      if (detection != null) detections.add(detection);
    }

    final stitchedLoops = _buildStitchedLoops(
      strokes: strokes,
      canvasSize: canvasSize,
    );
    for (final loop in stitchedLoops) {
      final detection = _buildContourDetection(
        contour: loop.points,
        source: _SketchRecognitionSource.stitchedLoop,
      );
      if (detection != null) detections.add(detection);
    }

    return detections;
  }

  List<_LoopContour> _buildStitchedLoops({
    required List<_ProcessedStroke> strokes,
    required Size canvasSize,
  }) {
    final graph = _buildEndpointGraph(
      strokes: strokes,
      canvasSize: canvasSize,
    );
    if (graph.edges.length < 2) return const <_LoopContour>[];

    final loops = <_LoopContour>[];

    for (final componentNodeIds in graph.components) {
      final componentEdges = graph.edges
          .where(
            (edge) =>
                componentNodeIds.contains(edge.startNodeId) &&
                componentNodeIds.contains(edge.endNodeId),
          )
          .toList(growable: false);
      if (componentEdges.length < 2) continue;
      loops.addAll(
        _findLoopContoursInComponent(
          componentNodeIds: componentNodeIds,
          componentEdges: componentEdges,
          adjacency: graph.adjacency,
          nodesById: graph.nodesById,
        ),
      );
    }

    return loops;
  }

  _EndpointGraphData _buildEndpointGraph({
    required List<_ProcessedStroke> strokes,
    required Size canvasSize,
  }) {
    final openStrokes = strokes.where((stroke) => !stroke.isClosed).toList();
    if (openStrokes.length < 2) {
      return _EndpointGraphData.empty();
    }

    final minCanvasSide = min(canvasSize.width, canvasSize.height).toDouble();
    final snapDistance = _clampDouble(
      minCanvasSide * _endpointSnapDistanceFactor,
      _minimumEndpointSnapDistance,
      _maximumEndpointSnapDistance,
    );
    final endpointNodes = <_EndpointNode>[];
    var nextNodeId = 0;

    _EndpointNode resolveNode(_EndpointAttachment attachment) {
      for (final node in endpointNodes) {
        if (_canMergeEndpointIntoNode(
          node: node,
          candidate: attachment,
          snapDistance: snapDistance,
        )) {
          node.addAttachment(attachment);
          return node;
        }
      }
      final node = _EndpointNode(
        id: nextNodeId++,
        position: attachment.position,
      );
      node.addAttachment(attachment);
      endpointNodes.add(node);
      return node;
    }

    final edges = <_EndpointGraphEdge>[];
    for (final stroke in openStrokes) {
      final startNode = resolveNode(
        _buildEndpointAttachment(
          strokeId: stroke.id,
          points: stroke.points,
          isStart: true,
        ),
      );
      final endNode = resolveNode(
        _buildEndpointAttachment(
          strokeId: stroke.id,
          points: stroke.points,
          isStart: false,
        ),
      );
      if (startNode.id == endNode.id) continue;
      edges.add(
        _EndpointGraphEdge(
          id: stroke.id,
          strokeId: stroke.id,
          startNodeId: startNode.id,
          endNodeId: endNode.id,
          points: stroke.points,
        ),
      );
    }
    if (edges.length < 2) {
      return _EndpointGraphData.empty();
    }

    final adjacency = <int, List<_EndpointGraphEdge>>{};
    for (final edge in edges) {
      adjacency
          .putIfAbsent(edge.startNodeId, () => <_EndpointGraphEdge>[])
          .add(edge);
      adjacency
          .putIfAbsent(edge.endNodeId, () => <_EndpointGraphEdge>[])
          .add(edge);
    }

    return _EndpointGraphData(
      nodesById: {
        for (final node in endpointNodes) node.id: node,
      },
      edges: List<_EndpointGraphEdge>.unmodifiable(edges),
      adjacency: adjacency.map(
        (nodeId, connectedEdges) => MapEntry(
          nodeId,
          List<_EndpointGraphEdge>.unmodifiable(connectedEdges),
        ),
      ),
      components: List<Set<int>>.unmodifiable(
        _collectGraphComponents(adjacency),
      ),
    );
  }

  List<Set<int>> _collectGraphComponents(
    Map<int, List<_EndpointGraphEdge>> adjacency,
  ) {
    final components = <Set<int>>[];
    final visitedNodeIds = <int>{};

    for (final nodeId in adjacency.keys) {
      if (visitedNodeIds.contains(nodeId)) continue;

      final component = <int>{};
      final queue = <int>[nodeId];
      var queueIndex = 0;
      visitedNodeIds.add(nodeId);

      while (queueIndex < queue.length) {
        final currentNodeId = queue[queueIndex++];
        component.add(currentNodeId);
        for (final edge
            in adjacency[currentNodeId] ?? const <_EndpointGraphEdge>[]) {
          final nextNodeId = edge.startNodeId == currentNodeId
              ? edge.endNodeId
              : edge.startNodeId;
          if (visitedNodeIds.add(nextNodeId)) queue.add(nextNodeId);
        }
      }

      components.add(component);
    }

    return components;
  }

  _SketchRecognitionDetection? _buildScissorsDetection({
    required Set<int> componentNodeIds,
    required List<_EndpointGraphEdge> componentEdges,
    required Map<int, _EndpointNode> nodesById,
  }) {
    if (componentNodeIds.length != 5 || componentEdges.length != 5) {
      return null;
    }

    final adjacency = <int, List<_EndpointGraphEdge>>{};
    for (final edge in componentEdges) {
      adjacency.putIfAbsent(edge.startNodeId, () => <_EndpointGraphEdge>[]).add(
            edge,
          );
      adjacency.putIfAbsent(edge.endNodeId, () => <_EndpointGraphEdge>[]).add(
            edge,
          );
    }

    final hubNodes = componentNodeIds.where(
      (nodeId) => (adjacency[nodeId]?.length ?? 0) == 4,
    );
    final leafNodes = componentNodeIds.where(
      (nodeId) => (adjacency[nodeId]?.length ?? 0) == 1,
    );
    final cycleNodes = componentNodeIds.where(
      (nodeId) => (adjacency[nodeId]?.length ?? 0) == 2,
    );
    if (hubNodes.length != 1 ||
        leafNodes.length != 2 ||
        cycleNodes.length != 2) {
      return null;
    }

    final hubNodeId = hubNodes.first;
    final leafNodeIds = leafNodes.toList(growable: false);
    final cycleNodeIds = cycleNodes.toList(growable: false);
    if (!_isNodeConnectedToAll(
          sourceNodeId: hubNodeId,
          targetNodeIds: leafNodeIds,
          edges: componentEdges,
        ) ||
        !_isNodeConnectedToAll(
          sourceNodeId: hubNodeId,
          targetNodeIds: cycleNodeIds,
          edges: componentEdges,
        ) ||
        _edgeConnectingNodes(
              componentEdges,
              cycleNodeIds[0],
              cycleNodeIds[1],
            ) ==
            null) {
      return null;
    }

    final leafEdges = leafNodeIds
        .map((nodeId) =>
            _edgeConnectingNodes(componentEdges, hubNodeId, nodeId)!)
        .toList(growable: false);
    final cycleEdges = cycleNodeIds
        .map((nodeId) =>
            _edgeConnectingNodes(componentEdges, hubNodeId, nodeId)!)
        .toList(growable: false);
    final baseEdge = _edgeConnectingNodes(
      componentEdges,
      cycleNodeIds[0],
      cycleNodeIds[1],
    )!;

    final topologyScore = _scoreScissorsTopology(
      hubNodeId: hubNodeId,
      leafNodeIds: leafNodeIds,
      cycleNodeIds: cycleNodeIds,
      leafEdges: leafEdges,
      cycleEdges: cycleEdges,
      baseEdge: baseEdge,
      nodesById: nodesById,
    );
    if (topologyScore < _minimumScissorsTopologyScore) {
      return null;
    }

    final pointCloud = _buildComponentPointCloud(componentEdges);
    final templateScore = _scoreScissorsTemplate(pointCloud);
    if (templateScore < _minimumScissorsTemplateScore) {
      return null;
    }

    final componentPoints =
        componentEdges.expand((edge) => edge.points).toList(growable: false);
    final bounds = _computeBounds(componentPoints);
    final cycleContour = <Offset>[
      nodesById[hubNodeId]!.position,
      nodesById[cycleNodeIds[0]]!.position,
      nodesById[cycleNodeIds[1]]!.position,
    ];
    final cycleArea = _polygonArea(cycleContour).abs();
    final finalScore = _clampDouble(
      _weightedAverage(
        <double>[
          topologyScore,
          templateScore,
        ],
        const <double>[0.6, 0.4],
      ),
      0.0,
      1.0,
    );

    return _SketchRecognitionDetection(
      kind: OperativeSketchRecognitionKind.scissors,
      source: _SketchRecognitionSource.graph,
      bounds: bounds,
      area: max(1.0, cycleArea),
      center: bounds.center,
      score: finalScore,
    );
  }

  bool _isNodeConnectedToAll({
    required int sourceNodeId,
    required List<int> targetNodeIds,
    required List<_EndpointGraphEdge> edges,
  }) {
    return targetNodeIds.every((targetNodeId) {
      return _edgeConnectingNodes(edges, sourceNodeId, targetNodeId) != null;
    });
  }

  _EndpointGraphEdge? _edgeConnectingNodes(
    List<_EndpointGraphEdge> edges,
    int firstNodeId,
    int secondNodeId,
  ) {
    for (final edge in edges) {
      final matchesForward =
          edge.startNodeId == firstNodeId && edge.endNodeId == secondNodeId;
      final matchesReverse =
          edge.startNodeId == secondNodeId && edge.endNodeId == firstNodeId;
      if (matchesForward || matchesReverse) {
        return edge;
      }
    }
    return null;
  }

  double _scoreScissorsTopology({
    required int hubNodeId,
    required List<int> leafNodeIds,
    required List<int> cycleNodeIds,
    required List<_EndpointGraphEdge> leafEdges,
    required List<_EndpointGraphEdge> cycleEdges,
    required _EndpointGraphEdge baseEdge,
    required Map<int, _EndpointNode> nodesById,
  }) {
    final leafLengths = leafEdges
        .map((edge) => _pathLength(edge.points, closed: false))
        .toList(growable: false)
      ..sort();
    final cycleSideLengths = <double>[
      ...cycleEdges.map((edge) => _pathLength(edge.points, closed: false)),
      _pathLength(baseEdge.points, closed: false),
    ]..sort();

    final leafBalance = leafLengths.first / max(leafLengths.last, 0.0001);
    final cycleBalance =
        cycleSideLengths.first / max(cycleSideLengths.last, 0.0001);
    final averageCycleSide = cycleSideLengths.fold<double>(
          0,
          (sum, value) => sum + value,
        ) /
        cycleSideLengths.length;
    final averageLeafLength = leafLengths.fold<double>(
          0,
          (sum, value) => sum + value,
        ) /
        leafLengths.length;
    final branchScaleScore = _softScore(
      averageLeafLength / max(averageCycleSide, 0.0001),
      center: 0.9,
      tolerance: 0.8,
    );
    final leafSpread = _pairSpreadScore(
      _extractEdgeDirection(
        nodeId: hubNodeId,
        edge: leafEdges[0],
        nodesById: nodesById,
      ),
      _extractEdgeDirection(
        nodeId: hubNodeId,
        edge: leafEdges[1],
        nodesById: nodesById,
      ),
    );
    final cycleSpread = _pairSpreadScore(
      _extractEdgeDirection(
        nodeId: hubNodeId,
        edge: cycleEdges[0],
        nodesById: nodesById,
      ),
      _extractEdgeDirection(
        nodeId: hubNodeId,
        edge: cycleEdges[1],
        nodesById: nodesById,
      ),
    );
    final cycleContour = <Offset>[
      nodesById[hubNodeId]!.position,
      nodesById[cycleNodeIds[0]]!.position,
      nodesById[cycleNodeIds[1]]!.position,
    ];
    final cycleArea = _polygonArea(cycleContour).abs();
    final areaScore = _softScore(
      cycleArea,
      center: 140,
      tolerance: 180,
    );

    return _weightedAverage(
      <double>[
        1.0,
        leafBalance,
        cycleBalance,
        branchScaleScore,
        leafSpread,
        cycleSpread,
        areaScore,
      ],
      const <double>[0.18, 0.14, 0.16, 0.12, 0.16, 0.16, 0.08],
    );
  }

  Offset _extractEdgeDirection({
    required int nodeId,
    required _EndpointGraphEdge edge,
    required Map<int, _EndpointNode> nodesById,
  }) {
    final otherNodeId =
        edge.startNodeId == nodeId ? edge.endNodeId : edge.startNodeId;
    final orientedPoints = _orientEdgePoints(
      edge: edge,
      fromNodeId: nodeId,
      toNodeId: otherNodeId,
      nodesById: nodesById,
    );
    if (orientedPoints.length < 2) {
      return Offset.zero;
    }
    return orientedPoints[1] - orientedPoints[0];
  }

  double _pairSpreadScore(Offset firstDirection, Offset secondDirection) {
    final first = _normalizeVector(firstDirection);
    final second = _normalizeVector(secondDirection);
    if (first == Offset.zero || second == Offset.zero) {
      return 0.0;
    }

    final dot =
        _clampDouble(first.dx * second.dx + first.dy * second.dy, -1, 1);
    final angle = acos(dot) * (180 / pi);
    return _softScore(angle, center: 72, tolerance: 56);
  }

  List<Offset> _buildComponentPointCloud(List<_EndpointGraphEdge> edges) {
    final points = edges.expand((edge) => edge.points).toList(growable: false);
    return _normalizePointCloud(points);
  }

  double _scoreScissorsTemplate(List<Offset> cloud) {
    if (cloud.length < 10) {
      return 0.0;
    }

    final templates = _buildScissorsTemplateClouds();
    var bestDistance = double.infinity;
    for (final template in templates) {
      bestDistance = min(
        bestDistance,
        _bestRotatedPointCloudDistance(
          cloud,
          template,
          maxRotationDegrees: 360,
        ),
      );
    }

    return 1 - _clampDouble(bestDistance / 0.42, 0.0, 1.0);
  }

  List<List<Offset>> _buildScissorsTemplateClouds() {
    final template = _normalizePointCloud(
      _sampleTemplateSegments(_scissorsTemplateSegments),
    );
    if (template.isEmpty) {
      return const <List<Offset>>[];
    }

    return <List<Offset>>[
      template,
      _mirrorPointCloud(template),
    ];
  }

  List<Offset> _sampleTemplateSegments(List<List<Offset>> segments) {
    final sampled = <Offset>[];
    for (final segment in segments) {
      if (segment.length < 2) continue;
      sampled.addAll(
        List<Offset>.generate(12, (index) {
          final t = index / 11;
          return Offset.lerp(segment.first, segment.last, t)!;
        }, growable: false),
      );
    }

    return _deduplicateSequentialPoints(
      sampled,
      minimumDistance: 0.02,
    );
  }

  List<Offset> _mirrorPointCloud(List<Offset> points) {
    return points
        .map((point) => Offset(-point.dx, point.dy))
        .toList(growable: false);
  }

  List<_LoopContour> _findLoopContoursInComponent({
    required Set<int> componentNodeIds,
    required List<_EndpointGraphEdge> componentEdges,
    required Map<int, List<_EndpointGraphEdge>> adjacency,
    required Map<int, _EndpointNode> nodesById,
  }) {
    final loops = <_LoopContour>[];
    final cycleSignatures = <String>{};
    final sortedStartNodes = componentNodeIds.toList()..sort();
    final maxCycleEdges = max(3, min(componentEdges.length, 8));

    void registerCycle({
      required List<_EndpointGraphEdge> cycleEdges,
      required List<int> cycleNodeIds,
    }) {
      if (cycleEdges.length < 3 ||
          cycleNodeIds.length != cycleEdges.length + 1) {
        return;
      }

      final signatureEdges = List<_EndpointGraphEdge>.from(cycleEdges)
        ..sort((left, right) => left.id.compareTo(right.id));
      final cycleSignature =
          signatureEdges.map((edge) => edge.id.toString()).join('|');
      if (!cycleSignatures.add(cycleSignature)) {
        return;
      }

      final loop = _buildLoopContourFromPath(
        cycleEdges: cycleEdges,
        cycleNodeIds: cycleNodeIds,
        nodesById: nodesById,
      );
      if (loop != null) {
        loops.add(loop);
      }
    }

    void searchFrom({
      required int startNodeId,
      required int currentNodeId,
      required List<_EndpointGraphEdge> pathEdges,
      required List<int> pathNodeIds,
      required Set<int> usedEdgeIds,
    }) {
      if (pathEdges.length >= maxCycleEdges) {
        return;
      }

      for (final edge
          in adjacency[currentNodeId] ?? const <_EndpointGraphEdge>[]) {
        if (usedEdgeIds.contains(edge.id)) {
          continue;
        }

        final nextNodeId = edge.startNodeId == currentNodeId
            ? edge.endNodeId
            : edge.startNodeId;
        if (!componentNodeIds.contains(nextNodeId)) {
          continue;
        }

        if (nextNodeId == startNodeId && pathEdges.length >= 2) {
          registerCycle(
            cycleEdges: <_EndpointGraphEdge>[...pathEdges, edge],
            cycleNodeIds: <int>[...pathNodeIds, startNodeId],
          );
          continue;
        }

        if (pathNodeIds.contains(nextNodeId) || nextNodeId < startNodeId) {
          continue;
        }

        searchFrom(
          startNodeId: startNodeId,
          currentNodeId: nextNodeId,
          pathEdges: <_EndpointGraphEdge>[...pathEdges, edge],
          pathNodeIds: <int>[...pathNodeIds, nextNodeId],
          usedEdgeIds: <int>{...usedEdgeIds, edge.id},
        );
      }
    }

    for (final startNodeId in sortedStartNodes) {
      searchFrom(
        startNodeId: startNodeId,
        currentNodeId: startNodeId,
        pathEdges: const <_EndpointGraphEdge>[],
        pathNodeIds: <int>[startNodeId],
        usedEdgeIds: <int>{},
      );
    }

    return loops;
  }

  _LoopContour? _buildLoopContourFromPath({
    required List<_EndpointGraphEdge> cycleEdges,
    required List<int> cycleNodeIds,
    required Map<int, _EndpointNode> nodesById,
  }) {
    final orderedPoints = <Offset>[];
    final strokeIds = <int>{};

    for (int index = 0; index < cycleEdges.length; index++) {
      final edge = cycleEdges[index];
      final fromNodeId = cycleNodeIds[index];
      final toNodeId = cycleNodeIds[index + 1];
      final oriented = _orientEdgePoints(
        edge: edge,
        fromNodeId: fromNodeId,
        toNodeId: toNodeId,
        nodesById: nodesById,
      );
      if (oriented.length < 2) {
        return null;
      }
      strokeIds.add(edge.strokeId);
      _appendPolyline(orderedPoints, oriented);
    }

    final normalized = _normalizeClosedContour(
      orderedPoints,
      smoothingPasses: 0,
    );
    if (normalized.length < 3) {
      return null;
    }

    return _LoopContour(points: normalized, strokeIds: strokeIds);
  }

  List<Offset> _orientEdgePoints({
    required _EndpointGraphEdge edge,
    required int fromNodeId,
    required int toNodeId,
    required Map<int, _EndpointNode> nodesById,
  }) {
    final directedPoints = edge.startNodeId == fromNodeId
        ? edge.points
        : edge.points.reversed.toList(growable: false);
    final startNode = nodesById[fromNodeId];
    final endNode = nodesById[toNodeId];
    if (startNode == null || endNode == null || directedPoints.length < 2) {
      return const <Offset>[];
    }

    return _deduplicateSequentialPoints(
      <Offset>[
        startNode.position,
        ...directedPoints.skip(1).take(directedPoints.length - 2),
        endNode.position,
      ],
      minimumDistance: 0.7,
    );
  }

  _SketchRecognitionDetection? _buildContourDetection({
    required List<Offset> contour,
    required _SketchRecognitionSource source,
  }) {
    final profile = _buildContourProfile(contour);
    if (profile == null) return null;

    final shapeScore = _pickBestShapeScore(
      profile,
      source: source,
    );
    if (shapeScore.kind == OperativeSketchRecognitionKind.none) return null;

    return _SketchRecognitionDetection(
      kind: shapeScore.kind,
      source: source,
      bounds: profile.bounds,
      area: profile.area,
      center: profile.centroid,
      score: shapeScore.score,
    );
  }

  List<_ShapeScore> _rankShapeScores(_ContourProfile profile) {
    return <_ShapeScore>[
      _scoreTriangle(profile),
      _scoreSquare(profile),
      _scoreCircle(profile),
    ]..sort((left, right) => right.score.compareTo(left.score));
  }

  _ShapeScore _pickBestShapeScore(
    _ContourProfile profile, {
    required _SketchRecognitionSource source,
  }) {
    final scores = _rankShapeScores(profile);
    final best = scores.first;
    final second = scores.length > 1
        ? scores[1]
        : const _ShapeScore(
            kind: OperativeSketchRecognitionKind.none,
            score: 0.0,
          );
    final geometryAccepted = _isGeometryClassificationAccepted(
      best: best,
      second: second,
    );
    final usePointCloudVerifier = _shouldUsePointCloudVerifier(
      source: source,
      scores: scores,
      best: best,
      second: second,
    );
    if (usePointCloudVerifier) {
      final verified = _verifyAmbiguousShapeWithPointCloud(
        profile: profile,
        geometryScores: scores,
      );
      if (verified.kind != OperativeSketchRecognitionKind.none) {
        return verified;
      }
    }

    if (!geometryAccepted) {
      return const _ShapeScore(
        kind: OperativeSketchRecognitionKind.none,
        score: 0.0,
      );
    }
    if (source == _SketchRecognitionSource.region &&
        best.score < _minimumRegionFallbackGeometryScore) {
      return const _ShapeScore(
        kind: OperativeSketchRecognitionKind.none,
        score: 0.0,
      );
    }

    return best;
  }

  bool _isGeometryClassificationAccepted({
    required _ShapeScore best,
    required _ShapeScore second,
  }) {
    return best.score >= _minimumClassificationScore &&
        best.score - second.score >= _minimumClassificationMargin;
  }

  bool _shouldUsePointCloudVerifier({
    required _SketchRecognitionSource source,
    required List<_ShapeScore> scores,
    required _ShapeScore best,
    required _ShapeScore second,
  }) {
    if (best.score < 0.44) {
      return false;
    }

    final margin = best.score - second.score;
    final circleScore = scores
        .firstWhere(
          (score) => score.kind == OperativeSketchRecognitionKind.circle,
          orElse: () => const _ShapeScore(
            kind: OperativeSketchRecognitionKind.circle,
            score: 0.0,
          ),
        )
        .score;
    final lowConfidence = best.score < (_minimumClassificationScore + 0.08);
    final narrowMargin = margin < (_minimumClassificationMargin + 0.08);
    final circleIsCompetitive = circleScore >= max(0.42, best.score - 0.16);
    final regionNeedsVerification = source == _SketchRecognitionSource.region &&
        best.score < _minimumRegionFallbackGeometryScore;

    if (source == _SketchRecognitionSource.stitchedLoop ||
        source == _SketchRecognitionSource.region) {
      return lowConfidence ||
          narrowMargin ||
          regionNeedsVerification ||
          circleIsCompetitive;
    }

    return (source == _SketchRecognitionSource.stroke && circleIsCompetitive) ||
        lowConfidence ||
        narrowMargin;
  }

  _ShapeScore _scoreTriangle(_ContourProfile profile) {
    final candidates = _buildPolygonCandidates(profile.contour, 3);
    var bestScore = 0.0;
    final cornerScore = profile.triangleCornerScore;
    final roundnessPenalty = _computePolygonRoundnessPenalty(
      profile,
      cornerScore: cornerScore,
      roundnessPenaltyWeight: 0.68,
    );
    if (candidates.isEmpty) {
      return _ShapeScore(
        kind: OperativeSketchRecognitionKind.triangle,
        score: cornerScore * (0.72 - (roundnessPenalty * 0.26)),
      );
    }

    for (final polygon in candidates) {
      final fit = _scorePolygonFit(profile, polygon);
      final closureScore = _scoreThreeSideClosure(profile, polygon);
      final sideLengths = <double>[
        (polygon[0] - polygon[1]).distance,
        (polygon[1] - polygon[2]).distance,
        (polygon[2] - polygon[0]).distance,
      ]..sort();
      final angles = _polygonAngles(polygon);
      final sideBalance =
          sqrt(sideLengths.first / max(sideLengths.last, 0.0001)).toDouble();
      final angleScore = _weightedAverage(
        <double>[
          _softScore(angles.reduce(min), center: 26, tolerance: 44),
          _softScore(angles.reduce(max), center: 112, tolerance: 68),
        ],
        const <double>[0.45, 0.55],
      );
      var candidateScore = _weightedAverage(
        <double>[
          cornerScore,
          fit.score,
          closureScore,
          sideBalance,
          angleScore,
          profile.selfIntersectionScore,
        ],
        const <double>[0.38, 0.24, 0.18, 0.08, 0.08, 0.04],
      );

      // Si hay tres esquinas claras y el contorno encaja razonablemente con
      // el poligono, aceptamos triangulos algo toscos.
      if (cornerScore >= 0.62 && fit.score >= 0.46 && closureScore >= 0.62) {
        candidateScore = max(
          candidateScore,
          0.66 +
              ((cornerScore - 0.62) * 0.18) +
              ((fit.score - 0.46) * 0.14) +
              ((closureScore - 0.62) * 0.12),
        );
      }

      candidateScore *= 1 - roundnessPenalty;
      bestScore = max(bestScore, _clampDouble(candidateScore, 0.0, 1.0));
    }

    return _ShapeScore(
      kind: OperativeSketchRecognitionKind.triangle,
      score: bestScore,
    );
  }

  _ShapeScore _scoreSquare(_ContourProfile profile) {
    final candidates = _buildPolygonCandidates(profile.contour, 4);
    var bestScore = 0.0;
    final cornerScore = profile.squareCornerScore;
    final roundnessPenalty = _computePolygonRoundnessPenalty(
      profile,
      cornerScore: cornerScore,
      roundnessPenaltyWeight: 0.46,
    );
    if (candidates.isEmpty) {
      return _ShapeScore(
        kind: OperativeSketchRecognitionKind.square,
        score: cornerScore * (0.72 - (roundnessPenalty * 0.18)),
      );
    }

    for (final polygon in candidates) {
      final fit = _scorePolygonFit(profile, polygon);
      final angles = _polygonAngles(polygon);
      final sideLengths = <double>[
        (polygon[0] - polygon[1]).distance,
        (polygon[1] - polygon[2]).distance,
        (polygon[2] - polygon[3]).distance,
        (polygon[3] - polygon[0]).distance,
      ]..sort();
      final edgeDirections = <double>[
        _edgeDirection(polygon[0], polygon[1]),
        _edgeDirection(polygon[1], polygon[2]),
        _edgeDirection(polygon[2], polygon[3]),
        _edgeDirection(polygon[3], polygon[0]),
      ];
      final oppositeParallelism = max(
        _axisAngleDifference(edgeDirections[0], edgeDirections[2]),
        _axisAngleDifference(edgeDirections[1], edgeDirections[3]),
      );
      final diagonalLengths = <double>[
        (polygon[0] - polygon[2]).distance,
        (polygon[1] - polygon[3]).distance,
      ]..sort();
      final geometryScore = _weightedAverage(
        <double>[
          sideLengths.first / max(sideLengths.last, 0.0001),
          _softScore(
            angles.map((angle) => (angle - 90).abs()).reduce(max),
            center: 0,
            tolerance: 26,
          ),
          _softScore(oppositeParallelism, center: 0, tolerance: 20),
          diagonalLengths.first / max(diagonalLengths.last, 0.0001),
          min(profile.bounds.width, profile.bounds.height) /
              max(max(profile.bounds.width, profile.bounds.height), 0.0001),
        ],
        const <double>[0.24, 0.26, 0.16, 0.18, 0.16],
      );

      bestScore = max(
        bestScore,
        _weightedAverage(
              <double>[
                cornerScore,
                fit.score,
                geometryScore,
                profile.selfIntersectionScore,
              ],
              const <double>[0.38, 0.30, 0.26, 0.06],
            ) *
            (1 - roundnessPenalty),
      );
    }

    return _ShapeScore(
      kind: OperativeSketchRecognitionKind.square,
      score: bestScore,
    );
  }

  _ShapeScore _scoreCircle(_ContourProfile profile) {
    final fittedCircle = _fitCircle(profile.smoothedContour);
    if (fittedCircle == null || fittedCircle.radius <= 0) {
      return const _ShapeScore(
        kind: OperativeSketchRecognitionKind.circle,
        score: 0.0,
      );
    }

    final radiusScale = max(fittedCircle.radius, 0.0001);
    final circleArea = pi * fittedCircle.radius * fittedCircle.radius;
    final radialVarianceScore = _computeRadialVarianceScore(
      contour: profile.smoothedContour,
      center: fittedCircle.center,
      radius: fittedCircle.radius,
    );
    final strongCornerPenalty = _clampDouble(
      (profile.strongCornerCount - 2) / 2,
      0.0,
      1.0,
    );
    final cornerPenalty = max(
      max(profile.triangleCornerScore, profile.squareCornerScore),
      strongCornerPenalty * 0.85,
    );
    final roundnessEvidence = _computeRoundnessEvidence(
      profile,
      fittedCircle: fittedCircle,
      radialVarianceScore: radialVarianceScore,
    );
    final cornerAbsenceScore = 1 - _clampDouble(cornerPenalty, 0.0, 1.0);
    final baseScore = _weightedAverage(
      <double>[
        1 - _clampDouble(fittedCircle.rmsResidual / (radiusScale * 0.14), 0, 1),
        1 - _clampDouble(fittedCircle.maxResidual / (radiusScale * 0.28), 0, 1),
        fittedCircle.coverage,
        radialVarianceScore,
        cornerAbsenceScore,
        1 -
            _clampDouble(
              (profile.area - circleArea).abs() /
                  max(max(profile.area, circleArea), 1.0),
              0,
              1,
            ),
        _softScore(profile.circularity, center: 1, tolerance: 0.32),
        min(profile.bounds.width, profile.bounds.height) /
            max(max(profile.bounds.width, profile.bounds.height), 0.0001),
        profile.selfIntersectionScore,
      ],
      const <double>[0.20, 0.10, 0.12, 0.18, 0.16, 0.10, 0.08, 0.04, 0.02],
    );
    final effectiveCornerPenalty =
        cornerPenalty * (1 - (roundnessEvidence * 0.42));
    final score = max(
      baseScore * (1 - (effectiveCornerPenalty * 0.58)),
      _weightedAverage(
        <double>[
          baseScore,
          roundnessEvidence,
          cornerAbsenceScore,
        ],
        const <double>[0.56, 0.30, 0.14],
      ),
    );

    return _ShapeScore(
      kind: OperativeSketchRecognitionKind.circle,
      score: _clampDouble(score, 0.0, 1.0),
    );
  }

  double _computePolygonRoundnessPenalty(
    _ContourProfile profile, {
    required double cornerScore,
    required double roundnessPenaltyWeight,
  }) {
    final roundnessEvidence = _computeRoundnessEvidence(profile);
    final cornerConfidence = _clampDouble(
      (cornerScore - 0.52) / 0.36,
      0.0,
      1.0,
    );
    return roundnessEvidence * (1 - cornerConfidence) * roundnessPenaltyWeight;
  }

  double _computeRoundnessEvidence(
    _ContourProfile profile, {
    _FittedCircle? fittedCircle,
    double? radialVarianceScore,
  }) {
    final effectiveFittedCircle =
        fittedCircle ?? _fitCircle(profile.smoothedContour);
    final effectiveRadialVarianceScore = radialVarianceScore ??
        (effectiveFittedCircle == null
            ? 0.0
            : _computeRadialVarianceScore(
                contour: profile.smoothedContour,
                center: effectiveFittedCircle.center,
                radius: effectiveFittedCircle.radius,
              ));
    final aspectScore = min(profile.bounds.width, profile.bounds.height) /
        max(max(profile.bounds.width, profile.bounds.height), 0.0001);
    return _weightedAverage(
      <double>[
        _softScore(profile.circularity, center: 1, tolerance: 0.22),
        aspectScore,
        effectiveRadialVarianceScore,
      ],
      const <double>[0.42, 0.18, 0.40],
    );
  }

  _ShapeScore _verifyAmbiguousShapeWithPointCloud({
    required _ContourProfile profile,
    required List<_ShapeScore> geometryScores,
  }) {
    final candidateKinds = geometryScores
        .take(3)
        .map((score) => score.kind)
        .where((kind) => kind != OperativeSketchRecognitionKind.none)
        .toSet();
    final circleGeometryScore = geometryScores
        .firstWhere(
          (score) => score.kind == OperativeSketchRecognitionKind.circle,
          orElse: () => const _ShapeScore(
            kind: OperativeSketchRecognitionKind.circle,
            score: 0.0,
          ),
        )
        .score;
    if (circleGeometryScore >= max(0.42, geometryScores.first.score - 0.18)) {
      candidateKinds.add(OperativeSketchRecognitionKind.circle);
    }
    if (candidateKinds.isEmpty) {
      return const _ShapeScore(
        kind: OperativeSketchRecognitionKind.none,
        score: 0.0,
      );
    }

    final geometryByKind = <OperativeSketchRecognitionKind, double>{
      for (final score in geometryScores) score.kind: score.score,
    };
    final pointCloudScores = _scorePointCloudTemplates(profile.contour);
    final pointCloudByKind = <OperativeSketchRecognitionKind, double>{
      for (final score in pointCloudScores) score.kind: score.score,
    };
    final verifierRanking = pointCloudScores
        .where((score) => candidateKinds.contains(score.kind))
        .toList(growable: false)
      ..sort((left, right) => right.score.compareTo(left.score));
    if (verifierRanking.isEmpty ||
        verifierRanking.first.score < _minimumPointCloudVerificationScore) {
      return const _ShapeScore(
        kind: OperativeSketchRecognitionKind.none,
        score: 0.0,
      );
    }

    final combinedScores = candidateKinds.map((kind) {
      final geometryScore = geometryByKind[kind] ?? 0.0;
      final pointCloudScore = pointCloudByKind[kind] ?? 0.0;
      return _ShapeScore(
        kind: kind,
        score: _weightedAverage(
          <double>[geometryScore, pointCloudScore],
          const <double>[0.68, 0.32],
        ),
      );
    }).toList(growable: false)
      ..sort((left, right) => right.score.compareTo(left.score));
    final best = combinedScores.first;
    final second = combinedScores.length > 1
        ? combinedScores[1]
        : const _ShapeScore(
            kind: OperativeSketchRecognitionKind.none,
            score: 0.0,
          );
    final pointCloudScore = pointCloudByKind[best.kind] ?? 0.0;
    if (pointCloudScore < _minimumPointCloudVerificationScore) {
      return const _ShapeScore(
        kind: OperativeSketchRecognitionKind.none,
        score: 0.0,
      );
    }
    if (best.score < (_minimumClassificationScore - 0.02) ||
        best.score - second.score < 0.04) {
      return const _ShapeScore(
        kind: OperativeSketchRecognitionKind.none,
        score: 0.0,
      );
    }

    return _ShapeScore(
      kind: best.kind,
      score: _clampDouble(best.score + 0.04, 0.0, 1.0),
    );
  }

  List<_ShapeScore> _scorePointCloudTemplates(List<Offset> contour) {
    final cloud = _normalizePointCloud(
      _resampleClosedPathToFixedCount(
        contour,
        _pointCloudSampleCount,
      ),
    );
    if (cloud.length < 8) {
      return _orderedRecognitionKinds
          .map(
            (kind) => _ShapeScore(
              kind: kind,
              score: 0.0,
            ),
          )
          .toList(growable: false);
    }

    final scores = _orderedRecognitionKinds.map((kind) {
      final template = _buildPointCloudTemplate(
        kind,
        _pointCloudSampleCount,
      );
      final distance = _bestRotatedPointCloudDistance(
        cloud,
        template,
      );
      return _ShapeScore(
        kind: kind,
        score: 1 - _clampDouble(distance / 0.34, 0.0, 1.0),
      );
    }).toList(growable: false)
      ..sort((left, right) => right.score.compareTo(left.score));
    return scores;
  }

  List<Offset> _buildPointCloudTemplate(
    OperativeSketchRecognitionKind kind,
    int pointCount,
  ) {
    final outline = switch (kind) {
      OperativeSketchRecognitionKind.scissors => _sampleTemplateSegments(
          _scissorsTemplateSegments,
        ),
      OperativeSketchRecognitionKind.triangle => const <Offset>[
          Offset(0.0, -1.0),
          Offset(0.88, 0.58),
          Offset(-0.88, 0.58),
        ],
      OperativeSketchRecognitionKind.square => const <Offset>[
          Offset(-1.0, -1.0),
          Offset(1.0, -1.0),
          Offset(1.0, 1.0),
          Offset(-1.0, 1.0),
        ],
      OperativeSketchRecognitionKind.circle => List<Offset>.generate(
          pointCount,
          (index) {
            final angle = (2 * pi * index) / pointCount;
            return Offset(cos(angle), sin(angle));
          },
          growable: false,
        ),
      OperativeSketchRecognitionKind.none => const <Offset>[],
    };
    if (outline.length < 3) {
      return const <Offset>[];
    }

    return _normalizePointCloud(
      kind == OperativeSketchRecognitionKind.circle ||
              kind == OperativeSketchRecognitionKind.scissors
          ? outline
          : _resampleClosedPathToFixedCount(outline, pointCount),
    );
  }

  List<Offset> _resampleClosedPathToFixedCount(
    List<Offset> points,
    int pointCount,
  ) {
    if (points.length < 2 || pointCount < 3) {
      return List<Offset>.from(points);
    }

    final polyline = <Offset>[...points, points.first];
    final cumulativeDistances = <double>[0.0];
    for (int index = 1; index < polyline.length; index++) {
      cumulativeDistances.add(
        cumulativeDistances.last +
            (polyline[index] - polyline[index - 1]).distance,
      );
    }

    final totalLength = cumulativeDistances.last;
    if (totalLength <= 0.0001) {
      return List<Offset>.from(points);
    }

    return List<Offset>.generate(pointCount, (index) {
      final distance = (index / pointCount) * totalLength;
      return _pointAtDistanceOnPolyline(
        polyline: polyline,
        cumulativeDistances: cumulativeDistances,
        distance: distance,
      );
    }, growable: false);
  }

  List<Offset> _normalizePointCloud(List<Offset> points) {
    if (points.isEmpty) {
      return const <Offset>[];
    }

    final bounds = _computeBounds(points);
    final scale = max(bounds.width, bounds.height).toDouble();
    if (scale <= 0.0001) {
      return const <Offset>[];
    }

    final centroid = _averagePoint(points);
    return points
        .map(
          (point) => Offset(
            (point.dx - centroid.dx) / scale,
            (point.dy - centroid.dy) / scale,
          ),
        )
        .toList(growable: false);
  }

  double _bestRotatedPointCloudDistance(
    List<Offset> cloud,
    List<Offset> template, {
    int maxRotationDegrees = 180,
  }) {
    var bestDistance = double.infinity;
    final clampedRotation = max(15, maxRotationDegrees);
    for (int angleDegrees = 0;
        angleDegrees < clampedRotation;
        angleDegrees += 15) {
      final rotatedCloud = _rotatePointCloud(
        cloud,
        angleDegrees * (pi / 180),
      );
      bestDistance = min(
        bestDistance,
        _bidirectionalPointCloudDistance(rotatedCloud, template),
      );
    }
    return bestDistance;
  }

  List<Offset> _rotatePointCloud(List<Offset> points, double angleRadians) {
    final cosine = cos(angleRadians);
    final sine = sin(angleRadians);
    return points
        .map(
          (point) => Offset(
            (point.dx * cosine) - (point.dy * sine),
            (point.dx * sine) + (point.dy * cosine),
          ),
        )
        .toList(growable: false);
  }

  double _bidirectionalPointCloudDistance(
    List<Offset> first,
    List<Offset> second,
  ) {
    return (_nearestNeighborPointCloudDistance(first, second) +
            _nearestNeighborPointCloudDistance(second, first)) /
        2;
  }

  double _nearestNeighborPointCloudDistance(
    List<Offset> source,
    List<Offset> target,
  ) {
    if (source.isEmpty || target.isEmpty) {
      return double.infinity;
    }

    var totalDistance = 0.0;
    for (final point in source) {
      var bestDistance = double.infinity;
      for (final candidate in target) {
        bestDistance = min(bestDistance, (point - candidate).distance);
      }
      totalDistance += bestDistance;
    }

    return totalDistance / source.length;
  }

  _ContourProfile? _buildContourProfile(List<Offset> contour) {
    if (contour.length < 3) return null;

    final cornerContour = _normalizeClosedContour(
      contour,
      smoothingPasses: 0,
    );
    if (cornerContour.length < 3) return null;

    final smoothedContour = _normalizeClosedContour(
      contour,
      smoothingPasses: 2,
    );
    final effectiveSmoothedContour =
        smoothedContour.length >= 5 ? smoothedContour : cornerContour;

    final bounds = _computeBounds(cornerContour);
    final shortSide = min(bounds.width, bounds.height).toDouble();
    if (bounds.width <= 0 ||
        bounds.height <= 0 ||
        shortSide < _minimumContourShortSide) {
      return null;
    }

    final area = _polygonArea(cornerContour).abs();
    if (area < _minimumContourArea) return null;

    final perimeter = _polygonPerimeter(cornerContour);
    if (perimeter < _minimumContourPerimeter) return null;

    final cornerPeaks = _computeCornerPeaks(cornerContour);
    final triangleCornerScore = _scoreExpectedCornerCount(
      cornerPeaks: cornerPeaks,
      contourPointCount: cornerContour.length,
      expectedCornerCount: 3,
    );
    final squareCornerScore = _scoreExpectedCornerCount(
      cornerPeaks: cornerPeaks,
      contourPointCount: cornerContour.length,
      expectedCornerCount: 4,
    );
    final strongCornerCount = cornerPeaks
        .where((peak) => peak.strength >= _strongCornerStrength)
        .length;

    return _ContourProfile(
      contour: cornerContour,
      smoothedContour: effectiveSmoothedContour,
      bounds: bounds,
      area: area,
      perimeter: perimeter,
      centroid: _computePolygonCentroid(cornerContour),
      smoothnessScore: _computeSmoothnessScore(effectiveSmoothedContour),
      selfIntersectionScore: _computeSelfIntersectionScore(cornerContour),
      circularity: (4 * pi * area) / max(perimeter * perimeter, 0.0001),
      cornerPeaks: cornerPeaks,
      triangleCornerScore: triangleCornerScore,
      squareCornerScore: squareCornerScore,
      strongCornerCount: strongCornerCount,
    );
  }

  List<List<Offset>> _buildPolygonCandidates(
    List<Offset> contour,
    int targetVertexCount,
  ) {
    if (contour.length < targetVertexCount) return const <List<Offset>>[];

    final bounds = _computeBounds(contour);
    final shortestSide = min(bounds.width, bounds.height).toDouble();
    final epsilons = <double>[
      max(1.2, shortestSide * 0.035).toDouble(),
      max(1.7, shortestSide * 0.05).toDouble(),
      max(2.2, shortestSide * 0.07).toDouble(),
      max(2.8, shortestSide * 0.09).toDouble(),
      max(3.5, shortestSide * 0.115).toDouble(),
      if (targetVertexCount == 3) max(4.3, shortestSide * 0.145).toDouble(),
      if (targetVertexCount == 3) max(5.4, shortestSide * 0.18).toDouble(),
    ];

    final candidates = <List<Offset>>[];
    final signatures = <String>{};
    for (final epsilon in epsilons) {
      final simplified = _simplifyClosedPolygon(contour, epsilon);
      final corners = _deduplicatePolygonVertices(simplified);
      if (corners.length < targetVertexCount) continue;

      final reduced = corners.length == targetVertexCount
          ? corners
          : _reducePolygonVertexCount(corners, targetVertexCount);
      if (reduced.length != targetVertexCount) continue;

      final signature = _polygonSignature(reduced);
      if (signatures.add(signature)) candidates.add(reduced);
    }

    final peakCandidate = _buildCornerPeakPolygonCandidate(
      contour,
      targetVertexCount,
    );
    if (peakCandidate.length == targetVertexCount) {
      final signature = _polygonSignature(peakCandidate);
      if (signatures.add(signature)) {
        candidates.add(peakCandidate);
      }
    }

    final hullCandidate = _buildHullCornerPolygonCandidate(
      contour,
      targetVertexCount,
    );
    if (hullCandidate.length == targetVertexCount) {
      final signature = _polygonSignature(hullCandidate);
      if (signatures.add(signature)) {
        candidates.add(hullCandidate);
      }
    }

    return candidates;
  }

  List<Offset> _buildCornerPeakPolygonCandidate(
    List<Offset> contour,
    int targetVertexCount,
  ) {
    final cornerPeaks = _computeCornerPeaks(contour);
    if (cornerPeaks.length < targetVertexCount) {
      return const <Offset>[];
    }

    final strongestPeaks = List<_CornerPeak>.from(cornerPeaks)
      ..sort((left, right) => right.strength.compareTo(left.strength));
    final selectedPeaks = strongestPeaks
        .take(targetVertexCount)
        .toList(growable: false)
      ..sort((left, right) => left.index.compareTo(right.index));

    return selectedPeaks
        .map((peak) => contour[peak.index])
        .toList(growable: false);
  }

  List<Offset> _buildHullCornerPolygonCandidate(
    List<Offset> contour,
    int targetVertexCount,
  ) {
    final hull = _computeConvexHull(contour);
    if (hull.length < targetVertexCount) {
      return const <Offset>[];
    }

    final hullVertices = _deduplicatePolygonVertices(hull);
    if (hullVertices.length < targetVertexCount) {
      return const <Offset>[];
    }

    final reducedHull = hullVertices.length == targetVertexCount
        ? hullVertices
        : _reducePolygonVertexCount(hullVertices, targetVertexCount);
    if (reducedHull.length != targetVertexCount) {
      return const <Offset>[];
    }

    final snapped = _snapPolygonVerticesToCornerPeaks(
      polygon: reducedHull,
      contour: contour,
    );
    final deduplicated = _deduplicatePolygonVertices(snapped);
    return deduplicated.length == targetVertexCount
        ? deduplicated
        : reducedHull;
  }

  double _scoreThreeSideClosure(
    _ContourProfile profile,
    List<Offset> polygon,
  ) {
    final edgeLengths = <double>[
      (polygon[0] - polygon[1]).distance,
      (polygon[1] - polygon[2]).distance,
      (polygon[2] - polygon[0]).distance,
    ];
    final perimeter = edgeLengths.reduce((sum, value) => sum + value);
    if (perimeter <= 0 || profile.contour.isEmpty) return 0.0;

    final edgeCounts = List<int>.filled(3, 0);
    for (final point in profile.contour) {
      var bestEdgeIndex = 0;
      var bestDistance = double.infinity;
      for (int edgeIndex = 0; edgeIndex < 3; edgeIndex++) {
        final start = polygon[edgeIndex];
        final end = polygon[(edgeIndex + 1) % 3];
        final distance = _distanceToSegment(point, start, end);
        if (distance < bestDistance) {
          bestDistance = distance;
          bestEdgeIndex = edgeIndex;
        }
      }
      edgeCounts[bestEdgeIndex]++;
    }

    final totalAssigned = edgeCounts.reduce((sum, value) => sum + value);
    if (totalAssigned <= 0) return 0.0;

    var shareError = 0.0;
    var weakestCoverage = 1.0;
    for (int edgeIndex = 0; edgeIndex < 3; edgeIndex++) {
      final expectedShare = edgeLengths[edgeIndex] / perimeter;
      final observedShare = edgeCounts[edgeIndex] / totalAssigned;
      shareError += (observedShare - expectedShare).abs();
      final minimumExpectedShare = max(expectedShare * 0.48, 0.1);
      weakestCoverage = min(
        weakestCoverage,
        _clampDouble(observedShare / minimumExpectedShare, 0.0, 1.0),
      );
    }

    final triangleArea = _polygonArea(polygon).abs();
    final areaAgreement = 1 -
        _clampDouble(
          (profile.area - triangleArea).abs() /
              max(max(profile.area, triangleArea), 1.0),
          0.0,
          1.0,
        );
    final shareScore = 1 - _clampDouble(shareError / 0.42, 0.0, 1.0);

    return _weightedAverage(
      <double>[
        shareScore,
        weakestCoverage,
        areaAgreement,
      ],
      const <double>[0.4, 0.35, 0.25],
    );
  }

  _PolygonFitScore _scorePolygonFit(
    _ContourProfile profile,
    List<Offset> polygon,
  ) {
    final meanDistance = profile.contour
            .map((point) => _distanceToPolygon(point, polygon))
            .reduce((sum, value) => sum + value) /
        profile.contour.length;
    final normalizedDistance = meanDistance /
        max(1.5, min(profile.bounds.width, profile.bounds.height) * 0.16);
    final distanceScore = 1 - _clampDouble(normalizedDistance, 0, 1);
    final polygonArea = _polygonArea(polygon).abs();
    final areaScore = 1 -
        _clampDouble(
          (profile.area - polygonArea).abs() /
              max(max(profile.area, polygonArea), 1.0),
          0,
          1,
        );
    final polygonPerimeter = _polygonPerimeter(polygon);
    final perimeterScore = 1 -
        _clampDouble(
          (profile.perimeter - polygonPerimeter).abs() /
              max(max(profile.perimeter, polygonPerimeter), 1.0),
          0,
          1,
        );
    final angularFitScore = _scoreContourAngularFit(profile.contour, polygon);

    return _PolygonFitScore(
      polygon: polygon,
      score: _weightedAverage(
        <double>[distanceScore, areaScore, perimeterScore, angularFitScore],
        const <double>[0.42, 0.20, 0.14, 0.24],
      ),
    );
  }

  _FittedCircle? _fitCircle(List<Offset> contour) {
    if (contour.length < 5) return null;

    double sumXx = 0;
    double sumXy = 0;
    double sumYy = 0;
    double sumX = 0;
    double sumY = 0;
    double sumZ = 0;
    double sumXz = 0;
    double sumYz = 0;

    for (final point in contour) {
      final x = point.dx;
      final y = point.dy;
      final z = -((x * x) + (y * y));
      sumXx += x * x;
      sumXy += x * y;
      sumYy += y * y;
      sumX += x;
      sumY += y;
      sumZ += z;
      sumXz += x * z;
      sumYz += y * z;
    }

    final solution = _solveLinear3x3(
      <List<double>>[
        <double>[sumXx, sumXy, sumX],
        <double>[sumXy, sumYy, sumY],
        <double>[sumX, sumY, contour.length.toDouble()],
      ],
      <double>[sumXz, sumYz, sumZ],
    );
    if (solution == null) return null;

    final center = Offset(-solution[0] / 2, -solution[1] / 2);
    final radiusSquared =
        ((solution[0] * solution[0]) + (solution[1] * solution[1])) / 4 -
            solution[2];
    if (radiusSquared <= 0) return null;

    final radius = sqrt(radiusSquared).toDouble();
    var residualSum = 0.0;
    var maxResidual = 0.0;
    final angles = <double>[];
    for (final point in contour) {
      final distance = (point - center).distance;
      final residual = (distance - radius).abs();
      residualSum += residual * residual;
      maxResidual = max(maxResidual, residual);
      angles.add(atan2(point.dy - center.dy, point.dx - center.dx));
    }

    angles.sort();
    var largestGap = 0.0;
    for (int index = 0; index < angles.length; index++) {
      final next = index + 1 < angles.length
          ? angles[index + 1]
          : angles.first + (2 * pi);
      largestGap = max(largestGap, next - angles[index]);
    }

    return _FittedCircle(
      center: center,
      radius: radius,
      rmsResidual: sqrt(residualSum / contour.length).toDouble(),
      maxResidual: maxResidual,
      coverage: 1 - _clampDouble(largestGap / (2 * pi), 0, 1),
    );
  }

  List<double>? _solveLinear3x3(List<List<double>> matrix, List<double> rhs) {
    final rows = List<List<double>>.generate(
      3,
      (index) => <double>[...matrix[index], rhs[index]],
      growable: false,
    );

    for (int pivotIndex = 0; pivotIndex < 3; pivotIndex++) {
      var bestRow = pivotIndex;
      var bestValue = rows[pivotIndex][pivotIndex].abs();
      for (int candidateIndex = pivotIndex + 1;
          candidateIndex < 3;
          candidateIndex++) {
        final candidateValue = rows[candidateIndex][pivotIndex].abs();
        if (candidateValue > bestValue) {
          bestValue = candidateValue;
          bestRow = candidateIndex;
        }
      }
      if (bestValue <= 0.000001) return null;

      if (bestRow != pivotIndex) {
        final tmp = rows[pivotIndex];
        rows[pivotIndex] = rows[bestRow];
        rows[bestRow] = tmp;
      }

      final pivot = rows[pivotIndex][pivotIndex];
      for (int columnIndex = pivotIndex; columnIndex < 4; columnIndex++) {
        rows[pivotIndex][columnIndex] /= pivot;
      }

      for (int rowIndex = 0; rowIndex < 3; rowIndex++) {
        if (rowIndex == pivotIndex) continue;
        final factor = rows[rowIndex][pivotIndex];
        for (int columnIndex = pivotIndex; columnIndex < 4; columnIndex++) {
          rows[rowIndex][columnIndex] -= factor * rows[pivotIndex][columnIndex];
        }
      }
    }

    return <double>[rows[0][3], rows[1][3], rows[2][3]];
  }

  List<Offset> _normalizeClosedContour(
    List<Offset> points, {
    required int smoothingPasses,
  }) {
    if (points.length < 3) return const <Offset>[];

    var contour = List<Offset>.from(points);
    if ((contour.first - contour.last).distance <= 1.4) {
      contour.removeLast();
    }
    contour = _deduplicateSequentialPoints(contour, minimumDistance: 0.8);
    if (contour.length < 3) return const <Offset>[];

    final perimeter = _polygonPerimeter(contour);
    final spacing = _clampDouble(
      perimeter / max(18, contour.length).toDouble(),
      3.2,
      8.2,
    );
    contour = _resamplePolyline(contour, spacing, closed: true);
    if (smoothingPasses > 0) {
      contour = _smoothPolyline(
        contour,
        closed: true,
        passes: smoothingPasses,
      );
    }
    contour = _resamplePolyline(contour, spacing, closed: true);
    contour = _deduplicateSequentialPoints(contour, minimumDistance: 0.7);
    return contour.length >= 3 ? contour : const <Offset>[];
  }

  List<_CornerPeak> _computeCornerPeaks(List<Offset> contour) {
    if (contour.length < 6) return const <_CornerPeak>[];

    final window = max(1, contour.length ~/ 18);
    final minimumPeakDistance = max(window + 1, contour.length ~/ 9);
    final peaks = <_CornerPeak>[];
    for (int index = 0; index < contour.length; index++) {
      final previous =
          contour[(index - window + contour.length) % contour.length];
      final current = contour[index];
      final next = contour[(index + window) % contour.length];
      final angle = _angleAt(previous, current, next);
      final sharpness = max(0.0, 180 - angle);
      if (sharpness < _minimumCornerSharpness) {
        continue;
      }

      peaks.add(
        _CornerPeak(
          index: index,
          angle: angle,
          sharpness: sharpness,
          strength: _clampDouble(
            (sharpness - _minimumCornerSharpness) / 72,
            0.0,
            1.0,
          ),
        ),
      );
    }

    final selected = <_CornerPeak>[];
    final rankedPeaks = List<_CornerPeak>.from(peaks)
      ..sort((left, right) => right.strength.compareTo(left.strength));
    for (final candidate in rankedPeaks) {
      final isTooCloseToExisting = selected.any(
        (existing) =>
            _cyclicIndexDistance(
              candidate.index,
              existing.index,
              contour.length,
            ) <
            minimumPeakDistance,
      );
      if (isTooCloseToExisting) {
        continue;
      }

      selected.add(candidate);
      if (selected.length >= 8) {
        break;
      }
    }

    selected.sort((left, right) => left.index.compareTo(right.index));
    return List<_CornerPeak>.unmodifiable(selected);
  }

  double _scoreExpectedCornerCount({
    required List<_CornerPeak> cornerPeaks,
    required int contourPointCount,
    required int expectedCornerCount,
  }) {
    if (expectedCornerCount <= 0 || contourPointCount <= 0) return 0.0;

    final rankedPeaks = List<_CornerPeak>.from(cornerPeaks)
      ..sort((left, right) => right.strength.compareTo(left.strength));
    final selectedPeaks = rankedPeaks
        .take(min(expectedCornerCount, rankedPeaks.length))
        .toList(growable: false)
      ..sort((left, right) => left.index.compareTo(right.index));
    if (selectedPeaks.isEmpty) return 0.0;

    final strengthScore = selectedPeaks.fold<double>(
          0.0,
          (sum, peak) => sum + peak.strength,
        ) /
        expectedCornerCount;
    final presenceScore = selectedPeaks.length / expectedCornerCount;
    final spacingScore = selectedPeaks.length == expectedCornerCount
        ? _scoreCornerSpacing(
            peaks: selectedPeaks,
            contourPointCount: contourPointCount,
          )
        : 0.0;
    final nextPeakStrength = rankedPeaks.length > expectedCornerCount
        ? rankedPeaks[expectedCornerCount].strength
        : 0.0;
    final extraPeakPenalty = 1 - _clampDouble(nextPeakStrength, 0.0, 1.0);

    return _weightedAverage(
      <double>[
        strengthScore,
        presenceScore,
        spacingScore,
        extraPeakPenalty,
      ],
      const <double>[0.46, 0.22, 0.20, 0.12],
    );
  }

  double _scoreCornerSpacing({
    required List<_CornerPeak> peaks,
    required int contourPointCount,
  }) {
    if (peaks.length < 2 || contourPointCount <= 0) return 0.0;

    final expectedGap = contourPointCount / peaks.length;
    var normalizedError = 0.0;
    for (int index = 0; index < peaks.length; index++) {
      final current = peaks[index];
      final next = peaks[(index + 1) % peaks.length];
      final gap = index + 1 < peaks.length
          ? next.index - current.index
          : contourPointCount - current.index + next.index;
      normalizedError += (gap - expectedGap).abs() / max(expectedGap, 1.0);
    }

    return 1 - _clampDouble(normalizedError / peaks.length, 0.0, 1.0);
  }

  int _cyclicIndexDistance(int first, int second, int length) {
    final rawDistance = (first - second).abs();
    return min(rawDistance, length - rawDistance);
  }

  double _computeRadialVarianceScore({
    required List<Offset> contour,
    required Offset center,
    required double radius,
  }) {
    if (contour.isEmpty || radius <= 0) return 0.0;

    final distances = contour
        .map((point) => (point - center).distance)
        .toList(growable: false);
    final meanDistance =
        distances.reduce((sum, value) => sum + value) / distances.length;
    if (meanDistance <= 0) return 0.0;

    final variance = distances.fold<double>(
          0.0,
          (sum, value) => sum + pow(value - meanDistance, 2).toDouble(),
        ) /
        distances.length;
    final standardDeviation = sqrt(variance).toDouble();
    return 1 -
        _clampDouble(
          standardDeviation / max(radius * 0.18, 0.0001),
          0.0,
          1.0,
        );
  }

  double _pathLength(List<Offset> points, {required bool closed}) {
    if (points.length < 2) return 0.0;

    var length = 0.0;
    final lastIndex = closed ? points.length : points.length - 1;
    for (int index = 0; index < lastIndex; index++) {
      final current = points[index];
      final next = points[(index + 1) % points.length];
      length += (next - current).distance;
    }
    return length;
  }

  double _polygonPerimeter(List<Offset> polygon) {
    return _pathLength(polygon, closed: true);
  }

  Rect _computeBounds(List<Offset> points) {
    double minX = points.first.dx;
    double maxX = points.first.dx;
    double minY = points.first.dy;
    double maxY = points.first.dy;

    for (final point in points.skip(1)) {
      minX = min(minX, point.dx);
      maxX = max(maxX, point.dx);
      minY = min(minY, point.dy);
      maxY = max(maxY, point.dy);
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  double _polygonArea(List<Offset> polygon) {
    var area = 0.0;
    for (int index = 0; index < polygon.length; index++) {
      final current = polygon[index];
      final next = polygon[(index + 1) % polygon.length];
      area += (current.dx * next.dy) - (next.dx * current.dy);
    }
    return area / 2;
  }

  Offset _computePolygonCentroid(List<Offset> polygon) {
    var signedAreaTwice = 0.0;
    var centroidX = 0.0;
    var centroidY = 0.0;

    for (int index = 0; index < polygon.length; index++) {
      final current = polygon[index];
      final next = polygon[(index + 1) % polygon.length];
      final cross = (current.dx * next.dy) - (next.dx * current.dy);
      signedAreaTwice += cross;
      centroidX += (current.dx + next.dx) * cross;
      centroidY += (current.dy + next.dy) * cross;
    }

    if (signedAreaTwice.abs() <= 0.0001) {
      return _averagePoint(polygon);
    }

    return Offset(
      centroidX / (3 * signedAreaTwice),
      centroidY / (3 * signedAreaTwice),
    );
  }

  Offset _averagePoint(List<Offset> points) {
    if (points.isEmpty) return Offset.zero;

    var sumX = 0.0;
    var sumY = 0.0;
    for (final point in points) {
      sumX += point.dx;
      sumY += point.dy;
    }

    return Offset(sumX / points.length, sumY / points.length);
  }

  double _distanceToPolygon(Offset point, List<Offset> polygon) {
    var bestDistance = double.infinity;
    for (int index = 0; index < polygon.length; index++) {
      bestDistance = min(
        bestDistance,
        _distanceToSegment(
            point, polygon[index], polygon[(index + 1) % polygon.length]),
      );
    }
    return bestDistance;
  }

  double _distanceToSegment(Offset point, Offset start, Offset end) {
    final segment = end - start;
    final segmentLengthSquared =
        (segment.dx * segment.dx) + (segment.dy * segment.dy);
    if (segmentLengthSquared == 0) return (point - start).distance;

    final projection = (((point.dx - start.dx) * segment.dx) +
            ((point.dy - start.dy) * segment.dy)) /
        segmentLengthSquared;
    final clampedProjection = projection.clamp(0.0, 1.0).toDouble();
    final closestPoint = Offset(
      start.dx + (segment.dx * clampedProjection),
      start.dy + (segment.dy * clampedProjection),
    );
    return (point - closestPoint).distance;
  }

  List<Offset> _simplifyClosedPolygon(List<Offset> polygon, double epsilon) {
    if (polygon.length < 4) return List<Offset>.from(polygon);
    final closedPath = <Offset>[...polygon, polygon.first];
    final simplifiedPath = _simplifyWithDouglasPeucker(closedPath, epsilon);
    if (simplifiedPath.length <= 2) return List<Offset>.from(polygon);

    final simplifiedPolygon = List<Offset>.from(simplifiedPath);
    if ((simplifiedPolygon.first - simplifiedPolygon.last).distance <= 1.5) {
      simplifiedPolygon.removeLast();
    }
    return simplifiedPolygon;
  }

  List<Offset> _computeConvexHull(List<Offset> points) {
    if (points.length < 3) {
      return List<Offset>.from(points);
    }

    final sortedPoints = List<Offset>.from(points)
      ..sort((left, right) {
        final dxComparison = left.dx.compareTo(right.dx);
        if (dxComparison != 0) return dxComparison;
        return left.dy.compareTo(right.dy);
      });
    final uniquePoints = <Offset>[];
    for (final point in sortedPoints) {
      if (uniquePoints.isEmpty || (point - uniquePoints.last).distance > 0.6) {
        uniquePoints.add(point);
      }
    }
    if (uniquePoints.length < 3) {
      return uniquePoints;
    }

    final lowerHull = <Offset>[];
    for (final point in uniquePoints) {
      while (lowerHull.length >= 2 &&
          _crossProduct(
                  lowerHull[lowerHull.length - 2], lowerHull.last, point) <=
              0.0001) {
        lowerHull.removeLast();
      }
      lowerHull.add(point);
    }

    final upperHull = <Offset>[];
    for (final point in uniquePoints.reversed) {
      while (upperHull.length >= 2 &&
          _crossProduct(
                  upperHull[upperHull.length - 2], upperHull.last, point) <=
              0.0001) {
        upperHull.removeLast();
      }
      upperHull.add(point);
    }

    return <Offset>[
      ...lowerHull.take(max(0, lowerHull.length - 1)),
      ...upperHull.take(max(0, upperHull.length - 1)),
    ];
  }

  double _crossProduct(Offset origin, Offset first, Offset second) {
    final firstVector = first - origin;
    final secondVector = second - origin;
    return (firstVector.dx * secondVector.dy) -
        (firstVector.dy * secondVector.dx);
  }

  List<Offset> _simplifyWithDouglasPeucker(
      List<Offset> points, double epsilon) {
    if (points.length < 3) return List<Offset>.from(points);

    var maxDistance = 0.0;
    var splitIndex = 0;
    final startPoint = points.first;
    final endPoint = points.last;

    for (int index = 1; index < points.length - 1; index++) {
      final distance = _distanceToSegment(points[index], startPoint, endPoint);
      if (distance > maxDistance) {
        maxDistance = distance;
        splitIndex = index;
      }
    }

    if (maxDistance <= epsilon) return <Offset>[startPoint, endPoint];

    final firstHalf = _simplifyWithDouglasPeucker(
      points.sublist(0, splitIndex + 1),
      epsilon,
    );
    final secondHalf = _simplifyWithDouglasPeucker(
      points.sublist(splitIndex),
      epsilon,
    );
    return <Offset>[
      ...firstHalf.take(firstHalf.length - 1),
      ...secondHalf,
    ];
  }

  List<Offset> _deduplicatePolygonVertices(List<Offset> polygon) {
    if (polygon.isEmpty) return const <Offset>[];

    final deduplicated = <Offset>[];
    for (final point in polygon) {
      if (deduplicated.isEmpty || (point - deduplicated.last).distance >= 1.2) {
        deduplicated.add(point);
      }
    }
    if (deduplicated.length >= 2 &&
        (deduplicated.first - deduplicated.last).distance < 1.2) {
      deduplicated.removeLast();
    }

    var index = 0;
    while (index < deduplicated.length && deduplicated.length > 3) {
      final previous =
          deduplicated[(index - 1 + deduplicated.length) % deduplicated.length];
      final current = deduplicated[index];
      final next = deduplicated[(index + 1) % deduplicated.length];

      if (_distanceToSegment(current, previous, next) <= 0.75) {
        deduplicated.removeAt(index);
        continue;
      }
      index++;
    }

    return deduplicated;
  }

  List<Offset> _snapPolygonVerticesToCornerPeaks({
    required List<Offset> polygon,
    required List<Offset> contour,
  }) {
    if (polygon.isEmpty || contour.isEmpty) {
      return const <Offset>[];
    }

    final cornerPeaks = _computeCornerPeaks(contour);
    if (cornerPeaks.isEmpty) {
      return List<Offset>.from(polygon);
    }

    final bounds = _computeBounds(contour);
    final maxSnapDistance = max(
      2.4,
      min(bounds.width, bounds.height).toDouble() * 0.16,
    );
    final usedPeakIndices = <int>{};
    final snapped = <Offset>[];

    for (final vertex in polygon) {
      _CornerPeak? bestPeak;
      var bestDistance = double.infinity;
      for (final peak in cornerPeaks) {
        if (usedPeakIndices.contains(peak.index)) {
          continue;
        }

        final peakPoint = contour[peak.index];
        final distance = (vertex - peakPoint).distance;
        if (distance < bestDistance) {
          bestDistance = distance;
          bestPeak = peak;
        }
      }

      if (bestPeak != null && bestDistance <= maxSnapDistance) {
        usedPeakIndices.add(bestPeak.index);
        snapped.add(contour[bestPeak.index]);
      } else {
        snapped.add(vertex);
      }
    }

    return snapped;
  }

  List<Offset> _reducePolygonVertexCount(
    List<Offset> polygon,
    int targetVertexCount,
  ) {
    final reduced = List<Offset>.from(polygon);
    while (reduced.length > targetVertexCount && reduced.length > 3) {
      var bestIndex = -1;
      var bestCost = double.infinity;

      for (int index = 0; index < reduced.length; index++) {
        final previous = reduced[(index - 1 + reduced.length) % reduced.length];
        final current = reduced[index];
        final next = reduced[(index + 1) % reduced.length];
        final distanceCost = _distanceToSegment(current, previous, next);
        final angle = _angleAt(previous, current, next);
        final cost = distanceCost + ((180 - angle).abs() / 180);
        if (cost < bestCost) {
          bestCost = cost;
          bestIndex = index;
        }
      }

      if (bestIndex < 0) break;
      reduced.removeAt(bestIndex);
    }

    return reduced;
  }

  List<double> _polygonAngles(List<Offset> polygon) {
    return List<double>.generate(polygon.length, (index) {
      final previous = polygon[(index - 1 + polygon.length) % polygon.length];
      final current = polygon[index];
      final next = polygon[(index + 1) % polygon.length];
      return _angleAt(previous, current, next);
    });
  }

  double _angleAt(Offset previous, Offset vertex, Offset next) {
    final vectorA = previous - vertex;
    final vectorB = next - vertex;
    final magnitudeProduct = vectorA.distance * vectorB.distance;
    if (magnitudeProduct == 0) return 0.0;

    final cosine = (((vectorA.dx * vectorB.dx) + (vectorA.dy * vectorB.dy)) /
            magnitudeProduct)
        .clamp(-1.0, 1.0)
        .toDouble();
    return acos(cosine) * (180 / pi);
  }

  double _edgeDirection(Offset start, Offset end) {
    final angle = atan2(end.dy - start.dy, end.dx - start.dx) * (180 / pi);
    final normalizedAngle = angle % 180;
    return normalizedAngle < 0 ? normalizedAngle + 180 : normalizedAngle;
  }

  double _axisAngleDifference(double first, double second) {
    final rawDifference = (first - second).abs() % 180;
    return rawDifference > 90 ? 180 - rawDifference : rawDifference;
  }

  double _scoreContourAngularFit(List<Offset> contour, List<Offset> polygon) {
    if (contour.length < 3 || polygon.length < 3) {
      return 0.0;
    }

    final edgeDirections = List<double>.generate(
      polygon.length,
      (index) => _edgeDirection(
        polygon[index],
        polygon[(index + 1) % polygon.length],
      ),
      growable: false,
    );
    final tolerance = polygon.length == 3 ? 32.0 : 24.0;
    var accumulatedScore = 0.0;

    for (int index = 0; index < contour.length; index++) {
      final previous = contour[(index - 1 + contour.length) % contour.length];
      final current = contour[index];
      final next = contour[(index + 1) % contour.length];
      final tangentDirection = _edgeDirection(previous, next);

      var bestEdgeIndex = 0;
      var bestDistance = double.infinity;
      for (int edgeIndex = 0; edgeIndex < polygon.length; edgeIndex++) {
        final distance = _distanceToSegment(
          current,
          polygon[edgeIndex],
          polygon[(edgeIndex + 1) % polygon.length],
        );
        if (distance < bestDistance) {
          bestDistance = distance;
          bestEdgeIndex = edgeIndex;
        }
      }

      final angleDifference = _axisAngleDifference(
        tangentDirection,
        edgeDirections[bestEdgeIndex],
      );
      accumulatedScore += _softScore(
        angleDifference,
        center: 0,
        tolerance: tolerance,
      );
    }

    return accumulatedScore / contour.length;
  }

  double _weightedAverage(List<double> values, List<double> weights) {
    var weightedSum = 0.0;
    var totalWeight = 0.0;
    for (int index = 0; index < values.length; index++) {
      weightedSum += values[index] * weights[index];
      totalWeight += weights[index];
    }
    if (totalWeight <= 0) return 0.0;
    return weightedSum / totalWeight;
  }

  double _softScore(double value,
      {required double center, required double tolerance}) {
    if (tolerance <= 0) return value == center ? 1.0 : 0.0;
    return 1 - _clampDouble((value - center).abs() / tolerance, 0, 1);
  }

  double _computeSmoothnessScore(List<Offset> contour) {
    if (contour.length < 3) return 0.0;

    var cumulativeTurning = 0.0;
    for (int index = 0; index < contour.length; index++) {
      final previous = contour[(index - 1 + contour.length) % contour.length];
      final current = contour[index];
      final next = contour[(index + 1) % contour.length];
      final firstDirection = atan2(
        current.dy - previous.dy,
        current.dx - previous.dx,
      );
      final secondDirection = atan2(
        next.dy - current.dy,
        next.dx - current.dx,
      );
      cumulativeTurning +=
          _normalizedAngleDifference(firstDirection, secondDirection).abs();
    }

    final normalizedTurning = cumulativeTurning / (2 * pi);
    return 1 - _clampDouble((normalizedTurning - 1.08) / 2.3, 0, 1);
  }

  double _computeSelfIntersectionScore(List<Offset> contour) {
    if (contour.length < 4) return 1.0;

    var intersections = 0;
    for (int firstIndex = 0; firstIndex < contour.length; firstIndex++) {
      final firstStart = contour[firstIndex];
      final firstEnd = contour[(firstIndex + 1) % contour.length];

      for (int secondIndex = firstIndex + 1;
          secondIndex < contour.length;
          secondIndex++) {
        final areAdjacent = secondIndex == firstIndex ||
            secondIndex == firstIndex + 1 ||
            (firstIndex == 0 && secondIndex == contour.length - 1);
        if (areAdjacent) continue;

        final secondStart = contour[secondIndex];
        final secondEnd = contour[(secondIndex + 1) % contour.length];
        if (_segmentsIntersect(firstStart, firstEnd, secondStart, secondEnd)) {
          intersections++;
        }
      }
    }

    return 1 - _clampDouble(intersections / 3, 0, 1);
  }

  bool _segmentsIntersect(
    Offset firstStart,
    Offset firstEnd,
    Offset secondStart,
    Offset secondEnd,
  ) {
    final o1 = _orientation(firstStart, firstEnd, secondStart);
    final o2 = _orientation(firstStart, firstEnd, secondEnd);
    final o3 = _orientation(secondStart, secondEnd, firstStart);
    final o4 = _orientation(secondStart, secondEnd, firstEnd);

    if (o1 == 0 && _isPointOnSegment(secondStart, firstStart, firstEnd)) {
      return true;
    }
    if (o2 == 0 && _isPointOnSegment(secondEnd, firstStart, firstEnd)) {
      return true;
    }
    if (o3 == 0 && _isPointOnSegment(firstStart, secondStart, secondEnd)) {
      return true;
    }
    if (o4 == 0 && _isPointOnSegment(firstEnd, secondStart, secondEnd)) {
      return true;
    }

    return o1 != o2 && o3 != o4;
  }

  int _orientation(Offset first, Offset second, Offset third) {
    final value = ((second.dy - first.dy) * (third.dx - second.dx)) -
        ((second.dx - first.dx) * (third.dy - second.dy));
    if (value.abs() <= 0.00001) return 0;
    return value > 0 ? 1 : 2;
  }

  bool _isPointOnSegment(Offset point, Offset start, Offset end) {
    return point.dx <= max(start.dx, end.dx) + 0.00001 &&
        point.dx + 0.00001 >= min(start.dx, end.dx) &&
        point.dy <= max(start.dy, end.dy) + 0.00001 &&
        point.dy + 0.00001 >= min(start.dy, end.dy);
  }

  List<Offset> _resamplePolyline(
    List<Offset> points,
    double spacing, {
    required bool closed,
  }) {
    if (points.length < 2) return List<Offset>.from(points);

    final polyline = List<Offset>.from(points);
    if (closed) polyline.add(points.first);

    final cumulative = <double>[0];
    for (int index = 1; index < polyline.length; index++) {
      cumulative.add(
        cumulative.last + (polyline[index] - polyline[index - 1]).distance,
      );
    }

    final totalLength = cumulative.last;
    if (totalLength <= spacing) return List<Offset>.from(points);

    final sampleCount = max(
      closed ? 12 : 2,
      (totalLength / max(spacing, 0.0001)).round(),
    );
    final result = <Offset>[];
    final sampleIterations = closed ? sampleCount : sampleCount + 1;

    for (int sampleIndex = 0; sampleIndex < sampleIterations; sampleIndex++) {
      final targetDistance = closed
          ? (sampleIndex / sampleCount) * totalLength
          : (sampleIndex / max(sampleCount, 1)) * totalLength;
      result.add(
        _pointAtDistanceOnPolyline(
          polyline: polyline,
          cumulativeDistances: cumulative,
          distance: targetDistance,
        ),
      );
    }

    if (!closed && result.isNotEmpty) {
      result[0] = points.first;
      result[result.length - 1] = points.last;
    }

    return _deduplicateSequentialPoints(
      result,
      minimumDistance: max(0.7, spacing * 0.24),
    );
  }

  Offset _pointAtDistanceOnPolyline({
    required List<Offset> polyline,
    required List<double> cumulativeDistances,
    required double distance,
  }) {
    for (int index = 1; index < cumulativeDistances.length; index++) {
      final currentDistance = cumulativeDistances[index];
      if (distance > currentDistance) continue;

      final previousDistance = cumulativeDistances[index - 1];
      final segmentLength = currentDistance - previousDistance;
      if (segmentLength <= 0) return polyline[index];

      final t = ((distance - previousDistance) / segmentLength).clamp(0.0, 1.0);
      final start = polyline[index - 1];
      final end = polyline[index];
      return Offset(
        start.dx + ((end.dx - start.dx) * t),
        start.dy + ((end.dy - start.dy) * t),
      );
    }

    return polyline.last;
  }

  List<Offset> _smoothPolyline(
    List<Offset> points, {
    required bool closed,
    required int passes,
  }) {
    var current = List<Offset>.from(points);
    for (int pass = 0; pass < passes; pass++) {
      if (current.length < 3) break;

      current = List<Offset>.generate(current.length, (index) {
        if (!closed && (index == 0 || index == current.length - 1)) {
          return current[index];
        }

        final previous = current[(index - 1 + current.length) % current.length];
        final point = current[index];
        final following = current[(index + 1) % current.length];
        final neighborAverage = Offset(
          (previous.dx + point.dx + following.dx) / 3,
          (previous.dy + point.dy + following.dy) / 3,
        );
        return Offset(
          point.dx + ((neighborAverage.dx - point.dx) * _smoothingWeight),
          point.dy + ((neighborAverage.dy - point.dy) * _smoothingWeight),
        );
      }, growable: false);
    }

    return current;
  }

  List<Offset> _deduplicateSequentialPoints(
    Iterable<Offset> points, {
    required double minimumDistance,
  }) {
    final deduplicated = <Offset>[];
    for (final point in points) {
      if (deduplicated.isEmpty ||
          (point - deduplicated.last).distance >= minimumDistance) {
        deduplicated.add(point);
      }
    }
    return deduplicated;
  }

  bool _isStrokeLikelyClosed(List<Offset> points) {
    if (points.length < 4) return false;

    final bounds = _computeBounds(points);
    final shortestSide = min(bounds.width, bounds.height).toDouble();
    final closureThreshold = _clampDouble(
      shortestSide * _closedStrokeDistanceFactor,
      _minimumClosedStrokeDistance,
      26,
    );
    return (points.first - points.last).distance <= closureThreshold;
  }

  double _normalizedAngleDifference(double first, double second) {
    var difference = (second - first + pi) % (2 * pi);
    if (difference < 0) difference += 2 * pi;
    return difference - pi;
  }

  _EndpointAttachment _buildEndpointAttachment({
    required int strokeId,
    required List<Offset> points,
    required bool isStart,
  }) {
    return _EndpointAttachment(
      strokeId: strokeId,
      isStart: isStart,
      position: isStart ? points.first : points.last,
      outwardDirection: _estimateEndpointOutwardDirection(
        points,
        isStart: isStart,
      ),
    );
  }

  Offset _estimateEndpointOutwardDirection(
    List<Offset> points, {
    required bool isStart,
  }) {
    if (points.length < 2) {
      return Offset.zero;
    }

    final anchorCount = min(3, points.length - 1);
    if (isStart) {
      final anchor = _averagePoint(points.sublist(1, anchorCount + 1));
      return points.first - anchor;
    }

    final anchor = _averagePoint(
      points.sublist(points.length - 1 - anchorCount, points.length - 1),
    );
    return points.last - anchor;
  }

  bool _canMergeEndpointIntoNode({
    required _EndpointNode node,
    required _EndpointAttachment candidate,
    required double snapDistance,
  }) {
    final distance = (node.position - candidate.position).distance;
    if (distance > snapDistance) {
      return false;
    }

    if (distance <= max(1.6, snapDistance * 0.18) || node.attachments.isEmpty) {
      return true;
    }

    for (final attachment in node.attachments) {
      if (attachment.strokeId == candidate.strokeId) {
        continue;
      }
      if (_endpointsFaceEachOther(attachment, candidate) ||
          _areEndpointTangentsCoherent(
            attachment.outwardDirection,
            candidate.outwardDirection,
            minimumAlignment: _minimumEndpointAxisAlignment,
          )) {
        return true;
      }
    }

    return false;
  }

  bool _isEndpointSegmentSnapCompatible({
    required _EndpointAttachment endpointAttachment,
    required Offset projectedPoint,
    required Offset segmentStart,
    required Offset segmentEnd,
  }) {
    if (!_areEndpointTangentsCoherent(
      endpointAttachment.outwardDirection,
      segmentEnd - segmentStart,
      minimumAlignment: _minimumSegmentSnapAxisAlignment,
    )) {
      return false;
    }

    final bridge = projectedPoint - endpointAttachment.position;
    if (bridge.distance <= 1.1) {
      return true;
    }

    final outwardDirection = _normalizeVector(
      endpointAttachment.outwardDirection,
    );
    if (outwardDirection == Offset.zero) {
      return false;
    }

    return _dotProduct(
          outwardDirection,
          _normalizeVector(bridge),
        ) >=
        _minimumEndpointFacingDot;
  }

  bool _endpointsFaceEachOther(
    _EndpointAttachment first,
    _EndpointAttachment second,
  ) {
    final bridge = second.position - first.position;
    if (bridge.distance <= 0.0001) {
      return true;
    }

    final firstDirection = _normalizeVector(first.outwardDirection);
    final secondDirection = _normalizeVector(second.outwardDirection);
    if (firstDirection == Offset.zero || secondDirection == Offset.zero) {
      return false;
    }

    final bridgeDirection = _normalizeVector(bridge);
    final firstFacing = _dotProduct(firstDirection, bridgeDirection);
    final secondFacing = _dotProduct(
      secondDirection,
      Offset(-bridgeDirection.dx, -bridgeDirection.dy),
    );
    return min(firstFacing, secondFacing) >= _minimumEndpointFacingDot;
  }

  bool _areEndpointTangentsCoherent(
    Offset firstDirection,
    Offset secondDirection, {
    required double minimumAlignment,
  }) {
    final normalizedFirst = _normalizeVector(firstDirection);
    final normalizedSecond = _normalizeVector(secondDirection);
    if (normalizedFirst == Offset.zero || normalizedSecond == Offset.zero) {
      return false;
    }

    return _dotProduct(normalizedFirst, normalizedSecond).abs() >=
        minimumAlignment;
  }

  Offset _normalizeVector(Offset vector) {
    final distance = vector.distance;
    if (distance <= 0.000001) {
      return Offset.zero;
    }

    return Offset(vector.dx / distance, vector.dy / distance);
  }

  double _dotProduct(Offset first, Offset second) {
    return (first.dx * second.dx) + (first.dy * second.dy);
  }

  void _appendPolyline(List<Offset> target, List<Offset> source) {
    if (source.isEmpty) return;
    if (target.isEmpty) {
      target.addAll(source);
      return;
    }

    for (final point in source) {
      if ((point - target.last).distance <= 0.6) continue;
      target.add(point);
    }
  }

  String _polygonSignature(List<Offset> polygon) {
    return polygon
        .map((point) =>
            '${point.dx.toStringAsFixed(1)}:${point.dy.toStringAsFixed(1)}')
        .join('|');
  }

  double _rectIntersectionArea(Rect first, Rect second) {
    final overlap = first.intersect(second);
    if (overlap.width <= 0 || overlap.height <= 0) return 0.0;
    return overlap.width * overlap.height;
  }

  double _rectArea(Rect rect) => rect.width * rect.height;

  double _rectDiagonal(Rect rect) {
    return sqrt((rect.width * rect.width) + (rect.height * rect.height))
        .toDouble();
  }

  List<_SketchRecognitionDetection> _mergeDetections({
    required List<_SketchRecognitionDetection> primaryDetections,
    required List<_SketchRecognitionDetection> secondaryDetections,
  }) {
    final clusters = <List<_SketchRecognitionDetection>>[];
    final allDetections = <_SketchRecognitionDetection>[
      ...primaryDetections,
      ...secondaryDetections,
    ];
    for (final detection in allDetections) {
      final matchingClusterIndices = <int>[];
      for (int index = 0; index < clusters.length; index++) {
        final cluster = clusters[index];
        if (cluster.any(
          (existing) => _areDuplicateDetections(existing, detection),
        )) {
          matchingClusterIndices.add(index);
        }
      }

      if (matchingClusterIndices.isEmpty) {
        clusters.add(<_SketchRecognitionDetection>[detection]);
        continue;
      }

      final mergedCluster = <_SketchRecognitionDetection>[detection];
      for (final clusterIndex in matchingClusterIndices.reversed) {
        mergedCluster.addAll(clusters.removeAt(clusterIndex));
      }
      clusters.add(mergedCluster);
    }

    return clusters.map(_mergeDetectionCluster).toList(growable: false);
  }

  List<_SketchRecognitionDetection> _suppressLowerPriorityDetections(
    List<_SketchRecognitionDetection> detections,
  ) {
    final higherPriorityDetections = detections
        .where((detection) => detection.kind.recognitionPriority > 0)
        .toList(growable: false);
    if (higherPriorityDetections.isEmpty) {
      return detections;
    }

    return detections.where((candidate) {
      if (candidate.kind.recognitionPriority > 0) {
        return true;
      }

      for (final detection in higherPriorityDetections) {
        if (candidate.kind.recognitionPriority >=
            detection.kind.recognitionPriority) {
          continue;
        }

        final overlapRatio =
            _rectIntersectionArea(detection.bounds, candidate.bounds) /
                max(1.0, _rectArea(candidate.bounds));
        if (overlapRatio < 0.72) {
          continue;
        }

        final centerDistance = (detection.center - candidate.center).distance;
        if (centerDistance <=
            max(12.0, _rectDiagonal(detection.bounds) * 0.4)) {
          return false;
        }
      }

      return true;
    }).toList(growable: false);
  }

  Map<OperativeSketchRecognitionKind, int> _countDetections(
    List<_SketchRecognitionDetection> detections,
  ) {
    final counts = _emptyCounts();
    for (final detection in detections) {
      counts[detection.kind] = counts[detection.kind]! + 1;
    }
    return counts;
  }

  bool _areDuplicateDetections(
    _SketchRecognitionDetection first,
    _SketchRecognitionDetection second,
  ) {
    final allowLooseMatching =
        first.source == _SketchRecognitionSource.region ||
            first.source == _SketchRecognitionSource.inkRegion ||
            second.source == _SketchRecognitionSource.region ||
            second.source == _SketchRecognitionSource.inkRegion ||
            first.kind == second.kind;
    return _matchesShapeGeometry(
      firstBounds: first.bounds,
      firstArea: first.area,
      firstCenter: first.center,
      secondBounds: second.bounds,
      secondArea: second.area,
      secondCenter: second.center,
      allowLoose: allowLooseMatching,
    );
  }

  bool _matchesShapeGeometry({
    required Rect firstBounds,
    required double firstArea,
    required Offset firstCenter,
    required Rect secondBounds,
    required double secondArea,
    required Offset secondCenter,
    required bool allowLoose,
  }) {
    final intersectionArea = _rectIntersectionArea(
      firstBounds,
      secondBounds,
    );
    if (intersectionArea > 0) {
      final overlapRatio = intersectionArea /
          max(1.0, min(_rectArea(firstBounds), _rectArea(secondBounds)));
      if (overlapRatio >= _duplicateOverlapThreshold) {
        final areaRatio =
            min(firstArea, secondArea) / max(firstArea, secondArea);
        if (areaRatio >= _duplicateAreaRatioThreshold) {
          final centerDistance = (firstCenter - secondCenter).distance;
          final minDiagonal =
              min(_rectDiagonal(firstBounds), _rectDiagonal(secondBounds));
          if (centerDistance <=
              max(6.0, minDiagonal * _duplicateCenterFactor)) {
            return true;
          }
        }
      }
    }

    if (!allowLoose) {
      return false;
    }

    final minDiagonal =
        min(_rectDiagonal(firstBounds), _rectDiagonal(secondBounds));
    final maxDiagonal =
        max(_rectDiagonal(firstBounds), _rectDiagonal(secondBounds));
    final areaRatio = min(firstArea, secondArea) / max(firstArea, secondArea);
    if (areaRatio < _looseDuplicateAreaRatioThreshold) {
      return false;
    }

    final centerDistance = (firstCenter - secondCenter).distance;
    if (centerDistance > max(10.0, minDiagonal * _looseDuplicateCenterFactor)) {
      return false;
    }

    final diagonalRatio = minDiagonal / max(maxDiagonal, 1.0);
    if (diagonalRatio < 0.34) {
      return false;
    }

    final inflation = max(3.5, minDiagonal * 0.12);
    final expandedFirstBounds = firstBounds.inflate(inflation);
    final expandedSecondBounds = secondBounds.inflate(inflation);
    final relaxedIntersectionArea = _rectIntersectionArea(
      expandedFirstBounds,
      expandedSecondBounds,
    );
    final relaxedOverlapRatio = relaxedIntersectionArea /
        max(
          1.0,
          min(
            _rectArea(expandedFirstBounds),
            _rectArea(expandedSecondBounds),
          ),
        );
    final containsCenter = expandedFirstBounds.contains(secondCenter) ||
        expandedSecondBounds.contains(firstCenter);

    return relaxedOverlapRatio >= _looseDuplicateOverlapThreshold ||
        containsCenter;
  }

  _SketchRecognitionDetection _mergeDetectionCluster(
    List<_SketchRecognitionDetection> cluster,
  ) {
    if (cluster.length <= 1) {
      return cluster.first;
    }

    final votesByKind = <OperativeSketchRecognitionKind, double>{
      for (final kind in _orderedRecognitionKinds) kind: 0.0,
    };
    final detectionsByKind =
        <OperativeSketchRecognitionKind, List<_SketchRecognitionDetection>>{};
    for (final detection in cluster) {
      votesByKind[detection.kind] =
          (votesByKind[detection.kind] ?? 0.0) + _detectionVoteScore(detection);
      detectionsByKind
          .putIfAbsent(detection.kind, () => <_SketchRecognitionDetection>[])
          .add(detection);
    }

    final highestClusterPriority = detectionsByKind.keys.fold<int>(
      -1,
      (best, kind) => max(best, kind.recognitionPriority),
    );
    final winningKind = _pickClusterWinningKind(
      votesByKind,
      allowedKinds: detectionsByKind.keys
          .where((kind) => kind.recognitionPriority == highestClusterPriority)
          .toSet(),
    );
    final winningDetections =
        detectionsByKind[winningKind] ?? <_SketchRecognitionDetection>[];
    final representative = winningDetections.isEmpty
        ? cluster.first
        : winningDetections.reduce((best, current) {
            return _detectionVoteScore(current) > _detectionVoteScore(best)
                ? current
                : best;
          });
    final weightedCenter = _weightedDetectionCenter(winningDetections);
    final weightedArea = _weightedDetectionArea(winningDetections);
    final mergedBounds = _unionDetectionBounds(winningDetections);
    final winningVote = votesByKind[winningKind] ?? 0.0;
    final totalVote = votesByKind.values.fold<double>(0.0, (sum, vote) {
      return sum + vote;
    });
    final supportScore = totalVote <= 0 ? 1.0 : winningVote / totalVote;
    final contributorBoost = min(
      0.12,
      max(0, winningDetections.length - 1) * 0.06,
    );
    final mergedScore = _clampDouble(
      _weightedAverage(
            <double>[
              representative.score,
              supportScore,
              winningVote / max(1, winningDetections.length).toDouble(),
            ],
            const <double>[0.52, 0.24, 0.24],
          ) +
          contributorBoost,
      0.0,
      1.0,
    );

    return _SketchRecognitionDetection(
      kind: winningKind,
      source: representative.source,
      bounds: mergedBounds,
      area: weightedArea,
      center: weightedCenter,
      score: mergedScore,
    );
  }

  OperativeSketchRecognitionKind _pickClusterWinningKind(
    Map<OperativeSketchRecognitionKind, double> votesByKind, {
    Set<OperativeSketchRecognitionKind>? allowedKinds,
  }) {
    var bestKind = OperativeSketchRecognitionKind.none;
    var bestVote = 0.0;
    for (final kind in _orderedRecognitionKinds) {
      if (allowedKinds != null && !allowedKinds.contains(kind)) {
        continue;
      }
      final vote = votesByKind[kind] ?? 0.0;
      if (vote > bestVote) {
        bestKind = kind;
        bestVote = vote;
      }
    }
    return bestKind;
  }

  double _detectionVoteScore(_SketchRecognitionDetection detection) {
    final sourceBonus = switch (detection.source) {
      _SketchRecognitionSource.graph => 0.12,
      _SketchRecognitionSource.inkRegion => 0.08,
      _SketchRecognitionSource.stroke => 0.06,
      _SketchRecognitionSource.stitchedLoop => 0.09,
      _SketchRecognitionSource.region => 0.0,
    };
    return detection.score + sourceBonus;
  }

  Offset _weightedDetectionCenter(
    List<_SketchRecognitionDetection> detections,
  ) {
    if (detections.isEmpty) {
      return Offset.zero;
    }

    var sumX = 0.0;
    var sumY = 0.0;
    var totalWeight = 0.0;
    for (final detection in detections) {
      final weight = max(0.0001, _detectionVoteScore(detection));
      sumX += detection.center.dx * weight;
      sumY += detection.center.dy * weight;
      totalWeight += weight;
    }

    return Offset(sumX / totalWeight, sumY / totalWeight);
  }

  double _weightedDetectionArea(
    List<_SketchRecognitionDetection> detections,
  ) {
    if (detections.isEmpty) {
      return 0.0;
    }

    var weightedArea = 0.0;
    var totalWeight = 0.0;
    for (final detection in detections) {
      final weight = max(0.0001, _detectionVoteScore(detection));
      weightedArea += detection.area * weight;
      totalWeight += weight;
    }

    return weightedArea / totalWeight;
  }

  Rect _unionDetectionBounds(List<_SketchRecognitionDetection> detections) {
    if (detections.isEmpty) {
      return Rect.zero;
    }

    var minX = detections.first.bounds.left;
    var minY = detections.first.bounds.top;
    var maxX = detections.first.bounds.right;
    var maxY = detections.first.bounds.bottom;
    for (final detection in detections.skip(1)) {
      minX = min(minX, detection.bounds.left);
      minY = min(minY, detection.bounds.top);
      maxX = max(maxX, detection.bounds.right);
      maxY = max(maxY, detection.bounds.bottom);
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  List<_ClosedRegionSupport> _scanClosedRegions({
    required List<List<Offset>> strokes,
    required Size canvasSize,
  }) {
    final supports = <_ClosedRegionSupport>[];
    final rasterGrid = _SketchRasterGrid.fromStrokes(
      strokes: strokes,
      canvasSize: canvasSize,
      resolution: _gridResolution,
    );
    final regions = _extractClosedRegions(rasterGrid);
    for (final region in regions) {
      final regionContour = _buildOrderedRegionContour(region, rasterGrid);
      if (regionContour.length < 3) continue;

      final canvasContour = regionContour
          .map((point) => rasterGrid.vertexToCanvasPoint(point, canvasSize))
          .toList(growable: false);
      final normalizedContour = _normalizeClosedContour(
        canvasContour,
        smoothingPasses: 0,
      );
      if (normalizedContour.length < 3) {
        continue;
      }

      supports.add(
        _ClosedRegionSupport(
          contour: normalizedContour,
          bounds: _computeBounds(normalizedContour),
          area: _polygonArea(normalizedContour).abs(),
          center: _computePolygonCentroid(normalizedContour),
        ),
      );
    }

    return supports;
  }

  List<_ClosedRegionSupport> _scanConnectedInkSupports({
    required List<List<Offset>> strokes,
    required Size canvasSize,
  }) {
    final supports = <_ClosedRegionSupport>[];
    final rasterGrid = _SketchRasterGrid.fromStrokes(
      strokes: strokes,
      canvasSize: canvasSize,
      resolution: _gridResolution,
    );
    final components = _extractBlockedComponents(rasterGrid);
    for (final component in components) {
      if (component.cells.length < _minimumConnectedInkCellCount) {
        continue;
      }

      final componentContour =
          _buildOrderedRegionContour(component, rasterGrid);
      if (componentContour.length < 3) continue;

      final canvasContour = componentContour
          .map((point) => rasterGrid.vertexToCanvasPoint(point, canvasSize))
          .toList(growable: false);
      final normalizedContour = _normalizeClosedContour(
        canvasContour,
        smoothingPasses: 0,
      );
      if (normalizedContour.length < 3) {
        continue;
      }

      supports.add(
        _ClosedRegionSupport(
          contour: normalizedContour,
          bounds: _computeBounds(normalizedContour),
          area: _polygonArea(normalizedContour).abs(),
          center: _computePolygonCentroid(normalizedContour),
        ),
      );
    }

    return supports;
  }

  List<_SketchRecognitionDetection> _scanConnectedInkSupportedScissors(
    List<_ClosedRegionSupport> supports,
  ) {
    if (supports.isEmpty) {
      return const <_SketchRecognitionDetection>[];
    }

    final templateCloud = _buildScissorsInkTemplateCloud();
    if (templateCloud.isEmpty) {
      return const <_SketchRecognitionDetection>[];
    }

    final detections = <_SketchRecognitionDetection>[];
    for (final support in supports) {
      final supportScore = _scoreScissorsInkSupport(
        contour: support.contour,
        templateCloud: templateCloud,
      );
      if (supportScore < _minimumScissorsInkTemplateScore) {
        continue;
      }

      detections.add(
        _SketchRecognitionDetection(
          kind: OperativeSketchRecognitionKind.scissors,
          source: _SketchRecognitionSource.inkRegion,
          bounds: support.bounds,
          area: support.area,
          center: support.center,
          score: supportScore,
        ),
      );
    }

    return detections;
  }

  double _scoreScissorsInkSupport({
    required List<Offset> contour,
    required List<Offset> templateCloud,
  }) {
    final profile = _buildContourProfile(contour);
    if (profile == null) {
      return 0.0;
    }

    final cloud = _normalizePointCloud(
      _resampleClosedPathToFixedCount(
        contour,
        _pointCloudSampleCount,
      ),
    );
    if (cloud.length < 8) {
      return 0.0;
    }

    final templateDistance = _bestRotatedPointCloudDistance(
      cloud,
      templateCloud,
      maxRotationDegrees: 360,
    );
    final templateScore = 1 - _clampDouble(templateDistance / 0.28, 0.0, 1.0);
    final complexityScore = _softScore(
      profile.strongCornerCount.toDouble(),
      center: 5.0,
      tolerance: 2.3,
    );
    final roundnessPenalty = _softScore(
      profile.circularity,
      center: 1.0,
      tolerance: 0.16,
    );
    return _clampDouble(
      _weightedAverage(
        <double>[
          templateScore,
          complexityScore,
          1 - roundnessPenalty,
        ],
        const <double>[0.72, 0.18, 0.1],
      ),
      0.0,
      1.0,
    );
  }

  List<Offset> _buildScissorsInkTemplateCloud() {
    const templateCanvasSize = Size(220, 220);
    final templateStrokes = _scissorsTemplateSegments.map((segment) {
      return segment
          .map(
            (point) => Offset(
              templateCanvasSize.width * (0.5 + (point.dx * 0.42)),
              templateCanvasSize.height * (0.5 + (point.dy * 0.42)),
            ),
          )
          .toList(growable: false);
    }).toList(growable: false);

    final rasterGrid = _SketchRasterGrid.fromStrokes(
      strokes: templateStrokes,
      canvasSize: templateCanvasSize,
      resolution: _gridResolution,
    );
    final components = _extractBlockedComponents(rasterGrid);
    if (components.isEmpty) {
      return const <Offset>[];
    }

    final component = components.reduce((best, current) {
      return current.cells.length > best.cells.length ? current : best;
    });
    final contour = _buildOrderedRegionContour(component, rasterGrid);
    if (contour.length < 3) {
      return const <Offset>[];
    }

    final canvasContour = contour
        .map(
          (point) => rasterGrid.vertexToCanvasPoint(point, templateCanvasSize),
        )
        .toList(growable: false);
    final normalizedContour = _normalizeClosedContour(
      canvasContour,
      smoothingPasses: 0,
    );
    if (normalizedContour.length < 3) {
      return const <Offset>[];
    }

    return _normalizePointCloud(
      _resampleClosedPathToFixedCount(
        normalizedContour,
        _pointCloudSampleCount,
      ),
    );
  }

  List<_SketchRecognitionDetection> _applyClosedRegionSupport({
    required List<_SketchRecognitionDetection> detections,
    required List<_ClosedRegionSupport> regionSupports,
  }) {
    if (detections.isEmpty || regionSupports.isEmpty) {
      return detections;
    }

    return detections.map((detection) {
      var bestBoost = 0.0;
      for (final support in regionSupports) {
        if (!_doesRegionSupportMatchDetection(support, detection)) {
          continue;
        }

        final overlapArea =
            _rectIntersectionArea(detection.bounds, support.bounds);
        final overlapRatio = overlapArea /
            max(
              1.0,
              min(
                _rectArea(detection.bounds),
                _rectArea(support.bounds),
              ),
            );
        final areaAgreement = 1 -
            _clampDouble(
              (detection.area - support.area).abs() /
                  max(max(detection.area, support.area), 1.0),
              0.0,
              1.0,
            );
        bestBoost = max(
          bestBoost,
          min(0.14, 0.03 + (overlapRatio * 0.07) + (areaAgreement * 0.04)),
        );
      }

      if (bestBoost <= 0) {
        return detection;
      }

      return _SketchRecognitionDetection(
        kind: detection.kind,
        source: detection.source,
        bounds: detection.bounds,
        area: detection.area,
        center: detection.center,
        score: _clampDouble(detection.score + bestBoost, 0.0, 1.0),
      );
    }).toList(growable: false);
  }

  List<_SketchRecognitionDetection> _buildRegionFallbackDetections({
    required List<_ClosedRegionSupport> regionSupports,
    required List<_SketchRecognitionDetection> existingDetections,
  }) {
    final fallbacks = <_SketchRecognitionDetection>[];
    for (final support in regionSupports) {
      final alreadyCovered = existingDetections.any(
        (detection) => _doesRegionSupportMatchDetection(support, detection),
      );
      if (alreadyCovered) {
        continue;
      }

      final detection = _buildContourDetection(
        contour: support.contour,
        source: _SketchRecognitionSource.region,
      );
      if (detection != null) {
        fallbacks.add(detection);
      }
    }
    return fallbacks;
  }

  bool _doesRegionSupportMatchDetection(
    _ClosedRegionSupport support,
    _SketchRecognitionDetection detection,
  ) {
    return _matchesShapeGeometry(
      firstBounds: support.bounds,
      firstArea: support.area,
      firstCenter: support.center,
      secondBounds: detection.bounds,
      secondArea: detection.area,
      secondCenter: detection.center,
      allowLoose: true,
    );
  }

  List<_SketchRegion> _extractClosedRegions(_SketchRasterGrid grid) {
    final outside = List<bool>.filled(grid.cellCount, false);
    final visited = List<bool>.filled(grid.cellCount, false);
    _markOutsideRegion(grid, outside);

    final regions = <_SketchRegion>[];
    for (int y = 0; y < grid.height; y++) {
      for (int x = 0; x < grid.width; x++) {
        final cellIndex = grid.index(x, y);
        if (grid.blocked[cellIndex] ||
            outside[cellIndex] ||
            visited[cellIndex]) {
          continue;
        }

        final regionCells = _collectRegionCells(
          grid: grid,
          visited: visited,
          startX: x,
          startY: y,
        );
        if (regionCells.length < _minimumRegionCellCount) continue;
        regions.add(_SketchRegion(cells: regionCells));
      }
    }

    return regions;
  }

  List<_SketchRegion> _extractBlockedComponents(_SketchRasterGrid grid) {
    final visited = List<bool>.filled(grid.cellCount, false);
    final regions = <_SketchRegion>[];

    for (int y = 0; y < grid.height; y++) {
      for (int x = 0; x < grid.width; x++) {
        final cellIndex = grid.index(x, y);
        if (!grid.blocked[cellIndex] || visited[cellIndex]) {
          continue;
        }

        final regionCells = _collectBlockedCells(
          grid: grid,
          visited: visited,
          startX: x,
          startY: y,
        );
        if (regionCells.length < _minimumConnectedInkCellCount) {
          continue;
        }
        regions.add(_SketchRegion(cells: regionCells));
      }
    }

    return regions;
  }

  void _markOutsideRegion(_SketchRasterGrid grid, List<bool> outside) {
    final queue = <int>[];
    var head = 0;

    void enqueueIfOpen(int x, int y) {
      if (!grid.inBounds(x, y)) return;
      final cellIndex = grid.index(x, y);
      if (grid.blocked[cellIndex] || outside[cellIndex]) return;
      outside[cellIndex] = true;
      queue.add(cellIndex);
    }

    for (int x = 0; x < grid.width; x++) {
      enqueueIfOpen(x, 0);
      enqueueIfOpen(x, grid.height - 1);
    }
    for (int y = 0; y < grid.height; y++) {
      enqueueIfOpen(0, y);
      enqueueIfOpen(grid.width - 1, y);
    }

    while (head < queue.length) {
      final cellIndex = queue[head++];
      final x = cellIndex % grid.width;
      final y = cellIndex ~/ grid.width;
      for (final offset in _orthogonalNeighbors) {
        final nextX = x + offset.dx.toInt();
        final nextY = y + offset.dy.toInt();
        if (!grid.inBounds(nextX, nextY)) continue;

        final nextIndex = grid.index(nextX, nextY);
        if (grid.blocked[nextIndex] || outside[nextIndex]) continue;
        outside[nextIndex] = true;
        queue.add(nextIndex);
      }
    }
  }

  List<int> _collectRegionCells({
    required _SketchRasterGrid grid,
    required List<bool> visited,
    required int startX,
    required int startY,
  }) {
    final cells = <int>[];
    final queue = <int>[grid.index(startX, startY)];
    var head = 0;
    visited[queue.first] = true;

    while (head < queue.length) {
      final cellIndex = queue[head++];
      cells.add(cellIndex);
      final x = cellIndex % grid.width;
      final y = cellIndex ~/ grid.width;
      for (final offset in _orthogonalNeighbors) {
        final nextX = x + offset.dx.toInt();
        final nextY = y + offset.dy.toInt();
        if (!grid.inBounds(nextX, nextY)) continue;

        final nextIndex = grid.index(nextX, nextY);
        if (grid.blocked[nextIndex] || visited[nextIndex]) continue;
        visited[nextIndex] = true;
        queue.add(nextIndex);
      }
    }

    return cells;
  }

  List<int> _collectBlockedCells({
    required _SketchRasterGrid grid,
    required List<bool> visited,
    required int startX,
    required int startY,
  }) {
    final cells = <int>[];
    final queue = <int>[grid.index(startX, startY)];
    var head = 0;
    visited[queue.first] = true;

    while (head < queue.length) {
      final cellIndex = queue[head++];
      cells.add(cellIndex);
      final x = cellIndex % grid.width;
      final y = cellIndex ~/ grid.width;
      for (int offsetY = -1; offsetY <= 1; offsetY++) {
        for (int offsetX = -1; offsetX <= 1; offsetX++) {
          if (offsetX == 0 && offsetY == 0) continue;
          final nextX = x + offsetX;
          final nextY = y + offsetY;
          if (!grid.inBounds(nextX, nextY)) continue;

          final nextIndex = grid.index(nextX, nextY);
          if (!grid.blocked[nextIndex] || visited[nextIndex]) continue;
          visited[nextIndex] = true;
          queue.add(nextIndex);
        }
      }
    }

    return cells;
  }

  List<Offset> _buildOrderedRegionContour(
    _SketchRegion region,
    _SketchRasterGrid grid,
  ) {
    final directedEdges = <_GridDirectedEdge>[];
    final edgeStartMap = <String, List<_GridDirectedEdge>>{};

    void addEdge(_GridVertex start, _GridVertex end) {
      final edge = _GridDirectedEdge(start: start, end: end);
      directedEdges.add(edge);
      edgeStartMap
          .putIfAbsent(start.key, () => <_GridDirectedEdge>[])
          .add(edge);
    }

    for (final cellIndex in region.cells) {
      final x = cellIndex % grid.width;
      final y = cellIndex ~/ grid.width;

      final leftIndex = x > 0 ? grid.index(x - 1, y) : -1;
      if (x == 0 || !region.cellSet.contains(leftIndex)) {
        addEdge(_GridVertex(x, y + 1), _GridVertex(x, y));
      }
      final topIndex = y > 0 ? grid.index(x, y - 1) : -1;
      if (y == 0 || !region.cellSet.contains(topIndex)) {
        addEdge(_GridVertex(x, y), _GridVertex(x + 1, y));
      }
      final rightIndex = x + 1 < grid.width ? grid.index(x + 1, y) : -1;
      if (x + 1 >= grid.width || !region.cellSet.contains(rightIndex)) {
        addEdge(_GridVertex(x + 1, y), _GridVertex(x + 1, y + 1));
      }
      final bottomIndex = y + 1 < grid.height ? grid.index(x, y + 1) : -1;
      if (y + 1 >= grid.height || !region.cellSet.contains(bottomIndex)) {
        addEdge(_GridVertex(x + 1, y + 1), _GridVertex(x, y + 1));
      }
    }

    final consumedEdges = <String>{};
    List<Offset> bestLoop = const <Offset>[];
    for (final edge in directedEdges) {
      if (!consumedEdges.add(edge.key)) continue;

      final loop = <Offset>[edge.start.toOffset(), edge.end.toOffset()];
      var nextKey = edge.end.key;

      while (nextKey != edge.start.key) {
        final candidates = edgeStartMap[nextKey] ?? const <_GridDirectedEdge>[];
        _GridDirectedEdge? nextEdge;
        for (final candidate in candidates) {
          if (consumedEdges.contains(candidate.key)) continue;
          nextEdge = candidate;
          break;
        }
        if (nextEdge == null) {
          loop.clear();
          break;
        }

        consumedEdges.add(nextEdge.key);
        loop.add(nextEdge.end.toOffset());
        nextKey = nextEdge.end.key;
      }

      if (loop.length > bestLoop.length) bestLoop = loop;
    }

    if (bestLoop.length < 4) return const <Offset>[];
    final polygon = List<Offset>.from(bestLoop);
    if ((polygon.first - polygon.last).distance <= 0.01) {
      polygon.removeLast();
    }
    return _compressCollinearVertices(polygon);
  }

  List<Offset> _compressCollinearVertices(List<Offset> polygon) {
    if (polygon.length < 3) return List<Offset>.from(polygon);

    final compressed = <Offset>[];
    for (int index = 0; index < polygon.length; index++) {
      final previous = polygon[(index - 1 + polygon.length) % polygon.length];
      final current = polygon[index];
      final next = polygon[(index + 1) % polygon.length];
      if (_distanceToSegment(current, previous, next) <= 0.01) continue;
      compressed.add(current);
    }

    return compressed.length >= 3 ? compressed : List<Offset>.from(polygon);
  }

  double _clampDouble(double value, double minValue, double maxValue) {
    return value.clamp(minValue, maxValue).toDouble();
  }

  static const List<Offset> _orthogonalNeighbors = <Offset>[
    Offset(1, 0),
    Offset(-1, 0),
    Offset(0, 1),
    Offset(0, -1),
  ];

  static int _compareRecognitionKinds(
    OperativeSketchRecognitionKind first,
    OperativeSketchRecognitionKind second,
  ) {
    final priorityComparison =
        second.recognitionPriority.compareTo(first.recognitionPriority);
    if (priorityComparison != 0) {
      return priorityComparison;
    }
    return first.index.compareTo(second.index);
  }
}

enum _SketchRecognitionSource {
  graph,
  inkRegion,
  stroke,
  stitchedLoop,
  region,
}

class _SketchRecognitionDetection {
  final OperativeSketchRecognitionKind kind;
  final _SketchRecognitionSource source;
  final Rect bounds;
  final double area;
  final Offset center;
  final double score;

  const _SketchRecognitionDetection({
    required this.kind,
    required this.source,
    required this.bounds,
    required this.area,
    required this.center,
    required this.score,
  });
}

class _ClosedRegionSupport {
  final List<Offset> contour;
  final Rect bounds;
  final double area;
  final Offset center;

  const _ClosedRegionSupport({
    required this.contour,
    required this.bounds,
    required this.area,
    required this.center,
  });
}

class _ProcessedStroke {
  final int id;
  final List<Offset> points;
  final double length;
  final Rect bounds;
  final bool isClosed;

  const _ProcessedStroke({
    required this.id,
    required this.points,
    required this.length,
    required this.bounds,
    required this.isClosed,
  });
}

class _ContourProfile {
  final List<Offset> contour;
  final List<Offset> smoothedContour;
  final Rect bounds;
  final double area;
  final double perimeter;
  final Offset centroid;
  final double smoothnessScore;
  final double selfIntersectionScore;
  final double circularity;
  final List<_CornerPeak> cornerPeaks;
  final double triangleCornerScore;
  final double squareCornerScore;
  final int strongCornerCount;

  const _ContourProfile({
    required this.contour,
    required this.smoothedContour,
    required this.bounds,
    required this.area,
    required this.perimeter,
    required this.centroid,
    required this.smoothnessScore,
    required this.selfIntersectionScore,
    required this.circularity,
    required this.cornerPeaks,
    required this.triangleCornerScore,
    required this.squareCornerScore,
    required this.strongCornerCount,
  });
}

class _CornerPeak {
  final int index;
  final double angle;
  final double sharpness;
  final double strength;

  const _CornerPeak({
    required this.index,
    required this.angle,
    required this.sharpness,
    required this.strength,
  });
}

class _ShapeScore {
  final OperativeSketchRecognitionKind kind;
  final double score;

  const _ShapeScore({
    required this.kind,
    required this.score,
  });
}

class _PolygonFitScore {
  final List<Offset> polygon;
  final double score;

  const _PolygonFitScore({
    required this.polygon,
    required this.score,
  });
}

class _FittedCircle {
  final Offset center;
  final double radius;
  final double rmsResidual;
  final double maxResidual;
  final double coverage;

  const _FittedCircle({
    required this.center,
    required this.radius,
    required this.rmsResidual,
    required this.maxResidual,
    required this.coverage,
  });
}

class _MutableStrokeGeometry {
  final int id;
  final List<Offset> points;
  final bool isClosed;

  _MutableStrokeGeometry({
    required this.id,
    required this.points,
    required this.isClosed,
  });
}

class _StrokePointInsertion {
  final int segmentIndex;
  final double t;
  final Offset point;

  const _StrokePointInsertion({
    required this.segmentIndex,
    required this.t,
    required this.point,
  });
}

class _EndpointSegmentSnap {
  final int sourceStrokeId;
  final bool isSourceStart;
  final int targetStrokeId;
  final int targetSegmentIndex;
  final double targetSegmentT;
  final Offset point;
  final double distance;

  const _EndpointSegmentSnap({
    required this.sourceStrokeId,
    required this.isSourceStart,
    required this.targetStrokeId,
    required this.targetSegmentIndex,
    required this.targetSegmentT,
    required this.point,
    required this.distance,
  });
}

class _SegmentProjection {
  final Offset point;
  final double t;
  final double distance;

  const _SegmentProjection({
    required this.point,
    required this.t,
    required this.distance,
  });
}

class _AnchoredStrokeEndpoint {
  final int strokeId;
  final Offset anchorPoint;
  final Offset outwardDirection;
  final double length;
  final List<Offset> points;

  const _AnchoredStrokeEndpoint({
    required this.strokeId,
    required this.anchorPoint,
    required this.outwardDirection,
    required this.length,
    required this.points,
  });
}

class _SegmentIntersection {
  final Offset point;
  final double firstT;
  final double secondT;

  const _SegmentIntersection({
    required this.point,
    required this.firstT,
    required this.secondT,
  });
}

class _AugmentedStrokeGeometry {
  final List<Offset> points;
  final Set<int> splitIndices;

  const _AugmentedStrokeGeometry({
    required this.points,
    required this.splitIndices,
  });
}

class _EndpointNode {
  final int id;
  Offset position;
  int _pointCount = 0;
  final List<_EndpointAttachment> attachments = <_EndpointAttachment>[];

  _EndpointNode({
    required this.id,
    required this.position,
  });

  void addAttachment(_EndpointAttachment attachment) {
    position = Offset(
      ((position.dx * _pointCount) + attachment.position.dx) /
          (_pointCount + 1),
      ((position.dy * _pointCount) + attachment.position.dy) /
          (_pointCount + 1),
    );
    _pointCount++;
    attachments.add(attachment);
  }
}

class _EndpointGraphEdge {
  final int id;
  final int strokeId;
  final int startNodeId;
  final int endNodeId;
  final List<Offset> points;

  const _EndpointGraphEdge({
    required this.id,
    required this.strokeId,
    required this.startNodeId,
    required this.endNodeId,
    required this.points,
  });
}

class _EndpointGraphData {
  final Map<int, _EndpointNode> nodesById;
  final List<_EndpointGraphEdge> edges;
  final Map<int, List<_EndpointGraphEdge>> adjacency;
  final List<Set<int>> components;

  const _EndpointGraphData({
    required this.nodesById,
    required this.edges,
    required this.adjacency,
    required this.components,
  });

  factory _EndpointGraphData.empty() {
    return const _EndpointGraphData(
      nodesById: <int, _EndpointNode>{},
      edges: <_EndpointGraphEdge>[],
      adjacency: <int, List<_EndpointGraphEdge>>{},
      components: <Set<int>>[],
    );
  }
}

class _LoopContour {
  final List<Offset> points;
  final Set<int> strokeIds;

  const _LoopContour({
    required this.points,
    required this.strokeIds,
  });
}

class _EndpointAttachment {
  final int strokeId;
  final bool isStart;
  final Offset position;
  final Offset outwardDirection;

  const _EndpointAttachment({
    required this.strokeId,
    required this.isStart,
    required this.position,
    required this.outwardDirection,
  });
}

class _SketchRegion {
  final List<int> cells;
  final Set<int> cellSet;

  _SketchRegion({
    required this.cells,
  }) : cellSet = cells.toSet();
}

class _SketchRasterGrid {
  final int width;
  final int height;
  final List<bool> blocked;

  const _SketchRasterGrid({
    required this.width,
    required this.height,
    required this.blocked,
  });

  factory _SketchRasterGrid.fromStrokes({
    required List<List<Offset>> strokes,
    required Size canvasSize,
    required int resolution,
  }) {
    final blocked = List<bool>.filled(resolution * resolution, false);
    final cellSize = canvasSize.width / resolution;
    final brushRadius = max(1, (5 / max(cellSize, 0.0001)).ceil());
    final grid = _SketchRasterGrid(
      width: resolution,
      height: resolution,
      blocked: blocked,
    );

    for (final stroke in strokes) {
      if (stroke.length == 1) {
        final cell = grid._pointToCell(stroke.first, canvasSize);
        grid._markDisk(cell.dx, cell.dy, brushRadius);
        continue;
      }

      for (int index = 1; index < stroke.length; index++) {
        final start = stroke[index - 1];
        final end = stroke[index];
        final segmentLength = (end - start).distance;
        final samples =
            max(1, (segmentLength / max(1.0, cellSize * 0.55)).ceil());

        for (int sample = 0; sample <= samples; sample++) {
          final t = sample / samples;
          final point = Offset(
            start.dx + ((end.dx - start.dx) * t),
            start.dy + ((end.dy - start.dy) * t),
          );
          final cell = grid._pointToCell(point, canvasSize);
          grid._markDisk(cell.dx, cell.dy, brushRadius);
        }
      }
    }

    grid._sealSmallOpenings();
    return grid;
  }

  int get cellCount => width * height;

  int index(int x, int y) => (y * width) + x;

  bool inBounds(int x, int y) {
    return x >= 0 && y >= 0 && x < width && y < height;
  }

  Offset _pointToCell(Offset point, Size canvasSize) {
    final x = ((point.dx / canvasSize.width) * (width - 1))
        .round()
        .clamp(0, width - 1);
    final y = ((point.dy / canvasSize.height) * (height - 1))
        .round()
        .clamp(0, height - 1);
    return Offset(x.toDouble(), y.toDouble());
  }

  Offset vertexToCanvasPoint(Offset vertex, Size canvasSize) {
    return Offset(
      (vertex.dx / width) * canvasSize.width,
      (vertex.dy / height) * canvasSize.height,
    );
  }

  void _markDisk(double centerX, double centerY, int radius) {
    final minX = (centerX - radius).floor();
    final maxX = (centerX + radius).ceil();
    final minY = (centerY - radius).floor();
    final maxY = (centerY + radius).ceil();

    for (int y = minY; y <= maxY; y++) {
      for (int x = minX; x <= maxX; x++) {
        if (!inBounds(x, y)) continue;
        final dx = x - centerX;
        final dy = y - centerY;
        if ((dx * dx) + (dy * dy) <= radius * radius) {
          blocked[index(x, y)] = true;
        }
      }
    }
  }

  void _sealSmallOpenings() {
    for (int pass = 0; pass < 2; pass++) {
      final pendingBlocks = <int>[];
      for (int y = 1; y < height - 1; y++) {
        for (int x = 1; x < width - 1; x++) {
          final cellIndex = index(x, y);
          if (blocked[cellIndex]) continue;

          final left = blocked[index(x - 1, y)];
          final right = blocked[index(x + 1, y)];
          final up = blocked[index(x, y - 1)];
          final down = blocked[index(x, y + 1)];
          final upLeft = blocked[index(x - 1, y - 1)];
          final upRight = blocked[index(x + 1, y - 1)];
          final downLeft = blocked[index(x - 1, y + 1)];
          final downRight = blocked[index(x + 1, y + 1)];

          final bridgesHorizontal = left &&
              right &&
              (up || down || upLeft || upRight || downLeft || downRight);
          final bridgesVertical = up &&
              down &&
              (left || right || upLeft || upRight || downLeft || downRight);
          final bridgesDiagonal =
              ((upLeft && downRight) || (upRight && downLeft)) &&
                  (left || right || up || down);
          final crowdedJunction = _blockedNeighborCount(x, y) >= 5 &&
              ((left && right) || (up && down));

          if (bridgesHorizontal ||
              bridgesVertical ||
              bridgesDiagonal ||
              crowdedJunction) {
            pendingBlocks.add(cellIndex);
          }
        }
      }

      if (pendingBlocks.isEmpty) return;
      for (final cellIndex in pendingBlocks) {
        blocked[cellIndex] = true;
      }
    }
  }

  int _blockedNeighborCount(int x, int y) {
    var count = 0;
    for (int offsetY = -1; offsetY <= 1; offsetY++) {
      for (int offsetX = -1; offsetX <= 1; offsetX++) {
        if (offsetX == 0 && offsetY == 0) continue;
        if (blocked[index(x + offsetX, y + offsetY)]) count++;
      }
    }
    return count;
  }
}

class _GridDirectedEdge {
  final _GridVertex start;
  final _GridVertex end;

  const _GridDirectedEdge({
    required this.start,
    required this.end,
  });

  String get key => '${start.key}>${end.key}';
}

class _GridVertex {
  final int x;
  final int y;

  const _GridVertex(this.x, this.y);

  String get key => '$x:$y';

  Offset toOffset() => Offset(x.toDouble(), y.toDouble());
}
