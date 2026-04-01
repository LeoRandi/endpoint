import '../_imports.dart';

enum OperativeSketchRecognitionKind {
  none,
  triangle,
  square,
  rhombus,
  circle,
}

extension OperativeSketchRecognitionKindLabel
    on OperativeSketchRecognitionKind {
  String get label {
    switch (this) {
      case OperativeSketchRecognitionKind.none:
        return 'NINGUNA';
      case OperativeSketchRecognitionKind.triangle:
        return 'TRIANGULO';
      case OperativeSketchRecognitionKind.square:
        return 'CUADRADO';
      case OperativeSketchRecognitionKind.rhombus:
        return 'ROMBO';
      case OperativeSketchRecognitionKind.circle:
        return 'CIRCULO';
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
  static const double _minimumClassificationScore = 0.58;
  static const double _minimumClassificationMargin = 0.08;
  static const double _duplicateOverlapThreshold = 0.42;
  static const double _duplicateAreaRatioThreshold = 0.34;
  static const double _duplicateCenterFactor = 0.35;
  static const List<OperativeSketchRecognitionKind> _priorityOrder =
      <OperativeSketchRecognitionKind>[
    OperativeSketchRecognitionKind.triangle,
    OperativeSketchRecognitionKind.square,
    OperativeSketchRecognitionKind.rhombus,
    OperativeSketchRecognitionKind.circle,
  ];

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

    final vectorDetections = _scanVectorContours(
      strokes: graphReadyStrokes,
      canvasSize: canvasSize,
    );
    final rasterDetections = _scanClosedRegions(
      strokes: graphReadyStrokes
          .map((stroke) => stroke.points)
          .toList(growable: false),
      canvasSize: canvasSize,
    );
    final mergedDetections = _mergeDetections(
      primaryDetections: vectorDetections,
      secondaryDetections: rasterDetections,
    );
    return _resultFromCounts(_countDetections(mergedDetections));
  }

  Map<OperativeSketchRecognitionKind, int> _emptyCounts() {
    return <OperativeSketchRecognitionKind, int>{
      for (final kind in _priorityOrder) kind: 0,
    };
  }

  OperativeSketchRecognitionResult _resultFromCounts(
    Map<OperativeSketchRecognitionKind, int> counts,
  ) {
    final matches = _priorityOrder
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
    for (final kind in _priorityOrder) {
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
    if (strokes.length <= 1) {
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

    _EndpointNode resolveEndpointNode(Offset point) {
      for (final node in endpointNodes) {
        if ((node.position - point).distance <= snapDistance) {
          node.addPoint(point);
          return node;
        }
      }

      final node = _EndpointNode(id: nextEndpointNodeId++, position: point);
      endpointNodes.add(node);
      return node;
    }

    for (final stroke in mutableStrokes.where((stroke) => !stroke.isClosed)) {
      for (final isStart in const <bool>[true, false]) {
        final endpoint = isStart ? stroke.points.first : stroke.points.last;
        final node = resolveEndpointNode(endpoint);
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
      final startFlags =
          endpointStartFlagsByNodeId[node.id] ?? const <bool>[];
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

    for (final sourceStroke in mutableStrokes.where((stroke) => !stroke.isClosed)) {
      for (final isStart in const <bool>[true, false]) {
        final endpoint = isStart ? sourceStroke.points.first : sourceStroke.points.last;
        _EndpointSegmentSnap? bestSnap;

        for (final targetStroke in mutableStrokes) {
          if (targetStroke.id == sourceStroke.id || targetStroke.points.length < 2) {
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
            .putIfAbsent(bestSnap.targetStrokeId, () => <_StrokePointInsertion>[])
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

    final graphReadyStrokes = <_ProcessedStroke>[];
    var nextGeneratedStrokeId = 100000;
    for (final stroke in mutableStrokes) {
      final augmentation = _augmentStrokePoints(
        points: stroke.points,
        insertions: insertionsByStrokeId[stroke.id] ?? const <_StrokePointInsertion>[],
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

      final splitIndices = augmentation.splitIndices.toList()..sort();
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
    for (int segmentIndex = 0; segmentIndex < points.length - 1; segmentIndex++) {
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
    final denominator =
        (firstDirection.dx * secondDirection.dy) -
            (firstDirection.dy * secondDirection.dx);
    if (denominator.abs() <= 0.00001) {
      return null;
    }

    final betweenStarts = secondStart - firstStart;
    final firstT =
        ((betweenStarts.dx * secondDirection.dy) -
                (betweenStarts.dy * secondDirection.dx)) /
            denominator;
    final secondT =
        ((betweenStarts.dx * firstDirection.dy) -
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
    final openStrokes = strokes.where((stroke) => !stroke.isClosed).toList();
    if (openStrokes.length < 2) return const <_LoopContour>[];

    final minCanvasSide = min(canvasSize.width, canvasSize.height).toDouble();
    final snapDistance = _clampDouble(
      minCanvasSide * _endpointSnapDistanceFactor,
      _minimumEndpointSnapDistance,
      _maximumEndpointSnapDistance,
    );
    final endpointNodes = <_EndpointNode>[];
    var nextNodeId = 0;

    _EndpointNode resolveNode(Offset point) {
      for (final node in endpointNodes) {
        if ((node.position - point).distance <= snapDistance) {
          node.addPoint(point);
          return node;
        }
      }
      final node = _EndpointNode(id: nextNodeId++, position: point);
      endpointNodes.add(node);
      return node;
    }

    final edges = <_EndpointGraphEdge>[];
    for (final stroke in openStrokes) {
      final startNode = resolveNode(stroke.points.first);
      final endNode = resolveNode(stroke.points.last);
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
    if (edges.length < 2) return const <_LoopContour>[];

    final adjacency = <int, List<_EndpointGraphEdge>>{};
    for (final edge in edges) {
      adjacency.putIfAbsent(edge.startNodeId, () => <_EndpointGraphEdge>[])
        ..add(edge);
      adjacency.putIfAbsent(edge.endNodeId, () => <_EndpointGraphEdge>[])
        ..add(edge);
    }

    final nodesById = <int, _EndpointNode>{
      for (final node in endpointNodes) node.id: node,
    };
    final nodeComponents = _collectGraphComponents(adjacency);
    final loops = <_LoopContour>[];

    for (final componentNodeIds in nodeComponents) {
      final componentEdges = edges
          .where((edge) => componentNodeIds.contains(edge.startNodeId))
          .toList(growable: false);
      if (componentEdges.length < 2) continue;
      loops.addAll(
        _findLoopContoursInComponent(
          componentNodeIds: componentNodeIds,
          componentEdges: componentEdges,
          adjacency: adjacency,
          nodesById: nodesById,
        ),
      );
    }

    return loops;
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
        for (final edge in adjacency[currentNodeId] ?? const <_EndpointGraphEdge>[]) {
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
      if (cycleEdges.length < 3 || cycleNodeIds.length != cycleEdges.length + 1) {
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

      for (final edge in adjacency[currentNodeId] ?? const <_EndpointGraphEdge>[]) {
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

    final normalized = _normalizeClosedContour(orderedPoints);
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
    final normalizedContour = _normalizeClosedContour(contour);
    final profile = _buildContourProfile(normalizedContour);
    if (profile == null) return null;

    final shapeScore = _pickBestShapeScore(profile);
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

  _ShapeScore _pickBestShapeScore(_ContourProfile profile) {
    final scores = <_ShapeScore>[
      _scoreTriangle(profile),
      _scoreSquare(profile),
      _scoreRhombus(profile),
      _scoreCircle(profile),
    ]..sort((left, right) => right.score.compareTo(left.score));

    final best = scores.first;
    final secondBestScore = scores.length > 1 ? scores[1].score : 0.0;
    if (best.score < _minimumClassificationScore ||
        best.score - secondBestScore < _minimumClassificationMargin) {
      return const _ShapeScore(
        kind: OperativeSketchRecognitionKind.none,
        score: 0.0,
      );
    }

    return best;
  }

  _ShapeScore _scoreTriangle(_ContourProfile profile) {
    final candidates = _buildPolygonCandidates(profile.contour, 3);
    var bestScore = 0.0;

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
          fit.score,
          closureScore,
          sideBalance,
          angleScore,
          profile.smoothnessScore,
          profile.selfIntersectionScore,
        ],
        const <double>[0.34, 0.34, 0.08, 0.10, 0.07, 0.07],
      );

      // Si el contorno se deja reducir a tres lados cerrados y encaja de forma
      // razonable con ese poligono, aceptamos un triangulo mas tosco.
      if (fit.score >= 0.5 && closureScore >= 0.68) {
        candidateScore = max(
          candidateScore,
          0.64 + ((fit.score - 0.5) * 0.22) + ((closureScore - 0.68) * 0.18),
        );
      }

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
            fit.score,
            geometryScore,
            profile.smoothnessScore,
            profile.selfIntersectionScore,
          ],
          const <double>[0.46, 0.32, 0.12, 0.10],
        ),
      );
    }

    return _ShapeScore(
      kind: OperativeSketchRecognitionKind.square,
      score: bestScore,
    );
  }

  _ShapeScore _scoreRhombus(_ContourProfile profile) {
    final candidates = _buildPolygonCandidates(profile.contour, 4);
    var bestScore = 0.0;

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
      final diagonalRatio =
          diagonalLengths.first / max(diagonalLengths.last, 0.0001);
      final oppositeAngleSimilarity = max(
        (angles[0] - angles[2]).abs(),
        (angles[1] - angles[3]).abs(),
      );
      final nonSquareScore = _softScore(
        angles.map((angle) => (angle - 90).abs()).reduce(max),
        center: 28,
        tolerance: 28,
      );
      final geometryScore = _weightedAverage(
        <double>[
          sideLengths.first / max(sideLengths.last, 0.0001),
          _softScore(oppositeParallelism, center: 0, tolerance: 24),
          _softScore(oppositeAngleSimilarity, center: 0, tolerance: 26),
          nonSquareScore,
          _softScore(diagonalRatio, center: 0.74, tolerance: 0.24),
        ],
        const <double>[0.26, 0.20, 0.22, 0.18, 0.14],
      );

      bestScore = max(
        bestScore,
        _weightedAverage(
          <double>[
            fit.score,
            geometryScore,
            profile.smoothnessScore,
            profile.selfIntersectionScore,
          ],
          const <double>[0.44, 0.34, 0.12, 0.10],
        ),
      );
    }

    return _ShapeScore(
      kind: OperativeSketchRecognitionKind.rhombus,
      score: bestScore,
    );
  }

  _ShapeScore _scoreCircle(_ContourProfile profile) {
    final fittedCircle = _fitCircle(profile.contour);
    if (fittedCircle == null || fittedCircle.radius <= 0) {
      return const _ShapeScore(
        kind: OperativeSketchRecognitionKind.circle,
        score: 0.0,
      );
    }

    final radiusScale = max(fittedCircle.radius, 0.0001);
    final circleArea = pi * fittedCircle.radius * fittedCircle.radius;
    final score = _weightedAverage(
      <double>[
        1 - _clampDouble(fittedCircle.rmsResidual / (radiusScale * 0.14), 0, 1),
        1 - _clampDouble(fittedCircle.maxResidual / (radiusScale * 0.28), 0, 1),
        fittedCircle.coverage,
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
        profile.smoothnessScore,
        profile.selfIntersectionScore,
      ],
      const <double>[0.24, 0.12, 0.14, 0.12, 0.14, 0.08, 0.10, 0.06],
    );

    return _ShapeScore(
      kind: OperativeSketchRecognitionKind.circle,
      score: score,
    );
  }

  _ContourProfile? _buildContourProfile(List<Offset> contour) {
    if (contour.length < 3) return null;

    final bounds = _computeBounds(contour);
    final shortSide = min(bounds.width, bounds.height).toDouble();
    if (bounds.width <= 0 ||
        bounds.height <= 0 ||
        shortSide < _minimumContourShortSide) {
      return null;
    }

    final area = _polygonArea(contour).abs();
    if (area < _minimumContourArea) return null;

    final perimeter = _polygonPerimeter(contour);
    if (perimeter < _minimumContourPerimeter) return null;

    return _ContourProfile(
      contour: contour,
      bounds: bounds,
      area: area,
      perimeter: perimeter,
      centroid: _computePolygonCentroid(contour),
      smoothnessScore: _computeSmoothnessScore(contour),
      selfIntersectionScore: _computeSelfIntersectionScore(contour),
      circularity: (4 * pi * area) / max(perimeter * perimeter, 0.0001),
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

    return candidates;
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

    return _PolygonFitScore(
      polygon: polygon,
      score: _weightedAverage(
        <double>[distanceScore, areaScore, perimeterScore],
        const <double>[0.56, 0.24, 0.20],
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
      final next = index + 1 < angles.length ? angles[index + 1] : angles.first + (2 * pi);
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

  List<Offset> _normalizeClosedContour(List<Offset> points) {
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
    contour = _smoothPolyline(contour, closed: true, passes: 1);
    contour = _resamplePolyline(contour, spacing, closed: true);
    contour = _deduplicateSequentialPoints(contour, minimumDistance: 0.7);
    return contour.length >= 3 ? contour : const <Offset>[];
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
        _distanceToSegment(point, polygon[index], polygon[(index + 1) % polygon.length]),
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

  List<Offset> _simplifyWithDouglasPeucker(List<Offset> points, double epsilon) {
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

  double _softScore(double value, {required double center, required double tolerance}) {
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

        final previous =
            current[(index - 1 + current.length) % current.length];
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
        .map((point) => '${point.dx.toStringAsFixed(1)}:${point.dy.toStringAsFixed(1)}')
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
    final merged = List<_SketchRecognitionDetection>.from(primaryDetections);
    for (final candidate in secondaryDetections) {
      final duplicateIndex = merged.indexWhere(
        (existing) => _areDuplicateDetections(existing, candidate),
      );
      if (duplicateIndex < 0) {
        merged.add(candidate);
      } else {
        merged[duplicateIndex] = _pickPreferredDetection(
          merged[duplicateIndex],
          candidate,
        );
      }
    }
    return merged;
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
    final intersectionArea = _rectIntersectionArea(first.bounds, second.bounds);
    if (intersectionArea <= 0) return false;

    final overlapRatio = intersectionArea /
        max(1.0, min(_rectArea(first.bounds), _rectArea(second.bounds)));
    if (overlapRatio < _duplicateOverlapThreshold) return false;

    final areaRatio = min(first.area, second.area) / max(first.area, second.area);
    if (areaRatio < _duplicateAreaRatioThreshold) return false;

    final centerDistance = (first.center - second.center).distance;
    final minDiagonal =
        min(_rectDiagonal(first.bounds), _rectDiagonal(second.bounds));
    return centerDistance <= max(6.0, minDiagonal * _duplicateCenterFactor);
  }

  _SketchRecognitionDetection _pickPreferredDetection(
    _SketchRecognitionDetection first,
    _SketchRecognitionDetection second,
  ) {
    final firstScore = _duplicatePreferenceScore(first);
    final secondScore = _duplicatePreferenceScore(second);
    if (firstScore > secondScore) return first;
    if (secondScore > firstScore) return second;
    return first.area >= second.area ? first : second;
  }

  double _duplicatePreferenceScore(_SketchRecognitionDetection detection) {
    final sourceBonus = switch (detection.source) {
      _SketchRecognitionSource.stroke => 0.18,
      _SketchRecognitionSource.stitchedLoop => 0.22,
      _SketchRecognitionSource.region => 0.0,
    };
    return detection.score + sourceBonus;
  }

  List<_SketchRecognitionDetection> _scanClosedRegions({
    required List<List<Offset>> strokes,
    required Size canvasSize,
  }) {
    final detections = <_SketchRecognitionDetection>[];
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
      final detection = _buildContourDetection(
        contour: canvasContour,
        source: _SketchRecognitionSource.region,
      );
      if (detection != null) detections.add(detection);
    }

    return detections;
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

  List<Offset> _buildOrderedRegionContour(
    _SketchRegion region,
    _SketchRasterGrid grid,
  ) {
    final directedEdges = <_GridDirectedEdge>[];
    final edgeStartMap = <String, List<_GridDirectedEdge>>{};

    void addEdge(_GridVertex start, _GridVertex end) {
      final edge = _GridDirectedEdge(start: start, end: end);
      directedEdges.add(edge);
      edgeStartMap.putIfAbsent(start.key, () => <_GridDirectedEdge>[]).add(edge);
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
}

enum _SketchRecognitionSource {
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
  final Rect bounds;
  final double area;
  final double perimeter;
  final Offset centroid;
  final double smoothnessScore;
  final double selfIntersectionScore;
  final double circularity;

  const _ContourProfile({
    required this.contour,
    required this.bounds,
    required this.area,
    required this.perimeter,
    required this.centroid,
    required this.smoothnessScore,
    required this.selfIntersectionScore,
    required this.circularity,
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
  int _pointCount = 1;

  _EndpointNode({
    required this.id,
    required this.position,
  });

  void addPoint(Offset point) {
    position = Offset(
      ((position.dx * _pointCount) + point.dx) / (_pointCount + 1),
      ((position.dy * _pointCount) + point.dy) / (_pointCount + 1),
    );
    _pointCount++;
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

class _LoopContour {
  final List<Offset> points;
  final Set<int> strokeIds;

  const _LoopContour({
    required this.points,
    required this.strokeIds,
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
