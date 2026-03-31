import '../_imports.dart';

const _sketchStrokeLifetime = Duration(seconds: 4);
const _sketchCanvasBorderRadius = 18.0;
const _sketchNoiseSeed = 4312;

/// Overlay autocontenido que ofrece un lienzo efimero para dibujar con el dedo.
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
    EndpointPalette.infoAccent,
    EndpointPalette.rewardAccent,
  ];

  final Random _randomizer = Random();
  final List<_SketchStroke> _strokes = <_SketchStroke>[];
  final Map<int, Timer> _strokeTimers = <int, Timer>{};
  late final List<_SketchNoiseDot> _noiseDots = _buildNoiseDots();
  int _nextStrokeId = 0;
  int? _activeStrokeId;

  /// Inicia un trazo nuevo con un color vivo elegido al azar dentro de la paleta del juego.
  void _handlePanStart(DragStartDetails details) {
    final stroke = _SketchStroke(
      id: _nextStrokeId++,
      color: _pickBrushColor(),
      points: <Offset>[details.localPosition],
    );
    setState(() {
      _strokes.add(stroke);
      _activeStrokeId = stroke.id;
    });
  }

  /// Anade nuevos puntos al trazo activo mientras el usuario arrastra el dedo.
  void _handlePanUpdate(DragUpdateDetails details) {
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

  /// Cierra el trazo activo y programa su borrado automatico unos segundos despues.
  void _handlePanEnd(DragEndDetails details) {
    final activeStrokeId = _activeStrokeId;
    _activeStrokeId = null;
    if (activeStrokeId == null) return;

    _scheduleStrokeRemoval(activeStrokeId);
  }

  /// Programa el borrado diferido de un trazo concreto para mantener el lienzo efimero.
  void _scheduleStrokeRemoval(int strokeId) {
    _strokeTimers.remove(strokeId)?.cancel();
    _strokeTimers[strokeId] = Timer(
      _sketchStrokeLifetime,
      () => _removeStroke(strokeId),
    );
  }

  /// Elimina un trazo concreto si sigue presente y limpia su temporizador asociado.
  void _removeStroke(int strokeId) {
    _strokeTimers.remove(strokeId)?.cancel();
    if (!mounted) return;

    setState(() {
      _strokes.removeWhere((stroke) => stroke.id == strokeId);
    });
  }

  /// Limpia manualmente todos los trazos y cancela cualquier borrado pendiente.
  void _clearStrokes() {
    for (final timer in _strokeTimers.values) {
      timer.cancel();
    }
    _strokeTimers.clear();
    setState(() {
      _strokes.clear();
      _activeStrokeId = null;
    });
  }

  /// Devuelve un color de pincel saturado a partir de los acentos principales de la interfaz.
  Color _pickBrushColor() {
    return _brushColors[_randomizer.nextInt(_brushColors.length)];
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

  /// Libera todos los temporizadores diferidos cuando el overlay desaparece.
  @override
  void dispose() {
    for (final timer in _strokeTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EndpointOverlayScaffold(
      title: 'TRAZADO',
      subtitle: 'Dibuja con el dedo. Cada trazo se borra solo al poco tiempo.',
      sectionLabel: 'LIENZO',
      sectionValue: 'EFIMERO',
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
                child: RepaintBoundary(
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
                      borderRadius:
                          BorderRadius.circular(_sketchCanvasBorderRadius - 1),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanStart: _handlePanStart,
                        onPanUpdate: _handlePanUpdate,
                        onPanEnd: _handlePanEnd,
                        onPanCancel: () => _handlePanEnd(
                          DragEndDetails(primaryVelocity: 0),
                        ),
                        child: CustomPaint(
                          painter: _OperativeSketchPainter(
                            strokes: List<_SketchStroke>.unmodifiable(_strokes),
                            noiseDots: _noiseDots,
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: EndpointText(
                  'Los trazos usan colores vivos del interfaz y desaparecen solos.',
                  maxLines: null,
                  style: textSmallBold.copyWith(
                    color: Colors.white.withValues(alpha: 0.74),
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(width: 10),
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
            ],
          ),
        ],
      ),
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

  /// Clona el trazo para actualizar su geometria sin perder su identidad efimera.
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

/// Pinta el fondo granular del lienzo y los trazos efimeros activos del usuario.
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
