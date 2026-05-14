import 'dart:collection';

import '../_imports.dart';

/// Alterna el comportamiento del gesto entre dibujar y borrar.
enum EndpointSketchToolMode {
  paint,
  erase,
  move,
}

/// Describe un trazo individual del usuario junto al color que se le ha asignado.
class EndpointSketchStroke {
  final int id;
  final Color color;
  final List<Offset> points;

  /// Construye un trazo simple a partir de sus puntos y su color de pincel.
  const EndpointSketchStroke({
    required this.id,
    required this.color,
    required this.points,
  });

  /// Clona el trazo para actualizar su geometria sin perder su identidad.
  EndpointSketchStroke copyWith({
    List<Offset>? points,
  }) {
    return EndpointSketchStroke(
      id: id,
      color: color,
      points: points ?? this.points,
    );
  }
}

/// Representa un punto del ruido de fondo en coordenadas relativas estables.
class EndpointSketchNoiseDot {
  final Offset relativeOffset;
  final double radius;
  final Color color;

  /// Construye un punto de grano con su posicion, tamano y tono ya resueltos.
  const EndpointSketchNoiseDot({
    required this.relativeOffset,
    required this.radius,
    required this.color,
  });
}

/// Centraliza el ciclo de vida de trazos, borrado y paleta de un lienzo manual.
class EndpointSketchCanvasController {
  static const _strokeSelectionRadius = 14.0;
  static const _strokeConnectionRadius = 8.0;
  static const _intersectionEpsilon = 0.0001;

  final double eraserRadius;

  int _nextStrokeId = 0;
  int? _activeStrokeId;
  Offset? _lastDragPosition;
  Color _selectedBrushColor;
  EndpointSketchToolMode _toolMode = EndpointSketchToolMode.paint;
  final List<EndpointSketchStroke> _strokes = <EndpointSketchStroke>[];
  _EndpointSketchMoveSession? _activeMoveSession;
  Set<int> _selectedStrokeIds = const <int>{};

  /// Inicializa el lienzo con un color inicial y el radio del borrador.
  EndpointSketchCanvasController({
    required Color initialBrushColor,
    required this.eraserRadius,
  }) : _selectedBrushColor = initialBrushColor;

  /// Expone los trazos actuales del lienzo.
  List<EndpointSketchStroke> get strokes =>
      List<EndpointSketchStroke>.unmodifiable(_strokes);

  /// Expone solo la geometria actual de los trazos para el clasificador.
  Iterable<List<Offset>> get strokePointLists => _strokes.map(
        (stroke) => stroke.points,
      );

  /// Indica si hay al menos un trazo visible en pantalla.
  bool get hasStrokes => _strokes.isNotEmpty;

  /// Indica si el usuario sigue con un trazo activo.
  bool get hasActiveStroke => _activeStrokeId != null;

  /// Expone el color actualmente seleccionado para pintar.
  Color get selectedBrushColor => _selectedBrushColor;

  /// Expone la herramienta actualmente activa.
  EndpointSketchToolMode get toolMode => _toolMode;

  /// Expone los ids de trazo seleccionados por la herramienta de movimiento.
  Set<int> get selectedStrokeIds => Set<int>.unmodifiable(_selectedStrokeIds);

  /// Indica si hay un arrastre activo de una seleccion levantada.
  bool get hasLiftedSelection => _activeMoveSession != null;

  /// Inicia un trazo nuevo o activa el borrador sobre la posicion inicial.
  bool handlePanStart(Offset position) {
    if (_toolMode == EndpointSketchToolMode.move) {
      return false;
    }
    _lastDragPosition = position;
    if (_toolMode == EndpointSketchToolMode.erase) {
      return _eraseBetween(position, position);
    }

    final stroke = EndpointSketchStroke(
      id: _nextStrokeId++,
      color: _selectedBrushColor,
      points: <Offset>[position],
    );
    _strokes.add(stroke);
    _activeStrokeId = stroke.id;
    return true;
  }

  /// Anade puntos al trazo activo o recorta los trazos atravesados por el borrador.
  bool handlePanUpdate(Offset position) {
    if (_toolMode == EndpointSketchToolMode.move) {
      return false;
    }
    if (_toolMode == EndpointSketchToolMode.erase) {
      final start = _lastDragPosition ?? position;
      final changed = _eraseBetween(start, position);
      _lastDragPosition = position;
      return changed;
    }

    final activeStrokeId = _activeStrokeId;
    if (activeStrokeId == null) return false;

    final strokeIndex = _strokes.indexWhere(
      (stroke) => stroke.id == activeStrokeId,
    );
    if (strokeIndex < 0) return false;

    final activeStroke = _strokes[strokeIndex];
    final updatedPoints = List<Offset>.from(activeStroke.points)..add(position);
    _strokes[strokeIndex] = activeStroke.copyWith(points: updatedPoints);
    return true;
  }

  /// Cierra el gesto activo y deja el lienzo listo para otro trazo.
  bool handlePanEnd() {
    final hadPendingGesture =
        _lastDragPosition != null || _activeStrokeId != null;
    _lastDragPosition = null;
    _activeStrokeId = null;
    return hadPendingGesture;
  }

  /// Limpia manualmente todos los trazos visibles del lienzo.
  bool clear() {
    if (_strokes.isEmpty && _activeStrokeId == null) {
      _lastDragPosition = null;
      _clearMoveSelection();
      return false;
    }

    _strokes.clear();
    _activeStrokeId = null;
    _lastDragPosition = null;
    _clearMoveSelection();
    return true;
  }

  /// Deshace el ultimo trazo completo si existe alguno.
  bool undoLastStroke() {
    if (_strokes.isEmpty) return false;

    _strokes.removeLast();
    _activeStrokeId = null;
    _lastDragPosition = null;
    _clearMoveSelection();
    return true;
  }

  /// Cambia el color del pincel y fuerza el modo pintar si hiciera falta.
  bool selectBrushColor(Color color) {
    if (_selectedBrushColor == color &&
        _toolMode == EndpointSketchToolMode.paint) {
      return false;
    }

    _selectedBrushColor = color;
    setToolMode(EndpointSketchToolMode.paint);
    return true;
  }

  /// Fija de forma explicita la herramienta activa del lienzo.
  bool setToolMode(EndpointSketchToolMode mode) {
    if (_toolMode == mode) {
      return false;
    }

    _toolMode = mode;
    _activeStrokeId = null;
    _lastDragPosition = null;
    _clearMoveSelection();
    return true;
  }

  /// Alterna entre trazar lineas nuevas y borrar las ya existentes.
  bool toggleToolMode() {
    final nextMode = _toolMode == EndpointSketchToolMode.erase
        ? EndpointSketchToolMode.paint
        : EndpointSketchToolMode.erase;
    return setToolMode(nextMode);
  }

  /// Selecciona un trazo conectado a partir de un punto y lo prepara para moverlo.
  bool startMoveSelection(Offset position) {
    if (_toolMode != EndpointSketchToolMode.move || _strokes.isEmpty) {
      return false;
    }

    final selectedStroke = _pickStrokeAt(position);
    if (selectedStroke == null) {
      return _clearMoveSelection();
    }

    final connectedStrokeIds = _connectedStrokeIdsFor(selectedStroke.id);
    if (connectedStrokeIds.isEmpty) {
      return _clearMoveSelection();
    }

    _selectedStrokeIds = connectedStrokeIds;
    _activeMoveSession = _EndpointSketchMoveSession(
      anchor: position,
      originalPointsByStrokeId: <int, List<Offset>>{
        for (final stroke in _strokes)
          if (connectedStrokeIds.contains(stroke.id))
            stroke.id: List<Offset>.unmodifiable(
              List<Offset>.from(stroke.points),
            ),
      },
    );
    return true;
  }

  /// Desplaza la seleccion activa segun la posicion actual del dedo.
  bool updateMoveSelection(Offset position) {
    if (_toolMode != EndpointSketchToolMode.move) {
      return false;
    }

    final moveSession = _activeMoveSession;
    if (moveSession == null) {
      return false;
    }

    final delta = position - moveSession.anchor;
    var didChange = false;
    for (var index = 0; index < _strokes.length; index++) {
      final currentStroke = _strokes[index];
      final originalPoints =
          moveSession.originalPointsByStrokeId[currentStroke.id];
      if (originalPoints == null) continue;

      final shiftedPoints =
          originalPoints.map((point) => point + delta).toList(growable: false);
      if (_arePointListsEqual(currentStroke.points, shiftedPoints)) {
        continue;
      }

      _strokes[index] = currentStroke.copyWith(points: shiftedPoints);
      didChange = true;
    }

    return didChange;
  }

  /// Suelta la seleccion levantada y deja el bloque en su posicion final.
  bool endMoveSelection() {
    return _clearMoveSelection();
  }

  /// Devuelve un clon del bloque conectado tocado en `position`.
  List<EndpointSketchStroke> exportConnectedStrokesAt(Offset position) {
    if (_strokes.isEmpty) {
      return const <EndpointSketchStroke>[];
    }

    final selectedStroke = _pickStrokeAt(position);
    if (selectedStroke == null) {
      return const <EndpointSketchStroke>[];
    }

    final connectedStrokeIds = _connectedStrokeIdsFor(selectedStroke.id);
    if (connectedStrokeIds.isEmpty) {
      return const <EndpointSketchStroke>[];
    }

    return _strokes
        .where((stroke) => connectedStrokeIds.contains(stroke.id))
        .map(
          (stroke) => EndpointSketchStroke(
            id: stroke.id,
            color: stroke.color,
            points: List<Offset>.unmodifiable(List<Offset>.from(stroke.points)),
          ),
        )
        .toList(growable: false);
  }

  /// Inserta un bloque de trazos en el centro del lienzo sin escalar su tamano.
  bool pasteStrokesCentered({
    required List<EndpointSketchStroke> sourceStrokes,
    required Size canvasSize,
  }) {
    if (sourceStrokes.isEmpty || canvasSize.isEmpty) {
      return false;
    }

    final sourcePoints =
        sourceStrokes.expand((stroke) => stroke.points).toList(growable: false);
    if (sourcePoints.isEmpty) {
      return false;
    }

    var minX = sourcePoints.first.dx;
    var maxX = sourcePoints.first.dx;
    var minY = sourcePoints.first.dy;
    var maxY = sourcePoints.first.dy;
    for (final point in sourcePoints.skip(1)) {
      minX = min(minX, point.dx);
      maxX = max(maxX, point.dx);
      minY = min(minY, point.dy);
      maxY = max(maxY, point.dy);
    }

    final sourceCenter = Offset(
      (minX + maxX) * 0.5,
      (minY + maxY) * 0.5,
    );
    final targetCenter = Offset(
      canvasSize.width * 0.5,
      canvasSize.height * 0.5,
    );
    final idealDelta = targetCenter - sourceCenter;

    final minDeltaX = -minX;
    final maxDeltaX = canvasSize.width - maxX;
    final minDeltaY = -minY;
    final maxDeltaY = canvasSize.height - maxY;
    final deltaX = minDeltaX > maxDeltaX
        ? idealDelta.dx
        : idealDelta.dx.clamp(minDeltaX, maxDeltaX).toDouble();
    final deltaY = minDeltaY > maxDeltaY
        ? idealDelta.dy
        : idealDelta.dy.clamp(minDeltaY, maxDeltaY).toDouble();
    final delta = Offset(deltaX, deltaY);

    var insertedAnyStroke = false;
    for (final stroke in sourceStrokes) {
      if (stroke.points.isEmpty) {
        continue;
      }

      final shiftedPoints =
          stroke.points.map((point) => point + delta).toList(growable: false);
      _strokes.add(
        EndpointSketchStroke(
          id: _nextStrokeId++,
          color: stroke.color,
          points: shiftedPoints,
        ),
      );
      insertedAnyStroke = true;
    }

    if (!insertedAnyStroke) {
      return false;
    }

    _activeStrokeId = null;
    _lastDragPosition = null;
    _clearMoveSelection();
    return true;
  }

  /// Borra los puntos tocados por el gesto actual y divide el trazo si hace falta.
  bool _eraseBetween(Offset start, Offset end) {
    if (_strokes.isEmpty) return false;

    final updatedStrokes = <EndpointSketchStroke>[];
    var didChange = false;

    for (final stroke in _strokes) {
      final remainingSegments = _eraseStrokeSegment(
        stroke: stroke,
        start: start,
        end: end,
      );
      final strokeWasChanged = remainingSegments.isEmpty ||
          remainingSegments.length != 1 ||
          remainingSegments.first.id != stroke.id;
      if (strokeWasChanged) {
        didChange = true;
      }
      updatedStrokes.addAll(remainingSegments);
    }

    if (!didChange) {
      return false;
    }

    _strokes
      ..clear()
      ..addAll(updatedStrokes);
    return true;
  }

  bool _arePointListsEqual(List<Offset> first, List<Offset> second) {
    if (identical(first, second)) return true;
    if (first.length != second.length) return false;

    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) {
        return false;
      }
    }

    return true;
  }

  EndpointSketchStroke? _pickStrokeAt(Offset position) {
    for (final stroke in _strokes.reversed) {
      final distance = _distanceToStroke(position, stroke);
      if (distance <= _strokeSelectionRadius) {
        return stroke;
      }
    }

    return null;
  }

  double _distanceToStroke(Offset point, EndpointSketchStroke stroke) {
    if (stroke.points.isEmpty) return double.infinity;
    if (stroke.points.length == 1) {
      return (point - stroke.points.first).distance;
    }

    var minimumDistance = double.infinity;
    for (var index = 1; index < stroke.points.length; index++) {
      final previous = stroke.points[index - 1];
      final current = stroke.points[index];
      final distance = _distanceToSegment(point, previous, current);
      if (distance < minimumDistance) {
        minimumDistance = distance;
      }
    }

    return minimumDistance;
  }

  Set<int> _connectedStrokeIdsFor(int rootStrokeId) {
    final adjacencyByStrokeId = <int, Set<int>>{
      for (final stroke in _strokes) stroke.id: <int>{},
    };
    for (var firstIndex = 0; firstIndex < _strokes.length; firstIndex++) {
      final firstStroke = _strokes[firstIndex];
      for (var secondIndex = firstIndex + 1;
          secondIndex < _strokes.length;
          secondIndex++) {
        final secondStroke = _strokes[secondIndex];
        if (!_areStrokesConnected(firstStroke, secondStroke)) {
          continue;
        }

        adjacencyByStrokeId[firstStroke.id]?.add(secondStroke.id);
        adjacencyByStrokeId[secondStroke.id]?.add(firstStroke.id);
      }
    }

    final connectedStrokeIds = <int>{};
    final pendingIds = Queue<int>()..add(rootStrokeId);
    while (pendingIds.isNotEmpty) {
      final currentId = pendingIds.removeFirst();
      if (!connectedStrokeIds.add(currentId)) {
        continue;
      }

      final neighbors = adjacencyByStrokeId[currentId];
      if (neighbors == null) continue;
      for (final neighborId in neighbors) {
        if (!connectedStrokeIds.contains(neighborId)) {
          pendingIds.add(neighborId);
        }
      }
    }

    return connectedStrokeIds;
  }

  bool _areStrokesConnected(
    EndpointSketchStroke firstStroke,
    EndpointSketchStroke secondStroke,
  ) {
    if (firstStroke.points.isEmpty || secondStroke.points.isEmpty) {
      return false;
    }

    if (firstStroke.points.length == 1 && secondStroke.points.length == 1) {
      return (firstStroke.points.first - secondStroke.points.first).distance <=
          _strokeConnectionRadius;
    }

    if (firstStroke.points.length == 1) {
      return _distanceToStroke(firstStroke.points.first, secondStroke) <=
          _strokeConnectionRadius;
    }

    if (secondStroke.points.length == 1) {
      return _distanceToStroke(secondStroke.points.first, firstStroke) <=
          _strokeConnectionRadius;
    }

    for (var firstIndex = 1;
        firstIndex < firstStroke.points.length;
        firstIndex++) {
      final firstStart = firstStroke.points[firstIndex - 1];
      final firstEnd = firstStroke.points[firstIndex];
      for (var secondIndex = 1;
          secondIndex < secondStroke.points.length;
          secondIndex++) {
        final secondStart = secondStroke.points[secondIndex - 1];
        final secondEnd = secondStroke.points[secondIndex];
        if (_segmentsIntersect(firstStart, firstEnd, secondStart, secondEnd)) {
          return true;
        }

        final minimumDistance = min(
          min(
            _distanceToSegment(firstStart, secondStart, secondEnd),
            _distanceToSegment(firstEnd, secondStart, secondEnd),
          ),
          min(
            _distanceToSegment(secondStart, firstStart, firstEnd),
            _distanceToSegment(secondEnd, firstStart, firstEnd),
          ),
        );
        if (minimumDistance <= _strokeConnectionRadius) {
          return true;
        }
      }
    }

    return false;
  }

  bool _segmentsIntersect(
    Offset firstStart,
    Offset firstEnd,
    Offset secondStart,
    Offset secondEnd,
  ) {
    final firstOrientation = _orientation(firstStart, firstEnd, secondStart);
    final secondOrientation = _orientation(firstStart, firstEnd, secondEnd);
    final thirdOrientation = _orientation(secondStart, secondEnd, firstStart);
    final fourthOrientation = _orientation(secondStart, secondEnd, firstEnd);

    if (firstOrientation != secondOrientation &&
        thirdOrientation != fourthOrientation) {
      return true;
    }
    if (firstOrientation == 0 &&
        _isOnSegment(firstStart, secondStart, firstEnd)) {
      return true;
    }
    if (secondOrientation == 0 &&
        _isOnSegment(firstStart, secondEnd, firstEnd)) {
      return true;
    }
    if (thirdOrientation == 0 &&
        _isOnSegment(secondStart, firstStart, secondEnd)) {
      return true;
    }
    if (fourthOrientation == 0 &&
        _isOnSegment(secondStart, firstEnd, secondEnd)) {
      return true;
    }

    return false;
  }

  int _orientation(Offset first, Offset second, Offset third) {
    final cross = (second.dx - first.dx) * (third.dy - first.dy) -
        (second.dy - first.dy) * (third.dx - first.dx);
    if (cross.abs() <= _intersectionEpsilon) {
      return 0;
    }
    return cross > 0 ? 1 : -1;
  }

  bool _isOnSegment(Offset start, Offset point, Offset end) {
    return point.dx <= max(start.dx, end.dx) + _intersectionEpsilon &&
        point.dx >= min(start.dx, end.dx) - _intersectionEpsilon &&
        point.dy <= max(start.dy, end.dy) + _intersectionEpsilon &&
        point.dy >= min(start.dy, end.dy) - _intersectionEpsilon;
  }

  /// Recorta de un trazo la porcion atravesada por el borrador y conserva el resto.
  List<EndpointSketchStroke> _eraseStrokeSegment({
    required EndpointSketchStroke stroke,
    required Offset start,
    required Offset end,
  }) {
    if (stroke.points.isEmpty) return const <EndpointSketchStroke>[];

    final keptPointGroups = <List<Offset>>[];
    var currentGroup = <Offset>[];
    var touched = false;

    for (final point in stroke.points) {
      final shouldErase = _distanceToSegment(point, start, end) <= eraserRadius;
      if (shouldErase) {
        touched = true;
        if (currentGroup.isNotEmpty) {
          keptPointGroups.add(List<Offset>.from(currentGroup));
          currentGroup = <Offset>[];
        }
        continue;
      }

      currentGroup.add(point);
    }

    if (currentGroup.isNotEmpty) {
      keptPointGroups.add(List<Offset>.from(currentGroup));
    }

    if (!touched) {
      return <EndpointSketchStroke>[stroke];
    }

    return keptPointGroups
        .map(
          (points) => EndpointSketchStroke(
            id: _nextStrokeId++,
            color: stroke.color,
            points: points,
          ),
        )
        .toList(growable: false);
  }

  /// Calcula la distancia minima entre el borrador y un punto concreto del trazo.
  double _distanceToSegment(Offset point, Offset start, Offset end) {
    final segment = end - start;
    final segmentLengthSquared =
        (segment.dx * segment.dx) + (segment.dy * segment.dy);
    if (segmentLengthSquared == 0) {
      return (point - start).distance;
    }

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

  bool _clearMoveSelection() {
    final hadSelection =
        _activeMoveSession != null || _selectedStrokeIds.isNotEmpty;
    _activeMoveSession = null;
    _selectedStrokeIds = const <int>{};
    return hadSelection;
  }
}

class _EndpointSketchMoveSession {
  final Offset anchor;
  final Map<int, List<Offset>> originalPointsByStrokeId;

  const _EndpointSketchMoveSession({
    required this.anchor,
    required this.originalPointsByStrokeId,
  });
}

/// Precalcula ruido de fondo estable para que la textura del lienzo no parpadee.
List<EndpointSketchNoiseDot> buildEndpointSketchNoiseDots({
  required int seed,
  required int count,
  double baseRadius = 0.4,
  double radiusDelta = 1.25,
  double baseAlpha = 0.04,
  double alphaDelta = 0.12,
}) {
  final seededRandom = Random(seed);
  return List<EndpointSketchNoiseDot>.generate(count, (index) {
    final tint = index.isEven
        ? EndpointPalette.softForeground
        : EndpointPalette.soften(EndpointPalette.infoAccent, amount: 0.2);
    return EndpointSketchNoiseDot(
      relativeOffset: Offset(
        seededRandom.nextDouble(),
        seededRandom.nextDouble(),
      ),
      radius: baseRadius + (seededRandom.nextDouble() * radiusDelta),
      color: tint.withValues(
        alpha: baseAlpha + (seededRandom.nextDouble() * alphaDelta),
      ),
    );
  });
}
