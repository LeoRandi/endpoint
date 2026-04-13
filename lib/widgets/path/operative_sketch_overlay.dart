import '../_imports.dart';
import 'operative_sketch_recognition_helper.dart';

const _sketchCanvasBorderRadius = 18.0;
const _sketchNoiseSeed = 4312;
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

  static const _emptyRecognitionResult = OperativeSketchRecognitionResult(
    kind: OperativeSketchRecognitionKind.none,
    count: 0,
    matches: <OperativeSketchRecognitionMatch>[],
  );

  final OperativeSketchRecognitionHelper _recognitionHelper =
      const OperativeSketchRecognitionHelper();
  late final EndpointSketchCanvasController _sketchController;
  late final EndpointSketchFeedbackController _feedbackController;
  late final List<EndpointSketchNoiseDot> _noiseDots;
  Size? _canvasSize;
  OperativeSketchRecognitionResult _lastRecognitionResult =
      _emptyRecognitionResult;

  @override
  void initState() {
    super.initState();
    _sketchController = EndpointSketchCanvasController(
      initialBrushColor: _brushColors.first,
      eraserRadius: _sketchEraserRadius,
    );
    _feedbackController = EndpointSketchFeedbackController(
      lifetime: _sketchRecognitionFeedbackLifetime,
      gap: _sketchRecognitionFeedbackGap,
    )..addListener(_handleFeedbackChanged);
    _noiseDots = buildEndpointSketchNoiseDots(
      seed: _sketchNoiseSeed,
      count: 220,
    );
  }

  void _handleFeedbackChanged() {
    if (!mounted) return;
    setState(() {});
  }

  /// Inicia un trazo nuevo usando el color seleccionado en la paleta visible.
  void _handlePanStart(DragStartDetails details) {
    _feedbackController.dismiss();
    if (_sketchController.handlePanStart(details.localPosition)) {
      setState(() {});
    }
  }

  /// Anade nuevos puntos al trazo activo mientras el usuario arrastra el dedo.
  void _handlePanUpdate(DragUpdateDetails details) {
    if (_sketchController.handlePanUpdate(details.localPosition)) {
      setState(() {});
    }
  }

  /// Cierra el trazo activo al terminar el gesto y deja el contenido en pantalla.
  void _handlePanEnd(DragEndDetails details) {
    _sketchController.handlePanEnd();
  }

  /// Limpia manualmente todos los trazos visibles del lienzo.
  void _clearStrokes() {
    _feedbackController.dismiss();
    if (_sketchController.clear()) {
      setState(() {});
    }
  }

  /// Cambia el color del pincel que usara el siguiente trazo del jugador.
  void _selectBrushColor(Color color) {
    if (_sketchController.selectBrushColor(color)) {
      setState(() {});
    }
  }

  /// Alterna entre trazar lineas nuevas y borrar las ya existentes.
  void _toggleToolMode() {
    if (_sketchController.toggleToolMode()) {
      setState(() {});
    }
  }

  /// Ejecuta el helper sobre el dibujo actual y lo traduce a feedback visual.
  void _runRecognitionScan() {
    if (!mounted || _sketchController.hasActiveStroke) return;
    final canvasSize = _canvasSize;
    if (canvasSize == null || canvasSize.isEmpty) return;

    final result = _recognitionHelper.scan(
      strokes: _sketchController.strokePointLists,
      canvasSize: canvasSize,
    );
    setState(() {
      _lastRecognitionResult = result;
    });
    if (result.hasMatch) {
      _feedbackController.showSequence(
        labels: result.displayLabels,
        color: EndpointPalette.warningAccent,
      );
      return;
    }

    _feedbackController.show(
      label: '?',
      color: _sketchRecognitionMissAccent,
    );
  }

  /// Permite lanzar el escaneo bajo demanda desde el nuevo boton de comprobacion.
  void _handleCheckPressed() {
    _feedbackController.dismiss();
    if (!_sketchController.hasStrokes) {
      setState(() {
        _lastRecognitionResult = _emptyRecognitionResult;
      });
      return;
    }
    _runRecognitionScan();
  }

  /// Libera los temporizadores del overlay al cerrar la ventana.
  @override
  void dispose() {
    _feedbackController
      ..removeListener(_handleFeedbackChanged)
      ..dispose();
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
          _SketchRecognitionSummaryPanel(
            result: _lastRecognitionResult,
          ),
          const SizedBox(height: 10),
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
                                    painter: EndpointSketchPainter(
                                      strokes: _sketchController.strokes,
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
                                        child: EndpointSketchFeedbackBanner(
                                          feedback:
                                              _feedbackController.feedback,
                                          lifetime:
                                              _sketchRecognitionFeedbackLifetime,
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
                        isSelected: _sketchController.toolMode ==
                                EndpointSketchToolMode.paint &&
                            _sketchController.selectedBrushColor == color,
                        onPressed: () => _selectBrushColor(color),
                      ),
                    _SketchToolToggleButton(
                      isEraseMode: _sketchController.toolMode ==
                          EndpointSketchToolMode.erase,
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
                    onPressed:
                        _sketchController.hasStrokes ? _clearStrokes : null,
                    tooltip: 'Borrar todos los trazos activos',
                    accent: EndpointPalette.infoAccent,
                    backgroundColor: EndpointPalette.closeButtonBackground,
                    foregroundColor: EndpointPalette.softForeground,
                    useMarquee: false,
                  ),
                  const SizedBox(width: 8),
                  _SketchCheckButton(
                    count: _lastRecognitionResult.totalCount,
                    onPressed: _handleCheckPressed,
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

/// Resume las formas detectadas para poder validar el reconocimiento sin mirar el feedback flotante.
class _SketchRecognitionSummaryPanel extends StatelessWidget {
  final OperativeSketchRecognitionResult result;

  /// Construye un panel compacto con el conteo actual de cada forma reconocida.
  const _SketchRecognitionSummaryPanel({
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final matches = result.matches;
    return Container(
      padding: const EdgeInsets.fromLTRB(2, 2, 2, 2),
      decoration: BoxDecoration(
        color: EndpointPalette.panelBackgroundOpaque.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: EndpointPalette.softForeground.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          EndpointText(
            'CHECK',
            style: textSmallBold.copyWith(
              color: EndpointPalette.infoAccent.withValues(alpha: 0.92),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 58,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: matches.isEmpty
                    ? const <Widget>[
                        _SketchRecognitionSummaryCard(
                          title: 'Sin detecciones',
                          value: '0',
                          accent: EndpointPalette.infoAccent,
                        ),
                      ]
                    : matches
                        .map(
                          (match) => Padding(
                            padding: EdgeInsets.only(
                              right: match == matches.last ? 0 : 10,
                            ),
                            child: _SketchRecognitionSummaryCard(
                              title: _shapeSummaryLabel(match.kind),
                              value: match.count.toString(),
                              accent: _shapeSummaryAccent(match.kind),
                            ),
                          ),
                        )
                        .toList(growable: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _shapeSummaryLabel(OperativeSketchRecognitionKind kind) {
    switch (kind) {
      case OperativeSketchRecognitionKind.scissors:
        return 'Tijeras';
      case OperativeSketchRecognitionKind.triangle:
        return 'Triangulo';
      case OperativeSketchRecognitionKind.square:
        return 'Cuadrado';
      case OperativeSketchRecognitionKind.circle:
        return 'Circulo';
      case OperativeSketchRecognitionKind.none:
        return 'Ninguna';
    }
  }

  static Color _shapeSummaryAccent(OperativeSketchRecognitionKind kind) {
    switch (kind) {
      case OperativeSketchRecognitionKind.scissors:
        return EndpointPalette.warningAccent;
      case OperativeSketchRecognitionKind.triangle:
        return EndpointPalette.warningAccent;
      case OperativeSketchRecognitionKind.square:
        return EndpointPalette.infoAccent;
      case OperativeSketchRecognitionKind.circle:
        return EndpointPalette.primaryAccent;
      case OperativeSketchRecognitionKind.none:
        return EndpointPalette.softForeground;
    }
  }
}

class _SketchRecognitionSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color accent;

  const _SketchRecognitionSummaryCard({
    required this.title,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      padding: const EdgeInsets.symmetric(
        horizontal: 2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: EndpointPalette.blend(
          EndpointPalette.panelBackground,
          accent,
          0.12,
        ),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: accent.withValues(alpha: 0.34),
          width: 1.1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          EndpointText(
            title,
            maxLines: 2,
            style: textSmallBold.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
              letterSpacing: 0.2,
              fontSize: 11,
            ),
          ),
          EndpointText(
            value,
            style: textTitleMediumBold.copyWith(
              color: accent,
              letterSpacing: 0.8,
            ),
          ),
        ],
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
    final accent = isEraseMode
        ? EndpointPalette.warningAccent
        : EndpointPalette.infoAccent;
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
                color:
                    isEraseMode ? accent : Colors.white.withValues(alpha: 0.26),
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
