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

  /// Resume cuantas figuras reconocibles se han detectado en total.
  int get totalCount {
    return matches.fold<int>(
      0,
      (sum, match) => sum + match.count,
    );
  }

  /// Devuelve la secuencia de textos que el overlay mostrara uno detras de otro.
  List<String> get displayLabels {
    return matches.map((match) => match.displayLabel).toList(growable: false);
  }
}

/// Helper que rasteriza el dibujo, separa regiones cerradas y clasifica su silueta.
class OperativeSketchRecognitionHelper {
  static const int _gridResolution = 96;
  static const int _minimumRegionCellCount = 6;
  static const double _minimumStrokeClosureDistance = 10;
  static const double _strokeClosureDistanceFactor = 0.22;
  static const double _minimumRecognizableHullSide = 6;
  static const double _minimumRecognizableArea = 20;
  static const int _inscribedFitIterations = 16;
  static const int _circleFitSampleCount = 24;
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
      return _emptyResult;
    }

    final sanitizedStrokes = strokes
        .map(_sanitizeStroke)
        .where((stroke) => stroke.length >= 2)
        .toList(growable: false);
    if (sanitizedStrokes.isEmpty) {
      return _emptyResult;
    }

    final regionDetections = _scanClosedRegions(
      strokes: sanitizedStrokes,
      canvasSize: canvasSize,
    );
    final strokeDetections = _scanClosedStrokes(sanitizedStrokes);
    final mergedDetections = _mergeDetections(
      primaryDetections: regionDetections,
      secondaryDetections: strokeDetections,
    );
    final combinedCounts = _countDetections(mergedDetections);

    return _resultFromCounts(combinedCounts);
  }

  /// Devuelve el mapa vacio reutilizable para acumular coincidencias por tipo.
  Map<OperativeSketchRecognitionKind, int> _emptyCounts() {
    return <OperativeSketchRecognitionKind, int>{
      for (final kind in _priorityOrder) kind: 0,
    };
  }

  /// Devuelve un resultado vacio comun cuando no hay ninguna forma reconocible.
  static const OperativeSketchRecognitionResult _emptyResult =
      OperativeSketchRecognitionResult(
    kind: OperativeSketchRecognitionKind.none,
    count: 0,
    matches: <OperativeSketchRecognitionMatch>[],
  );

  /// Convierte un mapa de contadores en el resultado publico que consume la UI.
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
    if (matches.isEmpty) {
      return _emptyResult;
    }

    final dominantKind = _pickDominantKind(counts);
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

  /// Ejecuta el recognizer tradicional basado en regiones cerradas rasterizadas.
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
    if (regions.isEmpty) {
      return detections;
    }

    for (final region in regions) {
      final kind = _classifyRegion(region, rasterGrid);
      if (kind == OperativeSketchRecognitionKind.none) continue;
      final detection = _buildRegionDetection(
        region: region,
        grid: rasterGrid,
        kind: kind,
      );
      if (detection != null) {
        detections.add(detection);
      }
    }

    return detections;
  }

  /// Escanea cada trazo cerrado como contorno independiente para detectar formas tocandose.
  List<_SketchRecognitionDetection> _scanClosedStrokes(
    List<List<Offset>> strokes,
  ) {
    final detections = <_SketchRecognitionDetection>[];

    for (final stroke in strokes) {
      final kind = _classifyClosedStroke(stroke);
      if (kind == OperativeSketchRecognitionKind.none) continue;
      final detection = _buildStrokeDetection(stroke: stroke, kind: kind);
      if (detection != null) {
        detections.add(detection);
      }
    }

    return detections;
  }

  /// Convierte una region valida en una deteccion geometrica util para fusionar resultados.
  _SketchRecognitionDetection? _buildRegionDetection({
    required _SketchRegion region,
    required _SketchRasterGrid grid,
    required OperativeSketchRecognitionKind kind,
  }) {
    final borderPoints = _buildRegionBorderPoints(region, grid);
    if (borderPoints.length < 3) return null;

    final hull = _computeConvexHull(borderPoints);
    return _buildDetectionFromHull(
      kind: kind,
      hull: hull,
      source: _SketchRecognitionSource.region,
    );
  }

  /// Convierte un trazo valido en una deteccion geometrica util para fusionar resultados.
  _SketchRecognitionDetection? _buildStrokeDetection({
    required List<Offset> stroke,
    required OperativeSketchRecognitionKind kind,
  }) {
    final hull = _computeConvexHull(stroke);
    return _buildDetectionFromHull(
      kind: kind,
      hull: hull,
      source: _SketchRecognitionSource.stroke,
    );
  }

  /// Empaqueta la geometria minima necesaria para decidir si dos lecturas son la misma figura.
  _SketchRecognitionDetection? _buildDetectionFromHull({
    required OperativeSketchRecognitionKind kind,
    required List<Offset> hull,
    required _SketchRecognitionSource source,
  }) {
    if (kind == OperativeSketchRecognitionKind.none || hull.length < 3) {
      return null;
    }

    final bounds = _computeBounds(hull);
    final area = _polygonArea(hull).abs();
    if (area <= 0 || bounds.width <= 0 || bounds.height <= 0) {
      return null;
    }

    return _SketchRecognitionDetection(
      kind: kind,
      source: source,
      bounds: bounds,
      area: area,
      center: _computePolygonCentroid(hull),
    );
  }

  /// Fusiona region y trazo, descartando detecciones que representan la misma figura.
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
        continue;
      }

      merged[duplicateIndex] = _pickPreferredDetection(
        merged[duplicateIndex],
        candidate,
      );
    }

    return merged;
  }

  /// Traduce la lista final de detecciones en el mapa compacto que consume la UI.
  Map<OperativeSketchRecognitionKind, int> _countDetections(
    List<_SketchRecognitionDetection> detections,
  ) {
    final counts = _emptyCounts();
    for (final detection in detections) {
      counts[detection.kind] = counts[detection.kind]! + 1;
    }
    return counts;
  }

  /// Decide si dos lecturas vienen probablemente de la misma forma dibujada.
  bool _areDuplicateDetections(
    _SketchRecognitionDetection first,
    _SketchRecognitionDetection second,
  ) {
    final intersectionArea = _rectIntersectionArea(first.bounds, second.bounds);
    if (intersectionArea <= 0) return false;

    final overlapRatio = intersectionArea /
        max(1.0, min(_rectArea(first.bounds), _rectArea(second.bounds)));
    final areaRatio = min(first.area, second.area) / max(first.area, second.area);
    final centerDistance = (first.center - second.center).distance;
    final minDiagonal =
        min(_rectDiagonal(first.bounds), _rectDiagonal(second.bounds));
    final sameKind = first.kind == second.kind;
    final bothCircles = sameKind &&
        first.kind == OperativeSketchRecognitionKind.circle &&
        second.kind == OperativeSketchRecognitionKind.circle;

    if (overlapRatio < (bothCircles ? 0.34 : (sameKind ? 0.52 : 0.72))) {
      return false;
    }
    if (areaRatio < (bothCircles ? 0.22 : (sameKind ? 0.44 : 0.62))) {
      return false;
    }
    if (centerDistance >
        max(bothCircles ? 9.0 : 6.0, minDiagonal * (bothCircles ? 0.42 : 0.32))) {
      return false;
    }

    return true;
  }

  /// Elige cual de las dos lecturas superpuestas es mas fiable para conservarla.
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

  /// Prioriza poligonos sobre circulos y regiones sobre trazos cuando hay empate.
  int _duplicatePreferenceScore(_SketchRecognitionDetection detection) {
    final sourceScore =
        detection.source == _SketchRecognitionSource.region ? 4 : 0;
    switch (detection.kind) {
      case OperativeSketchRecognitionKind.none:
        return sourceScore;
      case OperativeSketchRecognitionKind.circle:
        return 18 + sourceScore;
      case OperativeSketchRecognitionKind.rhombus:
        return 28 + sourceScore;
      case OperativeSketchRecognitionKind.triangle:
      case OperativeSketchRecognitionKind.square:
        return 30 + sourceScore;
    }
  }

  /// Calcula el area de solape entre dos rectangulos para medir duplicados.
  double _rectIntersectionArea(Rect first, Rect second) {
    final overlap = first.intersect(second);
    if (overlap.width <= 0 || overlap.height <= 0) return 0;
    return overlap.width * overlap.height;
  }

  /// Devuelve el area de un rectangulo para normalizar el solape.
  double _rectArea(Rect rect) => rect.width * rect.height;

  /// Calcula la diagonal del rectangulo para comparar distancias entre centros.
  double _rectDiagonal(Rect rect) {
    return sqrt((rect.width * rect.width) + (rect.height * rect.height))
        .toDouble();
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
    if (borderPoints.length < 6) {
      return OperativeSketchRecognitionKind.none;
    }

    final hull = _computeConvexHull(borderPoints);
    if (hull.length < 3) {
      return OperativeSketchRecognitionKind.none;
    }

    final hullBounds = _computeBounds(hull);
    final shortestHullSide =
        min(hullBounds.width, hullBounds.height).toDouble();
    if (shortestHullSide < _minimumRecognizableHullSide ||
        hullBounds.width < _minimumRecognizableHullSide ||
        hullBounds.height < _minimumRecognizableHullSide) {
      return OperativeSketchRecognitionKind.none;
    }

    final hullArea = _polygonArea(hull).abs();
    if (hullArea < _minimumRecognizableArea) {
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

    final fittedKind = _classifyByLargestFittedShape(
      hull: hull,
      hullBounds: hullBounds,
      hullArea: hullArea,
    );
    if (fittedKind != OperativeSketchRecognitionKind.none) {
      return fittedKind;
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

  /// Clasifica un unico trazo cerrado sin depender de que exista una region interior separable.
  OperativeSketchRecognitionKind _classifyClosedStroke(List<Offset> stroke) {
    if (stroke.length < 4) {
      return OperativeSketchRecognitionKind.none;
    }

    final strokeBounds = _computeBounds(stroke);
    final shortestStrokeSide =
        min(strokeBounds.width, strokeBounds.height).toDouble();
    if (shortestStrokeSide < _minimumRecognizableHullSide ||
        strokeBounds.width < _minimumRecognizableHullSide ||
        strokeBounds.height < _minimumRecognizableHullSide) {
      return OperativeSketchRecognitionKind.none;
    }

    final closureThreshold = max(
      _minimumStrokeClosureDistance,
      shortestStrokeSide * _strokeClosureDistanceFactor,
    ).toDouble();
    if ((stroke.first - stroke.last).distance > closureThreshold) {
      return OperativeSketchRecognitionKind.none;
    }

    final hull = _computeConvexHull(stroke);
    if (hull.length < 3) {
      return OperativeSketchRecognitionKind.none;
    }

    final hullBounds = _computeBounds(hull);
    final shortestHullSide =
        min(hullBounds.width, hullBounds.height).toDouble();
    if (shortestHullSide < _minimumRecognizableHullSide ||
        hullBounds.width < _minimumRecognizableHullSide ||
        hullBounds.height < _minimumRecognizableHullSide) {
      return OperativeSketchRecognitionKind.none;
    }

    final hullArea = _polygonArea(hull).abs();
    if (hullArea < _minimumRecognizableArea) {
      return OperativeSketchRecognitionKind.none;
    }

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
            regionArea: hullArea,
          )) {
        return OperativeSketchRecognitionKind.triangle;
      }

      if (corners.length == 4) {
        final quadrilateralKind = _classifyQuadrilateral(
          corners: corners,
          hullBounds: hullBounds,
          hullArea: hullArea,
          regionArea: hullArea,
        );
        if (quadrilateralKind != OperativeSketchRecognitionKind.none) {
          return quadrilateralKind;
        }
      }
    }

    final fittedKind = _classifyByLargestFittedShape(
      hull: hull,
      hullBounds: hullBounds,
      hullArea: hullArea,
    );
    if (fittedKind != OperativeSketchRecognitionKind.none) {
      return fittedKind;
    }

    if (_matchesCircleGeometry(
      borderPoints: stroke,
      hull: hull,
      hullBounds: hullBounds,
      hullArea: hullArea,
      regionArea: hullArea,
    )) {
      return OperativeSketchRecognitionKind.circle;
    }

    return OperativeSketchRecognitionKind.none;
  }

  /// Busca la forma ideal mas grande que puede inscribirse dentro de la silueta.
  OperativeSketchRecognitionKind _classifyByLargestFittedShape({
    required List<Offset> hull,
    required Rect hullBounds,
    required double hullArea,
  }) {
    if (hull.length < 3 || hullArea <= 0) {
      return OperativeSketchRecognitionKind.none;
    }

    final candidates = <_SketchInscribedFit>[
      _findLargestInscribedFit(
        kind: OperativeSketchRecognitionKind.triangle,
        hull: hull,
        hullBounds: hullBounds,
        hullArea: hullArea,
      ),
      _findLargestInscribedFit(
        kind: OperativeSketchRecognitionKind.square,
        hull: hull,
        hullBounds: hullBounds,
        hullArea: hullArea,
      ),
      _findLargestInscribedFit(
        kind: OperativeSketchRecognitionKind.circle,
        hull: hull,
        hullBounds: hullBounds,
        hullArea: hullArea,
      ),
    ]..sort((left, right) => right.area.compareTo(left.area));

    final bestFit = candidates.firstWhere(
      (candidate) => candidate.area > 0,
      orElse: () => const _SketchInscribedFit(
        kind: OperativeSketchRecognitionKind.none,
        area: 0,
        coverage: 0,
      ),
    );
    if (bestFit.kind == OperativeSketchRecognitionKind.none ||
        !_passesInscribedFitThreshold(bestFit, hullBounds)) {
      return OperativeSketchRecognitionKind.none;
    }

    return bestFit.kind;
  }

  /// Encuentra el candidato inscrito de mayor area para una familia concreta.
  _SketchInscribedFit _findLargestInscribedFit({
    required OperativeSketchRecognitionKind kind,
    required List<Offset> hull,
    required Rect hullBounds,
    required double hullArea,
  }) {
    if (kind == OperativeSketchRecognitionKind.none ||
        kind == OperativeSketchRecognitionKind.rhombus) {
      return const _SketchInscribedFit(
        kind: OperativeSketchRecognitionKind.none,
        area: 0,
        coverage: 0,
      );
    }

    final candidateCenters = _buildCandidateFitCenters(hull, hullBounds);
    if (candidateCenters.isEmpty) {
      return const _SketchInscribedFit(
        kind: OperativeSketchRecognitionKind.none,
        area: 0,
        coverage: 0,
      );
    }

    final maxRadius = sqrt(
      (hullBounds.width * hullBounds.width) +
          (hullBounds.height * hullBounds.height),
    ).toDouble();
    final rotations = _fitRotationsFor(kind);
    var bestArea = 0.0;

    for (final center in candidateCenters) {
      if (!_isPointInsideConvexPolygon(center, hull)) continue;

      for (final rotation in rotations) {
        final radius = _findLargestInscribedRadius(
          kind: kind,
          center: center,
          rotation: rotation,
          hull: hull,
          maxRadius: maxRadius,
        );
        if (radius <= 0) continue;

        final area = _shapeAreaFromRadius(kind, radius);
        if (area > bestArea) {
          bestArea = area;
        }
      }
    }

    if (bestArea <= 0) {
      return const _SketchInscribedFit(
        kind: OperativeSketchRecognitionKind.none,
        area: 0,
        coverage: 0,
      );
    }

    return _SketchInscribedFit(
      kind: kind,
      area: bestArea,
      coverage: bestArea / hullArea,
    );
  }

  /// Genera centros cercanos al centroide para compensar dibujos descentrados.
  List<Offset> _buildCandidateFitCenters(
    List<Offset> hull,
    Rect hullBounds,
  ) {
    final polygonCentroid = _computePolygonCentroid(hull);
    final averagePoint = _averagePoint(hull);
    final stepX = max(0.75, hullBounds.width * 0.08).toDouble();
    final stepY = max(0.75, hullBounds.height * 0.08).toDouble();
    final offsets = <Offset>[
      Offset.zero,
      Offset(stepX, 0),
      Offset(-stepX, 0),
      Offset(0, stepY),
      Offset(0, -stepY),
      Offset(stepX, stepY),
      Offset(stepX, -stepY),
      Offset(-stepX, stepY),
      Offset(-stepX, -stepY),
    ];

    final candidateCenters = <Offset>[];
    for (final baseCenter in <Offset>[
      polygonCentroid,
      hullBounds.center,
      averagePoint,
    ]) {
      for (final offset in offsets) {
        final candidate = baseCenter + offset;
        if (_isPointInsideConvexPolygon(candidate, hull)) {
          candidateCenters.add(candidate);
        }
      }
    }

    return _deduplicateOffsets(candidateCenters, minimumDistance: 0.8);
  }

  /// Devuelve las rotaciones que se evaluaran para buscar la mejor forma inscrita.
  List<double> _fitRotationsFor(OperativeSketchRecognitionKind kind) {
    switch (kind) {
      case OperativeSketchRecognitionKind.triangle:
        return List<double>.generate(
          24,
          (index) => index * (pi / 12),
          growable: false,
        );
      case OperativeSketchRecognitionKind.square:
        return List<double>.generate(
          12,
          (index) => index * (pi / 24),
          growable: false,
        );
      case OperativeSketchRecognitionKind.circle:
        return const <double>[0];
      case OperativeSketchRecognitionKind.none:
      case OperativeSketchRecognitionKind.rhombus:
        return const <double>[];
    }
  }

  /// Busca por biseccion el tamano maximo que cabe dentro de la envolvente convexa.
  double _findLargestInscribedRadius({
    required OperativeSketchRecognitionKind kind,
    required Offset center,
    required double rotation,
    required List<Offset> hull,
    required double maxRadius,
  }) {
    var low = 0.0;
    var high = maxRadius;

    for (int iteration = 0;
        iteration < _inscribedFitIterations;
        iteration++) {
      final radius = (low + high) / 2;
      final samplePoints = _buildShapeSamplePoints(
        kind: kind,
        center: center,
        radius: radius,
        rotation: rotation,
      );
      if (_allPointsInsideConvexPolygon(samplePoints, hull)) {
        low = radius;
      } else {
        high = radius;
      }
    }

    return low;
  }

  /// Construye puntos de control suficientes para comprobar si la forma cabe entera.
  List<Offset> _buildShapeSamplePoints({
    required OperativeSketchRecognitionKind kind,
    required Offset center,
    required double radius,
    required double rotation,
  }) {
    switch (kind) {
      case OperativeSketchRecognitionKind.triangle:
        return List<Offset>.generate(3, (index) {
          final angle = rotation - (pi / 2) + (index * ((2 * pi) / 3));
          return Offset(
            center.dx + (cos(angle) * radius),
            center.dy + (sin(angle) * radius),
          );
        }, growable: false);
      case OperativeSketchRecognitionKind.square:
        return List<Offset>.generate(4, (index) {
          final angle = rotation + (pi / 4) + (index * (pi / 2));
          return Offset(
            center.dx + (cos(angle) * radius),
            center.dy + (sin(angle) * radius),
          );
        }, growable: false);
      case OperativeSketchRecognitionKind.circle:
        return List<Offset>.generate(_circleFitSampleCount, (index) {
          final angle = rotation + (index * ((2 * pi) / _circleFitSampleCount));
          return Offset(
            center.dx + (cos(angle) * radius),
            center.dy + (sin(angle) * radius),
          );
        }, growable: false);
      case OperativeSketchRecognitionKind.none:
      case OperativeSketchRecognitionKind.rhombus:
        return const <Offset>[];
    }
  }

  /// Convierte el radio circunscrito comun a un area comparable entre familias.
  double _shapeAreaFromRadius(
    OperativeSketchRecognitionKind kind,
    double radius,
  ) {
    switch (kind) {
      case OperativeSketchRecognitionKind.triangle:
        return (3 * sqrt(3) / 4) * radius * radius;
      case OperativeSketchRecognitionKind.square:
        return 2 * radius * radius;
      case OperativeSketchRecognitionKind.circle:
        return pi * radius * radius;
      case OperativeSketchRecognitionKind.none:
      case OperativeSketchRecognitionKind.rhombus:
        return 0;
    }
  }

  /// Decide si la mejor forma inscrita ocupa suficiente area como para aceptarla.
  bool _passesInscribedFitThreshold(
    _SketchInscribedFit fit,
    Rect hullBounds,
  ) {
    final aspectRatio = hullBounds.width / max(1.0, hullBounds.height);
    switch (fit.kind) {
      case OperativeSketchRecognitionKind.triangle:
        return fit.coverage >= 0.34;
      case OperativeSketchRecognitionKind.square:
        return fit.coverage >= 0.58 &&
            aspectRatio >= 0.62 &&
            aspectRatio <= 1.62;
      case OperativeSketchRecognitionKind.circle:
        return fit.coverage >= 0.52 &&
            aspectRatio >= 0.55 &&
            aspectRatio <= 1.85;
      case OperativeSketchRecognitionKind.none:
      case OperativeSketchRecognitionKind.rhombus:
        return false;
    }
  }

  /// Indica si todos los puntos de control siguen dentro de un poligono convexo.
  bool _allPointsInsideConvexPolygon(
    List<Offset> points,
    List<Offset> polygon,
  ) {
    if (points.isEmpty) return false;
    return points.every((point) => _isPointInsideConvexPolygon(point, polygon));
  }

  /// Comprueba inclusion en una envolvente convexa tolerando puntos sobre el borde.
  bool _isPointInsideConvexPolygon(Offset point, List<Offset> polygon) {
    if (polygon.length < 3) return false;

    int sign = 0;
    for (int index = 0; index < polygon.length; index++) {
      final current = polygon[index];
      final next = polygon[(index + 1) % polygon.length];
      final cross = _cross(current, next, point);
      if (cross.abs() <= 0.12) {
        continue;
      }

      final currentSign = cross > 0 ? 1 : -1;
      if (sign == 0) {
        sign = currentSign;
        continue;
      }
      if (sign != currentSign) {
        return false;
      }
    }

    return true;
  }

  /// Calcula el centroide del poligono o una media de respaldo si el area es minima.
  Offset _computePolygonCentroid(List<Offset> polygon) {
    double signedAreaTwice = 0;
    double centroidX = 0;
    double centroidY = 0;

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

  /// Devuelve la media simple de varios puntos cuando no hace falta ponderacion.
  Offset _averagePoint(List<Offset> points) {
    if (points.isEmpty) return Offset.zero;

    double sumX = 0;
    double sumY = 0;
    for (final point in points) {
      sumX += point.dx;
      sumY += point.dy;
    }

    return Offset(sumX / points.length, sumY / points.length);
  }

  /// Elimina centros casi repetidos para no recalcular la misma solucion.
  List<Offset> _deduplicateOffsets(
    List<Offset> points, {
    required double minimumDistance,
  }) {
    final deduplicated = <Offset>[];
    for (final point in points) {
      final hasNearPoint = deduplicated.any(
        (candidate) => (candidate - point).distance < minimumDistance,
      );
      if (!hasNearPoint) {
        deduplicated.add(point);
      }
    }
    return deduplicated;
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

    if (sideLengths.first < 4.2) return false;
    if (sideLengths.first / sideLengths.last < 0.18) return false;

    final triangleArea = _polygonArea(corners).abs();
    if (triangleArea < 14) return false;

    final triangleCoverage = triangleArea /
        max(1.0, hullBounds.width * hullBounds.height).toDouble();
    if (triangleCoverage < 0.12) return false;

    final hullMatch = triangleArea / hullArea;
    if (hullMatch < 0.6 || hullMatch > 1.34) return false;

    final fillRatio = regionArea / triangleArea;
    if (fillRatio < 0.34 || fillRatio > 1.72) return false;

    final angles = _polygonAngles(corners);
    return angles.every((angle) => angle >= 10 && angle <= 170);
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

/// Indica de donde procede una deteccion para resolver duplicados con preferencia.
enum _SketchRecognitionSource {
  region,
  stroke,
}

/// Representa una figura ya clasificada junto a su huella geometrica.
class _SketchRecognitionDetection {
  final OperativeSketchRecognitionKind kind;
  final _SketchRecognitionSource source;
  final Rect bounds;
  final double area;
  final Offset center;

  const _SketchRecognitionDetection({
    required this.kind,
    required this.source,
    required this.bounds,
    required this.area,
    required this.center,
  });
}

/// Resume una forma perfecta ya inscrita para poder compararla con otras.
class _SketchInscribedFit {
  final OperativeSketchRecognitionKind kind;
  final double area;
  final double coverage;

  const _SketchInscribedFit({
    required this.kind,
    required this.area,
    required this.coverage,
  });
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
