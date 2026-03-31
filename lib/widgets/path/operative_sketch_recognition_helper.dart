import '../_imports.dart';

/// Tipos de coincidencia que el helper puede reconocer en el dibujo actual.
enum OperativeSketchRecognitionKind {
  none,
  triangle,
  square,
  rhombus,
  circle,
}

/// Traduce cada tipo de forma a la etiqueta que se muestra en el overlay.
extension OperativeSketchRecognitionKindLabel
    on OperativeSketchRecognitionKind {
  /// Devuelve el nombre visible de la forma usando etiquetas ASCII.
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

/// Representa una familia reconocida junto a cuantas veces aparece en el dibujo.
class OperativeSketchRecognitionMatch {
  final OperativeSketchRecognitionKind kind;
  final int count;

  /// Crea una coincidencia visible a partir de su tipo y de su numero de apariciones.
  const OperativeSketchRecognitionMatch({
    required this.kind,
    required this.count,
  });

  /// Expone el texto que se mostrara en el feedback flotante del overlay.
  String get displayLabel => '${kind.label}:$count';
}

/// Resultado compacto del escaneo para que el overlay traduzca la deteccion en UI.
class OperativeSketchRecognitionResult {
  final OperativeSketchRecognitionKind kind;
  final int count;
  final List<OperativeSketchRecognitionMatch> matches;

  /// Crea un resultado tipado a partir de la familia detectada y sus apariciones.
  const OperativeSketchRecognitionResult({
    required this.kind,
    required this.count,
    this.matches = const <OperativeSketchRecognitionMatch>[],
  });

  /// Indica de forma explicita si el escaneo encontro al menos una figura conocida.
  bool get hasMatch => matches.isNotEmpty;

  /// Devuelve la secuencia de textos que el overlay mostrara uno detras de otro.
  List<String> get displayLabels {
    return matches.map((match) => match.displayLabel).toList(growable: false);
  }
}

/// Helper que rasteriza el dibujo, separa regiones cerradas y clasifica su silueta.
class OperativeSketchRecognitionHelper {
  static const int _gridResolution = 96;
  static const int _minimumRegionCellCount = 10;
  static const List<OperativeSketchRecognitionKind> _priorityOrder =
      <OperativeSketchRecognitionKind>[
    OperativeSketchRecognitionKind.triangle,
    OperativeSketchRecognitionKind.square,
    OperativeSketchRecognitionKind.rhombus,
    OperativeSketchRecognitionKind.circle,
  ];

  /// Construye un helper sin estado que puede reutilizarse en cada escaneo.
  const OperativeSketchRecognitionHelper();

  /// Convierte los trazos del lienzo en regiones cerradas y resume la familia dominante.
  OperativeSketchRecognitionResult scan({
    required Iterable<List<Offset>> strokes,
    required Size canvasSize,
  }) {
    if (canvasSize.isEmpty) {
      return const OperativeSketchRecognitionResult(
        kind: OperativeSketchRecognitionKind.none,
        count: 0,
        matches: <OperativeSketchRecognitionMatch>[],
      );
    }

    final sanitizedStrokes = strokes
        .map(_sanitizeStroke)
        .where((stroke) => stroke.length >= 2)
        .toList(growable: false);
    if (sanitizedStrokes.isEmpty) {
      return const OperativeSketchRecognitionResult(
        kind: OperativeSketchRecognitionKind.none,
        count: 0,
        matches: <OperativeSketchRecognitionMatch>[],
      );
    }

    final rasterGrid = _SketchRasterGrid.fromStrokes(
      strokes: sanitizedStrokes,
      canvasSize: canvasSize,
      resolution: _gridResolution,
    );
    final regions = _extractClosedRegions(rasterGrid);
    if (regions.isEmpty) {
      return const OperativeSketchRecognitionResult(
        kind: OperativeSketchRecognitionKind.none,
        count: 0,
        matches: <OperativeSketchRecognitionMatch>[],
      );
    }

    final counts = <OperativeSketchRecognitionKind, int>{
      for (final kind in _priorityOrder) kind: 0,
    };

    for (final region in regions) {
      final kind = _classifyRegion(region, rasterGrid);
      if (kind == OperativeSketchRecognitionKind.none) continue;
      counts[kind] = counts[kind]! + 1;
    }

    final dominantKind = _pickDominantKind(counts);
    final matches = _priorityOrder
        .where((kind) => (counts[kind] ?? 0) > 0)
        .map(
          (kind) => OperativeSketchRecognitionMatch(
            kind: kind,
            count: counts[kind] ?? 0,
          ),
        )
        .toList(growable: false);
    return OperativeSketchRecognitionResult(
      kind: dominantKind,
      count: counts[dominantKind] ?? 0,
      matches: matches,
    );
  }

  /// Filtra puntos casi duplicados para estabilizar el analisis de un mismo trazo.
  List<Offset> _sanitizeStroke(List<Offset> points) {
    if (points.length < 2) return List<Offset>.from(points);

    final sanitized = <Offset>[points.first];
    for (int index = 1; index < points.length; index++) {
      final currentPoint = points[index];
      if ((currentPoint - sanitized.last).distance >= 3.5) {
        sanitized.add(currentPoint);
      }
    }
    return sanitized;
  }

  /// Escoge la familia con mas apariciones, rompiendo empates por prioridad fija.
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

  /// Localiza las regiones vacias que han quedado cerradas por los trazos del usuario.
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

  /// Marca como exterior todo lo que conecte con el borde del canvas rasterizado.
  void _markOutsideRegion(_SketchRasterGrid grid, List<bool> outside) {
    final queue = <int>[];
    int head = 0;

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

  /// Agrupa todas las celdas conectadas que pertenecen a una misma region interior.
  List<int> _collectRegionCells({
    required _SketchRasterGrid grid,
    required List<bool> visited,
    required int startX,
    required int startY,
  }) {
    final cells = <int>[];
    final queue = <int>[grid.index(startX, startY)];
    int head = 0;
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

  /// Clasifica una region cerrada analizando su contorno y su densidad interior.
  OperativeSketchRecognitionKind _classifyRegion(
    _SketchRegion region,
    _SketchRasterGrid grid,
  ) {
    final borderPoints = _buildRegionBorderPoints(region, grid);
    if (borderPoints.length < 9) {
      return OperativeSketchRecognitionKind.none;
    }

    final hull = _computeConvexHull(borderPoints);
    if (hull.length < 3) {
      return OperativeSketchRecognitionKind.none;
    }

    final hullBounds = _computeBounds(hull);
    final shortestHullSide =
        min(hullBounds.width, hullBounds.height).toDouble();
    if (shortestHullSide < 8 || hullBounds.width < 8 || hullBounds.height < 8) {
      return OperativeSketchRecognitionKind.none;
    }

    final hullArea = _polygonArea(hull).abs();
    if (hullArea < 40) {
      return OperativeSketchRecognitionKind.none;
    }

    final regionArea = region.cells.length.toDouble();
    final epsilonCandidates = <double>[
      max(1.2, shortestHullSide * 0.06).toDouble(),
      max(1.8, shortestHullSide * 0.08).toDouble(),
      max(2.4, shortestHullSide * 0.1).toDouble(),
      max(3.0, shortestHullSide * 0.12).toDouble(),
    ];

    for (final epsilon in epsilonCandidates) {
      final simplifiedHull = _simplifyClosedPolygon(hull, epsilon);
      final corners = _deduplicatePolygonVertices(simplifiedHull);

      if (corners.length == 3 &&
          _passesTriangleGeometry(
            corners: corners,
            hullBounds: hullBounds,
            hullArea: hullArea,
            regionArea: regionArea,
          )) {
        return OperativeSketchRecognitionKind.triangle;
      }

      if (corners.length == 4) {
        final quadrilateralKind = _classifyQuadrilateral(
          corners: corners,
          hullBounds: hullBounds,
          hullArea: hullArea,
          regionArea: regionArea,
        );
        if (quadrilateralKind != OperativeSketchRecognitionKind.none) {
          return quadrilateralKind;
        }
      }
    }

    if (_matchesCircleGeometry(
      borderPoints: borderPoints,
      hull: hull,
      hullBounds: hullBounds,
      hullArea: hullArea,
      regionArea: regionArea,
    )) {
      return OperativeSketchRecognitionKind.circle;
    }

    return OperativeSketchRecognitionKind.none;
  }

  /// Extrae puntos frontera de la region para reconstruir su silueta aproximada.
  List<Offset> _buildRegionBorderPoints(
    _SketchRegion region,
    _SketchRasterGrid grid,
  ) {
    final regionSet = region.cellSet;
    final borderPoints = <Offset>[];

    for (final cellIndex in region.cells) {
      final x = cellIndex % grid.width;
      final y = cellIndex ~/ grid.width;
      var isBorderCell = false;

      for (final offset in _orthogonalNeighbors) {
        final nextX = x + offset.dx.toInt();
        final nextY = y + offset.dy.toInt();
        if (!grid.inBounds(nextX, nextY) ||
            !regionSet.contains(grid.index(nextX, nextY))) {
          isBorderCell = true;
          break;
        }
      }

      if (isBorderCell) {
        borderPoints.add(Offset(x + 0.5, y + 0.5));
      }
    }

    return borderPoints;
  }

  /// Calcula la envolvente convexa para ignorar pequenas irregularidades del raster.
  List<Offset> _computeConvexHull(List<Offset> points) {
    if (points.length <= 3) return List<Offset>.from(points);

    final sortedPoints = List<Offset>.from(points)
      ..sort((left, right) {
        final xComparison = left.dx.compareTo(right.dx);
        return xComparison != 0 ? xComparison : left.dy.compareTo(right.dy);
      });

    final lowerHull = <Offset>[];
    for (final point in sortedPoints) {
      while (lowerHull.length >= 2 &&
          _cross(lowerHull[lowerHull.length - 2], lowerHull.last, point) <= 0) {
        lowerHull.removeLast();
      }
      lowerHull.add(point);
    }

    final upperHull = <Offset>[];
    for (final point in sortedPoints.reversed) {
      while (upperHull.length >= 2 &&
          _cross(upperHull[upperHull.length - 2], upperHull.last, point) <= 0) {
        upperHull.removeLast();
      }
      upperHull.add(point);
    }

    return <Offset>[
      ...lowerHull.take(lowerHull.length - 1),
      ...upperHull.take(upperHull.length - 1),
    ];
  }

  /// Simplifica un poligono cerrado para convertir su contorno en esquinas principales.
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

  /// Reduce una polilinea hasta sus puntos significativos con Douglas-Peucker.
  List<Offset> _simplifyWithDouglasPeucker(
      List<Offset> points, double epsilon) {
    if (points.length < 3) return List<Offset>.from(points);

    double maxDistance = 0;
    int splitIndex = 0;
    final startPoint = points.first;
    final endPoint = points.last;

    for (int index = 1; index < points.length - 1; index++) {
      final distance = _distanceToSegment(points[index], startPoint, endPoint);
      if (distance > maxDistance) {
        maxDistance = distance;
        splitIndex = index;
      }
    }

    if (maxDistance <= epsilon) {
      return <Offset>[startPoint, endPoint];
    }

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

  /// Limpia vertices muy cercanos o practicamente colineales tras la simplificacion.
  List<Offset> _deduplicatePolygonVertices(List<Offset> polygon) {
    if (polygon.isEmpty) return const <Offset>[];

    final deduplicated = <Offset>[];
    for (final point in polygon) {
      if (deduplicated.isEmpty || (point - deduplicated.last).distance >= 1.6) {
        deduplicated.add(point);
      }
    }
    if (deduplicated.length >= 2 &&
        (deduplicated.first - deduplicated.last).distance < 1.6) {
      deduplicated.removeLast();
    }

    var index = 0;
    while (index < deduplicated.length && deduplicated.length > 3) {
      final previous =
          deduplicated[(index - 1 + deduplicated.length) % deduplicated.length];
      final current = deduplicated[index];
      final next = deduplicated[(index + 1) % deduplicated.length];

      if (_distanceToSegment(current, previous, next) <= 0.9) {
        deduplicated.removeAt(index);
        continue;
      }
      index++;
    }

    return deduplicated;
  }

  /// Valida lados, angulos y densidad para distinguir triangulos de otras regiones.
  bool _passesTriangleGeometry({
    required List<Offset> corners,
    required Rect hullBounds,
    required double hullArea,
    required double regionArea,
  }) {
    final sideLengths = <double>[
      (corners[0] - corners[1]).distance,
      (corners[1] - corners[2]).distance,
      (corners[2] - corners[0]).distance,
    ]..sort();

    if (sideLengths.first < 6) return false;
    if (sideLengths.first / sideLengths.last < 0.34) return false;

    final triangleArea = _polygonArea(corners).abs();
    if (triangleArea < 32) return false;

    final triangleCoverage = triangleArea /
        max(1.0, hullBounds.width * hullBounds.height).toDouble();
    if (triangleCoverage < 0.22) return false;

    final hullMatch = triangleArea / hullArea;
    if (hullMatch < 0.78 || hullMatch > 1.14) return false;

    final fillRatio = regionArea / triangleArea;
    if (fillRatio < 0.56 || fillRatio > 1.38) return false;

    final angles = _polygonAngles(corners);
    return angles.every((angle) => angle >= 18 && angle <= 144);
  }

  /// Decide si un cuadrilatero se acerca mas a un cuadrado, un rombo o a nada.
  OperativeSketchRecognitionKind _classifyQuadrilateral({
    required List<Offset> corners,
    required Rect hullBounds,
    required double hullArea,
    required double regionArea,
  }) {
    final sideLengths = <double>[
      (corners[0] - corners[1]).distance,
      (corners[1] - corners[2]).distance,
      (corners[2] - corners[3]).distance,
      (corners[3] - corners[0]).distance,
    ]..sort();

    final sideUniformity = sideLengths.first / sideLengths.last;
    if (sideLengths.first < 5.5 || sideUniformity < 0.68) {
      return OperativeSketchRecognitionKind.none;
    }

    final quadrilateralArea = _polygonArea(corners).abs();
    if (quadrilateralArea < 34) {
      return OperativeSketchRecognitionKind.none;
    }

    final hullCoverage = quadrilateralArea / max(1.0, hullArea).toDouble();
    if (hullCoverage < 0.8 || hullCoverage > 1.16) {
      return OperativeSketchRecognitionKind.none;
    }

    final fillRatio = regionArea / quadrilateralArea;
    if (fillRatio < 0.58 || fillRatio > 1.4) {
      return OperativeSketchRecognitionKind.none;
    }

    final angles = _polygonAngles(corners);
    if (angles.any((angle) => angle < 24 || angle > 156)) {
      return OperativeSketchRecognitionKind.none;
    }

    final shapeCoverage = quadrilateralArea /
        max(1.0, hullBounds.width * hullBounds.height).toDouble();
    if (shapeCoverage < 0.32) {
      return OperativeSketchRecognitionKind.none;
    }

    final edgeDirections = <double>[
      _edgeDirection(corners[0], corners[1]),
      _edgeDirection(corners[1], corners[2]),
      _edgeDirection(corners[2], corners[3]),
      _edgeDirection(corners[3], corners[0]),
    ];
    final oppositeEdgeParallelism = max(
      _axisAngleDifference(edgeDirections[0], edgeDirections[2]),
      _axisAngleDifference(edgeDirections[1], edgeDirections[3]),
    );
    final rightAngleDeviation =
        angles.map((angle) => (angle - 90).abs()).reduce(max);
    final diagonalLengths = <double>[
      (corners[0] - corners[2]).distance,
      (corners[1] - corners[3]).distance,
    ]..sort();
    final diagonalRatio = diagonalLengths.first / diagonalLengths.last;
    final oppositeSideRatioA = min(
          (corners[0] - corners[1]).distance,
          (corners[2] - corners[3]).distance,
        ) /
        max(
          (corners[0] - corners[1]).distance,
          (corners[2] - corners[3]).distance,
        );
    final oppositeSideRatioB = min(
          (corners[1] - corners[2]).distance,
          (corners[3] - corners[0]).distance,
        ) /
        max(
          (corners[1] - corners[2]).distance,
          (corners[3] - corners[0]).distance,
        );

    if (sideUniformity >= 0.72 &&
        rightAngleDeviation <= 24 &&
        oppositeEdgeParallelism <= 18 &&
        diagonalRatio >= 0.8) {
      return OperativeSketchRecognitionKind.square;
    }

    final oppositeAngleSimilarity = max(
      (angles[0] - angles[2]).abs(),
      (angles[1] - angles[3]).abs(),
    );
    final hasAcuteAndObtuseAngles =
        angles.any((angle) => angle < 78) && angles.any((angle) => angle > 102);

    if ((sideUniformity >= 0.56 ||
            (oppositeSideRatioA >= 0.72 && oppositeSideRatioB >= 0.72)) &&
        oppositeAngleSimilarity <= 24 &&
        hasAcuteAndObtuseAngles &&
        rightAngleDeviation >= 8 &&
        rightAngleDeviation <= 68 &&
        diagonalRatio <= 0.98 &&
        oppositeEdgeParallelism <= 24) {
      return OperativeSketchRecognitionKind.rhombus;
    }

    return OperativeSketchRecognitionKind.none;
  }

  /// Comprueba circularidad, simetria radial y densidad para detectar circulos.
  bool _matchesCircleGeometry({
    required List<Offset> borderPoints,
    required List<Offset> hull,
    required Rect hullBounds,
    required double hullArea,
    required double regionArea,
  }) {
    if (borderPoints.length < 8) return false;

    final hullPerimeter = _polygonPerimeter(hull);
    if (hullPerimeter <= 0) return false;

    final circularity = (4 * pi * hullArea) / (hullPerimeter * hullPerimeter);
    if (circularity < 0.56) return false;

    final aspectRatio = hullBounds.width / hullBounds.height;
    if (aspectRatio < 0.38 || aspectRatio > 2.15) return false;

    final circleProxyCorners = _deduplicatePolygonVertices(
      _simplifyClosedPolygon(
        hull,
        max(3.4, min(hullBounds.width, hullBounds.height) * 0.12).toDouble(),
      ),
    );
    if (circleProxyCorners.length < 4) return false;

    final center = hullBounds.center;
    final distances = borderPoints
        .map((point) => (point - center).distance)
        .where((distance) => distance > 0)
        .toList(growable: false);
    if (distances.length < 8) return false;

    final meanRadius =
        distances.reduce((sum, distance) => sum + distance) / distances.length;
    if (meanRadius <= 0) return false;

    final variance = distances
            .map((distance) => pow(distance - meanRadius, 2).toDouble())
            .reduce((sum, value) => sum + value) /
        distances.length;
    final normalizedDeviation = sqrt(variance) / meanRadius;
    if (normalizedDeviation > 0.46) return false;

    final expectedCircleArea = pi * meanRadius * meanRadius;
    final fillRatio = regionArea / expectedCircleArea;
    return fillRatio >= 0.28 && fillRatio <= 1.82;
  }

  /// Devuelve todos los angulos interiores de un poligono ordenado.
  List<double> _polygonAngles(List<Offset> polygon) {
    return List<double>.generate(polygon.length, (index) {
      final previous = polygon[(index - 1 + polygon.length) % polygon.length];
      final current = polygon[index];
      final next = polygon[(index + 1) % polygon.length];
      return _angleAt(previous, current, next);
    });
  }

  /// Mide el angulo interior alrededor de una esquina concreta del candidato.
  double _angleAt(Offset previous, Offset vertex, Offset next) {
    final vectorA = previous - vertex;
    final vectorB = next - vertex;
    final magnitudeProduct = vectorA.distance * vectorB.distance;
    if (magnitudeProduct == 0) return 0;

    final cosine = (((vectorA.dx * vectorB.dx) + (vectorA.dy * vectorB.dy)) /
            magnitudeProduct)
        .clamp(-1.0, 1.0)
        .toDouble();
    return acos(cosine) * (180 / pi);
  }

  /// Calcula el rectangulo contenedor minimo de una lista de puntos.
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

  /// Suma el perimetro de un poligono ya ordenado.
  double _polygonPerimeter(List<Offset> polygon) {
    double perimeter = 0;
    for (int index = 0; index < polygon.length; index++) {
      final current = polygon[index];
      final next = polygon[(index + 1) % polygon.length];
      perimeter += (next - current).distance;
    }
    return perimeter;
  }

  /// Calcula la distancia de un punto a un segmento para simplificar contornos.
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

  /// Calcula el area orientada del poligono para medir la superficie encerrada.
  double _polygonArea(List<Offset> polygon) {
    double area = 0;
    for (int index = 0; index < polygon.length; index++) {
      final current = polygon[index];
      final next = polygon[(index + 1) % polygon.length];
      area += (current.dx * next.dy) - (next.dx * current.dy);
    }
    return area / 2;
  }

  /// Devuelve el producto cruzado necesario para construir la envolvente convexa.
  double _cross(Offset origin, Offset middle, Offset end) {
    return ((middle.dx - origin.dx) * (end.dy - origin.dy)) -
        ((middle.dy - origin.dy) * (end.dx - origin.dx));
  }

  /// Normaliza la direccion de un lado para comparar paralelismo entre aristas opuestas.
  double _edgeDirection(Offset start, Offset end) {
    final angle = atan2(end.dy - start.dy, end.dx - start.dx) * (180 / pi);
    final normalizedAngle = angle % 180;
    return normalizedAngle < 0 ? normalizedAngle + 180 : normalizedAngle;
  }

  /// Calcula la diferencia angular minima entre dos ejes cuando el signo no importa.
  double _axisAngleDifference(double first, double second) {
    final rawDifference = (first - second).abs() % 180;
    return rawDifference > 90 ? 180 - rawDifference : rawDifference;
  }

  /// Vecinos ortogonales usados para separar regiones sin fugas diagonales.
  static const List<Offset> _orthogonalNeighbors = <Offset>[
    Offset(1, 0),
    Offset(-1, 0),
    Offset(0, 1),
    Offset(0, -1),
  ];
}

/// Rejilla binaria del lienzo donde los trazos actuan como paredes entre regiones.
class _SketchRasterGrid {
  final int width;
  final int height;
  final List<bool> blocked;

  /// Construye una rejilla ya rasterizada lista para flood fill y analisis de formas.
  const _SketchRasterGrid({
    required this.width,
    required this.height,
    required this.blocked,
  });

  /// Rasteriza todos los trazos sobre una rejilla cuadrada de resolucion fija.
  factory _SketchRasterGrid.fromStrokes({
    required List<List<Offset>> strokes,
    required Size canvasSize,
    required int resolution,
  }) {
    final blocked = List<bool>.filled(resolution * resolution, false);
    final cellSize = canvasSize.width / resolution;
    final brushRadius = max(1, (6 / cellSize).ceil());

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

  /// Devuelve el numero total de celdas disponibles en la rejilla.
  int get cellCount => width * height;

  /// Convierte coordenadas enteras a indice lineal para listas compactas.
  int index(int x, int y) => (y * width) + x;

  /// Indica si unas coordenadas caen dentro de la rejilla rasterizada.
  bool inBounds(int x, int y) {
    return x >= 0 && y >= 0 && x < width && y < height;
  }

  /// Traduce una coordenada real del lienzo a una celda de la rejilla.
  Offset _pointToCell(Offset point, Size canvasSize) {
    final x = ((point.dx / canvasSize.width) * (width - 1))
        .round()
        .clamp(0, width - 1);
    final y = ((point.dy / canvasSize.height) * (height - 1))
        .round()
        .clamp(0, height - 1);
    return Offset(x.toDouble(), y.toDouble());
  }

  /// Marca un pequeno disco de celdas bloqueadas para dar grosor a cada segmento.
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

  /// Cierra microhuecos entre trazos para que lados compartidos o casi conectados formen paredes validas.
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

  /// Cuenta vecinos bloqueados alrededor de una celda para detectar juntas casi cerradas.
  int _blockedNeighborCount(int x, int y) {
    var count = 0;
    for (int offsetY = -1; offsetY <= 1; offsetY++) {
      for (int offsetX = -1; offsetX <= 1; offsetX++) {
        if (offsetX == 0 && offsetY == 0) continue;
        if (blocked[index(x + offsetX, y + offsetY)]) {
          count++;
        }
      }
    }
    return count;
  }
}

/// Region cerrada del lienzo representada como las celdas interiores que la forman.
class _SketchRegion {
  final List<int> cells;
  final Set<int> cellSet;

  /// Construye una region interior y precalcula su set para consultas rapidas.
  _SketchRegion({
    required this.cells,
  }) : cellSet = cells.toSet();
}
