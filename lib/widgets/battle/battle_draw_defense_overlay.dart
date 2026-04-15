import '../_imports.dart';
import '../path/operative_sketch_recognition_helper.dart';

const _battleDefenseCanvasBorderRadius = 20.0;
const _battleDefenseNoiseSeed = 52431;
const _battleDefenseFeedbackLifetime = Duration(seconds: 1);
const _battleDefenseFeedbackGap = Duration(milliseconds: 450);
const _battleDefenseMissAccent = Color(0xFFC178FF);
const _battleDefenseSuccessAccent = Color(0xFF5AF78E);
const _battleDefenseEraserRadius = 18.0;

class BattleDrawDefenseOverlay extends StatefulWidget {
  final int requiredSquareCount;

  const BattleDrawDefenseOverlay({
    super.key,
    required this.requiredSquareCount,
  }) : assert(requiredSquareCount > 0);

  @override
  State<BattleDrawDefenseOverlay> createState() =>
      _BattleDrawDefenseOverlayState();
}

class _BattleDrawDefenseOverlayState extends State<BattleDrawDefenseOverlay> {
  final OperativeSketchRecognitionHelper _recognitionHelper =
      const OperativeSketchRecognitionHelper();
  late final EndpointSketchCanvasController _sketchController;
  late final EndpointSketchFeedbackController _feedbackController;
  late final List<EndpointSketchNoiseDot> _noiseDots;

  Size? _canvasSize;
  int _lastDetectedSquares = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _sketchController = EndpointSketchCanvasController(
      initialBrushColor: EndpointPalette.infoAccent,
      eraserRadius: _battleDefenseEraserRadius,
    );
    _feedbackController = EndpointSketchFeedbackController(
      lifetime: _battleDefenseFeedbackLifetime,
      gap: _battleDefenseFeedbackGap,
    )..addListener(_handleFeedbackChanged);
    _noiseDots = buildEndpointSketchNoiseDots(
      seed: _battleDefenseNoiseSeed,
      count: 240,
      radiusDelta: 1.3,
    );
  }

  void _handleFeedbackChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _handlePanStart(DragStartDetails details) {
    _feedbackController.dismiss();
    if (_sketchController.handlePanStart(details.localPosition)) {
      setState(() {});
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_sketchController.handlePanUpdate(details.localPosition)) {
      setState(() {});
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    _sketchController.handlePanEnd();
  }

  void _clearStrokes() {
    _feedbackController.dismiss();
    if (_sketchController.clear()) {
      setState(() {
        _lastDetectedSquares = 0;
      });
    }
  }

  void _undoLastStroke() {
    _feedbackController.dismiss();
    if (_sketchController.undoLastStroke()) {
      setState(() {
        _lastDetectedSquares = 0;
      });
    }
  }

  void _handleCheckPressed() {
    _scanDetectedSquares(showFeedback: true);
  }

  Future<void> _submitDefense() async {
    if (_isSubmitting) return;

    final detectedSquares = _scanDetectedSquares(showFeedback: true);
    final didMatchTarget = detectedSquares == widget.requiredSquareCount;
    setState(() {
      _isSubmitting = true;
    });

    if (!mounted) return;
    Navigator.of(context).pop(didMatchTarget);
  }

  int _scanDetectedSquares({
    required bool showFeedback,
  }) {
    final canvasSize = _canvasSize;
    if (canvasSize == null ||
        canvasSize.isEmpty ||
        !_sketchController.hasStrokes) {
      if (showFeedback) {
        _feedbackController.show(
          label: '0/${widget.requiredSquareCount}',
          color: _battleDefenseMissAccent,
        );
      }
      setState(() {
        _lastDetectedSquares = 0;
      });
      return 0;
    }

    final result = _recognitionHelper.scan(
      strokes: _sketchController.strokePointLists,
      canvasSize: canvasSize,
    );
    final detectedSquares = result.matches
        .where((match) => match.kind == OperativeSketchRecognitionKind.square)
        .fold<int>(0, (sum, match) => sum + match.count);
    final didMatchTarget = detectedSquares == widget.requiredSquareCount;

    setState(() {
      _lastDetectedSquares = detectedSquares;
    });

    if (!showFeedback) {
      return detectedSquares;
    }

    _feedbackController.show(
      label: didMatchTarget
          ? 'OK ${widget.requiredSquareCount}'
          : '$detectedSquares/${widget.requiredSquareCount}',
      color: didMatchTarget
          ? _battleDefenseSuccessAccent
          : _battleDefenseMissAccent,
    );

    return detectedSquares;
  }

  @override
  void dispose() {
    _feedbackController
      ..removeListener(_handleFeedbackChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goalLabel = '${widget.requiredSquareCount}';
    final progressColor = _lastDetectedSquares == widget.requiredSquareCount
        ? _battleDefenseSuccessAccent
        : EndpointPalette.infoAccent;

    return EndpointOverlayScaffold(
      sectionLabel: 'COMBATE',
      sectionValue: 'BLOQUEO',
      showHeader: false,
      showCloseButton: false,
      accent: EndpointPalette.infoAccent,
      backgroundColor: EndpointPalette.panelBackgroundOpaque,
      bottomInset: 18,
      maxWidth: 540,
      maxHeight: 760,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EndpointPanel(
            accent: progressColor,
            backgroundColor: EndpointPalette.blend(
              EndpointPalette.panelBackgroundBattle,
              progressColor,
              0.12,
            ),
            borderRadius: 12,
            glowOpacity: 0.06,
            blurRadius: 16,
            spreadRadius: 1,
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Row(
              children: [
                Icon(
                  Icons.crop_square_rounded,
                  color: progressColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                EndpointText(
                  '$goalLabel',
                  style: textTitleMediumBold.copyWith(
                    color: EndpointPalette.softForeground,
                    letterSpacing: 1.0,
                  ),
                ),
                const Spacer(),
                EndpointText(
                  '${_lastDetectedSquares.clamp(0, 999)}/$goalLabel',
                  style: textSmallNumericBold.copyWith(
                    color: progressColor,
                    fontSize: 12,
                    letterSpacing: 0.9,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                _canvasSize = Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );
                return RepaintBoundary(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        _battleDefenseCanvasBorderRadius,
                      ),
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
                          blurRadius: 22,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        _battleDefenseCanvasBorderRadius - 1,
                      ),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanStart: _handlePanStart,
                        onPanUpdate: _handlePanUpdate,
                        onPanEnd: _handlePanEnd,
                        onPanCancel: () =>
                            _handlePanEnd(DragEndDetails(primaryVelocity: 0)),
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
                                    padding: const EdgeInsets.only(top: 18),
                                    child: EndpointSketchFeedbackBanner(
                                      feedback: _feedbackController.feedback,
                                      lifetime: _battleDefenseFeedbackLifetime,
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
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: EndpointActionButton(
                  label: 'Retroceder',
                  icon: Icons.undo_rounded,
                  onPressed:
                      _sketchController.hasStrokes ? _undoLastStroke : null,
                  tooltip: 'Eliminar el ultimo trazo',
                  accent: EndpointPalette.primaryAccent,
                  backgroundColor: EndpointPalette.closeButtonBackground,
                  foregroundColor: EndpointPalette.softForeground,
                  height: 44,
                  useMarquee: false,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: EndpointActionButton(
                  label: 'Limpiar',
                  icon: Icons.layers_clear_rounded,
                  onPressed:
                      _sketchController.hasStrokes ? _clearStrokes : null,
                  tooltip: 'Borrar todos los trazos',
                  accent: EndpointPalette.infoAccent,
                  backgroundColor: EndpointPalette.closeButtonBackground,
                  foregroundColor: EndpointPalette.softForeground,
                  height: 44,
                  useMarquee: false,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: EndpointActionButton(
                  label: 'CHECK',
                  icon: Icons.fact_check_rounded,
                  onPressed: _handleCheckPressed,
                  tooltip: 'Contar cuadrados detectados',
                  accent: EndpointPalette.warningAccent,
                  backgroundColor: EndpointPalette.blend(
                    EndpointPalette.panelBackground,
                    EndpointPalette.warningAccent,
                    0.1,
                  ),
                  foregroundColor: EndpointPalette.softForegroundWarm,
                  height: 44,
                  useMarquee: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          EndpointActionButton(
            label: _isSubmitting ? 'RESOLVIENDO' : 'BLOQUEAR',
            icon: Icons.shield_rounded,
            onPressed: _isSubmitting ? null : () => unawaited(_submitDefense()),
            tooltip: 'Resolver el bloqueo segun los cuadrados detectados',
            accent: EndpointPalette.infoAccent,
            backgroundColor: EndpointPalette.blend(
              EndpointPalette.panelBackgroundBattle,
              EndpointPalette.infoAccent,
              0.14,
            ),
            foregroundColor: EndpointPalette.softForegroundWarm,
            height: 52,
            useMarquee: false,
          ),
        ],
      ),
    );
  }
}
