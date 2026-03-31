import '../_imports.dart';
import 'operative_sketch_recognition_helper.dart';

const _sketchCanvasBorderRadius = 18.0;
const _sketchNoiseSeed = 4312;
const _sketchRecognitionDelay = Duration(seconds: 2);
const _sketchRecognitionFeedbackLifetime = Duration(seconds: 1);
const _sketchRecognitionFeedbackGap = Duration(milliseconds: 500);
const _sketchRecognitionMissAccent = Color(0xFFC178FF);
const _sketchEraserRadius = 18.0;

/// Overlay autocontenido que ofrece un lienzo persistente para dibujar con el dedo.
class OperativeSketchOverlay extends StatefulWidget {
  /// Construye el overlay de dibujo reutilizando la estetica de paneles de la app.
  const OperativeSketchOverlay({super.key});

  @override
  State<OperativeSketchOverlay> createState() => _OperativeSketchOverlayState();
}

class _OperativeSketchOverlayState extends State<OperativeSketchOverlay> {
  static const _brushColors = <Color>[
    EndpointPalette.primaryAccent,
    EndpointPalette.dangerAccent,
    EndpointPalette.warningAccent,
  ];

  final OperativeSketchRecognitionHelper _recognitionHelper =
      const OperativeSketchRecognitionHelper();
  final List<_SketchStroke> _strokes = <_SketchStroke>[];
  late final List<_SketchNoiseDot> _noiseDots = _buildNoiseDots();
  Timer? _recognitionTimer;
  Timer? _feedbackTimer;
  _SketchRecognitionFeedback? _recognitionFeedback;
  Size? _canvasSize;
  Color _selectedBrushColor = _brushColors.first;
  _SketchToolMode _toolMode = _SketchToolMode.paint;
  int _recognitionFeedbackVersion = 0;
  int _nextStrokeId = 0;
  int? _activeStrokeId;
  Offset? _lastDragPosition;
  bool _gestureChangedCanvas = false;
  OperativeSketchRecognitionResult _lastRecognitionResult =
      const OperativeSketchRecognitionResult(
        kind: OperativeSketchRecognitionKind.none,
        count: 0,
        matches: <OperativeSketchRecognitionMatch>[],
      );

  /// Inicia un trazo nuevo usando el color seleccionado en la paleta visible.
  void _handlePanStart(DragStartDetails details) {
    _cancelRecognitionTimer();
    _dismissRecognitionFeedback();
    _lastDragPosition = details.localPosition;
    _gestureChangedCanvas = false;
    if (_toolMode == _SketchToolMode.erase) {
      _gestureChangedCanvas = _eraseBetween(
        details.localPosition,
        details.localPosition,
      );
      return;
    }

    final stroke = _SketchStroke(
      id: _nextStrokeId++,
      color: _selectedBrushColor,
      points: <Offset>[details.localPosition],
    );
    setState(() {
      _strokes.add(stroke);
      _activeStrokeId = stroke.id;
      _lastRecognitionResult = const OperativeSketchRecognitionResult(
        kind: OperativeSketchRecognitionKind.none,
        count: 0,
        matches: <OperativeSketchRecognitionMatch>[],
      );
    });
  }

  /// Anade nuevos puntos al trazo activo mientras el usuario arrastra el dedo.
  void _handlePanUpdate(DragUpdateDetails details) {
    if (_toolMode == _SketchToolMode.erase) {
      final start = _lastDragPosition ?? details.localPosition;
      if (_eraseBetween(start, details.localPosition)) {
        _gestureChangedCanvas = true;
      }
      _lastDragPosition = details.localPosition;
      return;
    }

    final activeStrokeId = _activeStrokeId;
    if (activeStrokeId == null) return;

    final strokeIndex = _strokes.indexWhere(
      (stroke) => stroke.id == activeStrokeId,
    );
    if (strokeIndex < 0) return;

    final activeStroke = _strokes[strokeIndex];
    final updatedPoints = List<Offset>.from(activeStroke.points)
      ..add(details.localPosition);
    setState(() {
      _strokes[strokeIndex] = activeStroke.copyWith(points: updatedPoints);
    });
  }

  /// Cierra el trazo activo al terminar el gesto y deja el contenido en pantalla.
  void _handlePanEnd(DragEndDetails details) {
    _lastDragPosition = null;
    if (_toolMode == _SketchToolMode.erase) {
      _activeStrokeId = null;
      final shouldScan = _gestureChangedCanvas;
      _gestureChangedCanvas = false;
      if (shouldScan) {
        _scheduleRecognitionScan();
      }
      return;
    }

    _activeStrokeId = null;
    _scheduleRecognitionScan();
  }

  /// Limpia manualmente todos los trazos visibles del lienzo.
  void _clearStrokes() {
    _cancelRecognitionTimer();
    _dismissRecognitionFeedback();
    setState(() {
      _strokes.clear();
      _activeStrokeId = null;
      _lastRecognitionResult = const OperativeSketchRecognitionResult(
        kind: OperativeSketchRecognitionKind.none,
        count: 0,
        matches: <OperativeSketchRecognitionMatch>[],
      );
    });
  }

  /// Cambia el color del pincel que usara el siguiente trazo del jugador.
  void _selectBrushColor(Color color) {
    if (_selectedBrushColor == color && _toolMode == _SketchToolMode.paint) {
      return;
    }
    setState(() {
      _selectedBrushColor = color;
      _toolMode = _SketchToolMode.paint;
    });
  }

  /// Alterna entre trazar lineas nuevas y borrar las ya existentes.
  void _toggleToolMode() {
    setState(() {
      _toolMode = _toolMode == _SketchToolMode.paint
          ? _SketchToolMode.erase
          : _SketchToolMode.paint;
    });
  }

  /// Borra los puntos tocados por el gesto actual y divide el trazo si hace falta.
  bool _eraseBetween(Offset start, Offset end) {
    if (_strokes.isEmpty) return false;

    final updatedStrokes = <_SketchStroke>[];
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

    setState(() {
      _strokes
        ..clear()
        ..addAll(updatedStrokes);
      _lastRecognitionResult = const OperativeSketchRecognitionResult(
        kind: OperativeSketchRecognitionKind.none,
        count: 0,
        matches: <OperativeSketchRecognitionMatch>[],
      );
    });
    return true;
  }

  /// Recorta de un trazo la porcion atravesada por el borrador y conserva el resto.
  List<_SketchStroke> _eraseStrokeSegment({
    required _SketchStroke stroke,
    required Offset start,
    required Offset end,
  }) {
    if (stroke.points.isEmpty) return const <_SketchStroke>[];

    final keptPointGroups = <List<Offset>>[];
    var currentGroup = <Offset>[];
    var touched = false;

    for (final point in stroke.points) {
      final shouldErase =
          _distanceToSegment(point, start, end) <= _sketchEraserRadius;
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
      return <_SketchStroke>[stroke];
    }

    return keptPointGroups
        .map(
          (points) => _SketchStroke(
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

  /// Programa un escaneo diferido cuando el usuario deja el lienzo en reposo.
  void _scheduleRecognitionScan() {
    _cancelRecognitionTimer();
    if (_strokes.isEmpty) return;

    _recognitionTimer = Timer(_sketchRecognitionDelay, _runRecognitionScan);
  }

  /// Cancela cualquier escaneo pendiente cuando vuelve a haber interaccion.
  void _cancelRecognitionTimer() {
    _recognitionTimer?.cancel();
    _recognitionTimer = null;
  }

  /// Ejecuta el helper sobre el dibujo actual y lo traduce a feedback visual.
  void _runRecognitionScan() {
    _recognitionTimer = null;
    if (!mounted || _activeStrokeId != null) return;
    final canvasSize = _canvasSize;
    if (canvasSize == null || canvasSize.isEmpty) return;

    final result = _recognitionHelper.scan(
      strokes: _strokes.map((stroke) => stroke.points),
      canvasSize: canvasSize,
    );
    setState(() {
      _lastRecognitionResult = result;
    });
    if (result.hasMatch) {
      _showRecognitionFeedbackSequence(
        labels: result.displayLabels,
        color: EndpointPalette.warningAccent,
      );
      return;
    }

    _showRecognitionFeedback(label: '?', color: _sketchRecognitionMissAccent);
  }

  /// Permite lanzar el escaneo bajo demanda desde el nuevo boton de comprobacion.
  void _handleCheckPressed() {
    _cancelRecognitionTimer();
    _runRecognitionScan();
  }

  /// Muestra una pista flotante corta para comunicar el resultado del reconocimiento.
  void _showRecognitionFeedback({
    required String label,
    required Color color,
  }) {
    _feedbackTimer?.cancel();
    final feedback = _SketchRecognitionFeedback(
      label: label,
      color: color,
      version: ++_recognitionFeedbackVersion,
    );
    setState(() {
      _recognitionFeedback = feedback;
    });
    _feedbackTimer = Timer(_sketchRecognitionFeedbackLifetime, () {
      if (!mounted) return;
      setState(() {
        if (_recognitionFeedback?.version == feedback.version) {
          _recognitionFeedback = null;
        }
      });
    });
  }

  /// Reproduce varias pistas una detras de otra dejando una pausa corta entre mensajes.
  void _showRecognitionFeedbackSequence({
    required List<String> labels,
    required Color color,
  }) {
    if (labels.isEmpty) return;

    _feedbackTimer?.cancel();
    _playRecognitionFeedbackAt(
      labels: labels,
      color: color,
      index: 0,
    );
  }

  /// Muestra un mensaje concreto de la secuencia y programa el siguiente cuando toca.
  void _playRecognitionFeedbackAt({
    required List<String> labels,
    required Color color,
    required int index,
  }) {
    if (!mounted || index >= labels.length) return;

    final feedback = _SketchRecognitionFeedback(
      label: labels[index],
      color: color,
      version: ++_recognitionFeedbackVersion,
    );
    setState(() {
      _recognitionFeedback = feedback;
    });

    _feedbackTimer = Timer(_sketchRecognitionFeedbackLifetime, () {
      if (!mounted) return;
      setState(() {
        if (_recognitionFeedback?.version == feedback.version) {
          _recognitionFeedback = null;
        }
      });

      if (index + 1 >= labels.length) return;
      _feedbackTimer = Timer(_sketchRecognitionFeedbackGap, () {
        _playRecognitionFeedbackAt(
          labels: labels,
          color: color,
          index: index + 1,
        );
      });
    });
  }

  /// Elimina el feedback temporal activo cuando el lienzo debe quedar neutro.
  void _dismissRecognitionFeedback() {
    _feedbackTimer?.cancel();
    _feedbackTimer = null;
    _recognitionFeedback = null;
  }

  /// Precalcula el ruido de fondo en coordenadas relativas para que la textura no parpadee.
  List<_SketchNoiseDot> _buildNoiseDots() {
    final seededRandom = Random(_sketchNoiseSeed);
    return List<_SketchNoiseDot>.generate(220, (index) {
      final tint = index.isEven
          ? EndpointPalette.softForeground
          : EndpointPalette.soften(EndpointPalette.infoAccent, amount: 0.2);
      return _SketchNoiseDot(
        relativeOffset: Offset(
          seededRandom.nextDouble(),
          seededRandom.nextDouble(),
        ),
        radius: 0.4 + (seededRandom.nextDouble() * 1.25),
        color: tint.withValues(
          alpha: 0.04 + (seededRandom.nextDouble() * 0.12),
        ),
      );
    });
  }

  /// Libera los temporizadores del overlay al cerrar la ventana.
  @override
  void dispose() {
    _cancelRecognitionTimer();
    _feedbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EndpointOverlayScaffold(
      title: 'TRAZADO',
      subtitle:
          'Dibuja con el dedo, cambia de color o activa el borrador cuando lo necesites.',
      sectionLabel: 'LIENZO',
      sectionValue: 'MANUAL',
      closeTooltip: 'Cerrar lienzo',
      accent: EndpointPalette.infoAccent,
      bottomInset: 28,
      maxWidth: 430,
      maxHeight: 540,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    _canvasSize = Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );
                    return RepaintBoundary(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(_sketchCanvasBorderRadius),
                          border: Border.all(
                            color: EndpointPalette.softForeground.withValues(
                              alpha: 0.76,
                            ),
                            width: 1.6,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: EndpointPalette.infoAccent.withValues(
                                alpha: 0.1,
                              ),
                              blurRadius: 20,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                              _sketchCanvasBorderRadius - 1),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanStart: _handlePanStart,
                            onPanUpdate: _handlePanUpdate,
                            onPanEnd: _handlePanEnd,
                            onPanCancel: () => _handlePanEnd(
                              DragEndDetails(primaryVelocity: 0),
                            ),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _OperativeSketchPainter(
                                      strokes: List<_SketchStroke>.unmodifiable(
                                          _strokes),
                                      noiseDots: _noiseDots,
                                    ),
                                    child: const SizedBox.expand(),
                                  ),
                                ),
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: Align(
                                      alignment: Alignment.topCenter,
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 20),
                                        child: _SketchRecognitionFeedbackBanner(
                                          feedback: _recognitionFeedback,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          EndpointText(
            'Los trazos permanecen en pantalla hasta que limpies el lienzo o uses el borrador.',
            maxLines: null,
            style: textSmallBold.copyWith(
              color: Colors.white.withValues(alpha: 0.74),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Flexible(
                fit: FlexFit.loose,
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final color in _brushColors)
                      _SketchBrushSwatch(
                        color: color,
                        isSelected: _toolMode == _SketchToolMode.paint &&
                            _selectedBrushColor == color,
                        onPressed: () => _selectBrushColor(color),
                      ),
                    _SketchToolToggleButton(
                      isEraseMode: _toolMode == _SketchToolMode.erase,
                      onPressed: _toggleToolMode,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  EndpointActionButton(
                    label: 'Limpiar',
                    icon: Icons.layers_clear_rounded,
                    onPressed: _strokes.isEmpty ? null : _clearStrokes,
                    tooltip: 'Borrar todos los trazos activos',
                    accent: EndpointPalette.infoAccent,
                    backgroundColor: EndpointPalette.closeButtonBackground,
                    foregroundColor: EndpointPalette.softForeground,
                    useMarquee: false,
                  ),
                  const SizedBox(width: 8),
                  _SketchCheckButton(
                    count: _lastRecognitionResult.totalCount,
                    onPressed: _strokes.isEmpty ? null : _handleCheckPressed,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Alterna el comportamiento del gesto entre dibujar y borrar.
enum _SketchToolMode {
  paint,
  erase,
}

/// Modelo breve que describe el ultimo resultado de reconocimiento mostrado.
class _SketchRecognitionFeedback {
  final String label;
  final Color color;
  final int version;

  /// Construye una pieza de feedback con identidad propia para animarla una sola vez.
  const _SketchRecognitionFeedback({
    required this.label,
    required this.color,
    required this.version,
  });
}

/// Presenta un mensaje flotante que sube y se desvanece sobre el lienzo.
class _SketchRecognitionFeedbackBanner extends StatelessWidget {
  final _SketchRecognitionFeedback? feedback;

  /// Construye el banner que dibuja la ultima forma detectada o el ? de error.
  const _SketchRecognitionFeedbackBanner({
    required this.feedback,
  });

  @override
  Widget build(BuildContext context) {
    final activeFeedback = feedback;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 140),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: activeFeedback == null
          ? const SizedBox.shrink()
          : TweenAnimationBuilder<double>(
              key: ValueKey<int>(activeFeedback.version),
              tween: Tween<double>(begin: 0, end: 1),
              duration: _sketchRecognitionFeedbackLifetime,
              curve: Curves.easeOutCubic,
              builder: (context, progress, child) {
                final slideOffset = Offset(0, -18 * progress);
                final opacity = progress < 0.72
                    ? 1.0
                    : ((1 - progress) / 0.28).clamp(0.0, 1.0).toDouble();
                return Transform.translate(
                  offset: slideOffset,
                  child: Opacity(opacity: opacity, child: child),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: EndpointPalette.panelBackgroundOpaque.withValues(
                    alpha: 0.92,
                  ),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: activeFeedback.color.withValues(alpha: 0.74),
                    width: 1.3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: activeFeedback.color.withValues(alpha: 0.22),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: EndpointText(
                  activeFeedback.label,
                  style: textTitleMediumBold.copyWith(
                    color: activeFeedback.color,
                    letterSpacing: 1.6,
                  ),
                ),
              ),
            ),
    );
  }
}

/// Boton circular que permite escoger uno de los colores vivos del pincel.
class _SketchBrushSwatch extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onPressed;

  /// Construye una muestra de color pulsable y marca visualmente la seleccion activa.
  const _SketchBrushSwatch({
    required this.color,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkResponse(
        onTap: onPressed,
        radius: 22,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(
              color: isSelected
                  ? EndpointPalette.softForeground
                  : Colors.white.withValues(alpha: 0.26),
              width: isSelected ? 2.2 : 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isSelected ? 0.42 : 0.18),
                blurRadius: isSelected ? 12 : 6,
                spreadRadius: isSelected ? 1 : 0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Boton de paleta que conmuta entre pincel y borrador sin salir del overlay.
class _SketchToolToggleButton extends StatelessWidget {
  final bool isEraseMode;
  final VoidCallback onPressed;

  /// Construye el acceso rapido al borrador manteniendo el lenguaje visual de la paleta.
  const _SketchToolToggleButton({
    required this.isEraseMode,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final accent =
        isEraseMode ? EndpointPalette.warningAccent : EndpointPalette.infoAccent;
    final backgroundColor = isEraseMode
        ? EndpointPalette.blend(
            EndpointPalette.panelBackground,
            EndpointPalette.warningAccent,
            0.22,
          )
        : EndpointPalette.panelBackgroundOpaque.withValues(alpha: 0.74);

    return Tooltip(
      message: isEraseMode ? 'Cambiar a pintar' : 'Activar borrador',
      child: Material(
        color: Colors.transparent,
        child: InkResponse(
          onTap: onPressed,
          radius: 22,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: backgroundColor,
              border: Border.all(
                color: isEraseMode
                    ? accent
                    : Colors.white.withValues(alpha: 0.26),
                width: isEraseMode ? 2 : 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: isEraseMode ? 0.3 : 0.12),
                  blurRadius: isEraseMode ? 12 : 6,
                  spreadRadius: isEraseMode ? 1 : 0,
                ),
              ],
            ),
            child: Icon(
              isEraseMode
                  ? Icons.cleaning_services_rounded
                  : Icons.brush_rounded,
              size: 16,
              color: isEraseMode
                  ? EndpointPalette.softForegroundWarm
                  : EndpointPalette.softForeground,
            ),
          ),
        ),
      ),
    );
  }
}

/// Boton de comprobacion manual que refleja el total reconocido en un badge.
class _SketchCheckButton extends StatelessWidget {
  final int count;
  final VoidCallback? onPressed;

  /// Construye el acceso rapido de chequeo y deja el total combinado siempre visible.
  const _SketchCheckButton({
    required this.count,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final badgeAccent = count > 0
        ? EndpointPalette.warningAccent
        : EndpointPalette.neutralAccent;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        EndpointActionButton(
          label: 'CHECK',
          icon: Icons.fact_check_rounded,
          onPressed: onPressed,
          tooltip: onPressed == null
              ? 'Dibuja algo antes de lanzar el chequeo'
              : 'Escanear el lienzo y actualizar el conteo',
          accent: EndpointPalette.warningAccent,
          backgroundColor: EndpointPalette.blend(
            EndpointPalette.panelBackground,
            EndpointPalette.warningAccent,
            0.1,
          ),
          foregroundColor: EndpointPalette.softForegroundWarm,
          useMarquee: false,
        ),
        Positioned(
          top: -6,
          right: -6,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: EndpointPalette.panelBackgroundOpaque,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: badgeAccent.withValues(alpha: 0.88),
              ),
              boxShadow: [
                BoxShadow(
                  color: badgeAccent.withValues(alpha: 0.18),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              child: EndpointText(
                '$count',
                style: textSmallNumericBold.copyWith(
                  color: badgeAccent,
                  fontSize: 10,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Describe un trazo individual del usuario junto al color que se le ha asignado.
class _SketchStroke {
  final int id;
  final Color color;
  final List<Offset> points;

  /// Construye un trazo simple a partir de sus puntos y su color de pincel.
  const _SketchStroke({
    required this.id,
    required this.color,
    required this.points,
  });

  /// Clona el trazo para actualizar su geometria sin perder su identidad.
  _SketchStroke copyWith({
    List<Offset>? points,
  }) {
    return _SketchStroke(
      id: id,
      color: color,
      points: points ?? this.points,
    );
  }
}

/// Representa un punto del ruido de fondo en coordenadas relativas estables.
class _SketchNoiseDot {
  final Offset relativeOffset;
  final double radius;
  final Color color;

  /// Construye un punto de grano con su posicion, tamano y tono ya resueltos.
  const _SketchNoiseDot({
    required this.relativeOffset,
    required this.radius,
    required this.color,
  });
}

/// Pinta el fondo granular del lienzo y los trazos persistentes activos del usuario.
class _OperativeSketchPainter extends CustomPainter {
  final List<_SketchStroke> strokes;
  final List<_SketchNoiseDot> noiseDots;

  /// Recibe los trazos visibles y el ruido precomputado necesarios para el canvas.
  const _OperativeSketchPainter({
    required this.strokes,
    required this.noiseDots,
  });

  /// Dibuja el fondo oscuro del lienzo, el grano y las lineas activas del usuario.
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final backgroundPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF030706),
          Color(0xFF0B1210),
          Color(0xFF050907),
        ],
      ).createShader(rect);
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.1, -0.2),
        radius: 1.15,
        colors: [
          EndpointPalette.infoAccent.withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(rect);
    final gridPaint = Paint()
      ..color = EndpointPalette.softForeground.withValues(alpha: 0.035)
      ..strokeWidth = 1;

    canvas.drawRect(rect, backgroundPaint);
    canvas.drawRect(rect, vignettePaint);

    for (double y = 12; y <= size.height; y += 18) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (double x = 10; x <= size.width; x += 18) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    for (final dot in noiseDots) {
      final dotPaint = Paint()..color = dot.color;
      canvas.drawCircle(
        Offset(
          dot.relativeOffset.dx * size.width,
          dot.relativeOffset.dy * size.height,
        ),
        dot.radius,
        dotPaint,
      );
    }

    for (final stroke in strokes) {
      _paintStroke(canvas, stroke);
    }
  }

  /// Pinta un trazo con un halo suave y un nucleo mas intenso para que destaque.
  void _paintStroke(Canvas canvas, _SketchStroke stroke) {
    final glowPaint = Paint()
      ..color = stroke.color.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 9
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    final corePaint = Paint()
      ..color = stroke.color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 4.2;

    if (stroke.points.length < 2) {
      final point = stroke.points.first;
      canvas.drawCircle(point, 5.2, glowPaint..style = PaintingStyle.fill);
      canvas.drawCircle(point, 2.8, corePaint..style = PaintingStyle.fill);
      return;
    }

    final path = Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);
    for (int index = 1; index < stroke.points.length; index++) {
      final previousPoint = stroke.points[index - 1];
      final currentPoint = stroke.points[index];
      final midPoint = Offset(
        (previousPoint.dx + currentPoint.dx) / 2,
        (previousPoint.dy + currentPoint.dy) / 2,
      );
      path.quadraticBezierTo(
        previousPoint.dx,
        previousPoint.dy,
        midPoint.dx,
        midPoint.dy,
      );
    }
    final lastPoint = stroke.points.last;
    path.lineTo(lastPoint.dx, lastPoint.dy);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, corePaint);
  }

  /// Fuerza repintado cuando cambia la lista visible de ruido o de trazos.
  @override
  bool shouldRepaint(covariant _OperativeSketchPainter oldDelegate) {
    return true;
  }
}
