import '../_imports.dart';
import 'endpoint_sketch_canvas_controller.dart';

/// Pinta el fondo granular del lienzo y los trazos persistentes activos del usuario.
class EndpointSketchPainter extends CustomPainter {
  final List<EndpointSketchStroke> strokes;
  final List<EndpointSketchNoiseDot> noiseDots;

  /// Recibe los trazos visibles y el ruido precomputado necesarios para el canvas.
  const EndpointSketchPainter({
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
  void _paintStroke(Canvas canvas, EndpointSketchStroke stroke) {
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
  bool shouldRepaint(covariant EndpointSketchPainter oldDelegate) {
    return true;
  }
}
