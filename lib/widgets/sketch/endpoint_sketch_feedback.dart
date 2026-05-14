import '../_imports.dart';

/// Modelo breve que describe el ultimo mensaje flotante mostrado sobre el lienzo.
class EndpointSketchFeedback {
  final String label;
  final Color color;
  final int version;

  /// Construye una pieza de feedback con identidad propia para animarla una sola vez.
  const EndpointSketchFeedback({
    required this.label,
    required this.color,
    required this.version,
  });
}

/// Orquesta la cola temporal de mensajes flotantes del lienzo compartido.
class EndpointSketchFeedbackController extends ChangeNotifier {
  final Duration lifetime;
  final Duration gap;

  Timer? _timer;
  EndpointSketchFeedback? _feedback;
  int _version = 0;

  /// Inicializa el controlador con la duracion visible de cada mensaje y la pausa entre ellos.
  EndpointSketchFeedbackController({
    required this.lifetime,
    required this.gap,
  });

  /// Expone el mensaje activo actual, si existe alguno.
  EndpointSketchFeedback? get feedback => _feedback;

  /// Muestra una sola pista flotante y programa su desaparicion.
  void show({
    required String label,
    required Color color,
  }) {
    _timer?.cancel();
    final feedback = EndpointSketchFeedback(
      label: label,
      color: color,
      version: ++_version,
    );
    _feedback = feedback;
    notifyListeners();
    _timer = Timer(lifetime, () {
      _clearIfMatches(feedback);
    });
  }

  /// Reproduce varias pistas una detras de otra dejando una pausa corta entre mensajes.
  void showSequence({
    required List<String> labels,
    required Color color,
  }) {
    if (labels.isEmpty) return;

    _timer?.cancel();
    _playAt(
      labels: labels,
      color: color,
      index: 0,
    );
  }

  /// Elimina el feedback temporal activo cuando el lienzo debe quedar neutro.
  void dismiss() {
    if (_feedback == null && _timer == null) return;

    _timer?.cancel();
    _timer = null;
    _feedback = null;
    notifyListeners();
  }

  /// Libera el temporizador interno al cerrar el overlay.
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Muestra un mensaje concreto de la secuencia y programa el siguiente cuando toca.
  void _playAt({
    required List<String> labels,
    required Color color,
    required int index,
  }) {
    if (index >= labels.length) return;

    final feedback = EndpointSketchFeedback(
      label: labels[index],
      color: color,
      version: ++_version,
    );
    _feedback = feedback;
    notifyListeners();

    _timer = Timer(lifetime, () {
      _clearIfMatches(feedback);
      if (index + 1 >= labels.length) return;
      _timer = Timer(gap, () {
        _playAt(
          labels: labels,
          color: color,
          index: index + 1,
        );
      });
    });
  }

  void _clearIfMatches(EndpointSketchFeedback feedback) {
    if (_feedback?.version != feedback.version) return;

    _feedback = null;
    notifyListeners();
  }
}

/// Presenta un mensaje flotante que sube y se desvanece sobre el lienzo.
class EndpointSketchFeedbackBanner extends StatelessWidget {
  final EndpointSketchFeedback? feedback;
  final Duration lifetime;

  /// Construye el banner que dibuja la ultima forma detectada o el mensaje de error.
  const EndpointSketchFeedbackBanner({
    super.key,
    required this.feedback,
    required this.lifetime,
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
              duration: lifetime,
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
