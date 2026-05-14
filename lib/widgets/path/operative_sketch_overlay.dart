import '../_imports.dart';
import '../../services/battle_drawing_bonus_resolver.dart';
import 'operative_sketch_recognition_helper.dart';
import 'package:flutter/gestures.dart';

const _sketchCanvasBorderRadius = 18.0;
const _sketchNoiseSeed = 4312;
const _sketchRecognitionFeedbackLifetime = Duration(seconds: 1);
const _sketchRecognitionFeedbackGap = Duration(milliseconds: 500);
const _sketchEraserRadius = 18.0;
const _sketchMoveLongPressDuration = Duration(milliseconds: 200);
const _sketchPreloadWarmupDuration = Duration(seconds: 3);
const _sketchPreloadDrawingDuration = Duration(seconds: 15);
const _operativeAttackBonusHooks = <ItemEffectHook>{
  ItemEffectHook.attackResolved,
  ItemEffectHook.turnStart,
  ItemEffectHook.turnEnd,
};
const _operativeDefenseBonusHooks = <ItemEffectHook>{
  ItemEffectHook.defendResolved,
  ItemEffectHook.receiveDamageResolved,
  ItemEffectHook.turnStart,
  ItemEffectHook.turnEnd,
};

enum _OperativeSketchPracticeMode {
  attack,
  defense,
}

enum _OperativeSketchPreloadPhase {
  idle,
  countdown,
  drawing,
}

/// Overlay autocontenido que ofrece un lienzo persistente para dibujar con el dedo.
class OperativeSketchOverlay extends StatefulWidget {
  final Battler player;

  /// Construye el overlay de dibujo reutilizando la estetica de paneles de la app.
  const OperativeSketchOverlay({
    super.key,
    required this.player,
  });

  @override
  State<OperativeSketchOverlay> createState() => _OperativeSketchOverlayState();
}

class _OperativeSketchOverlayState extends State<OperativeSketchOverlay>
    with TickerProviderStateMixin {
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
  final BattleDrawingBonusResolver _bonusResolver =
      const BattleDrawingBonusResolver();
  final BattleDrawingEligibleItemPlanner _eligibleItemPlanner =
      const BattleDrawingEligibleItemPlanner();
  late final AnimationController _preloadCountdownController =
      AnimationController(
    vsync: this,
    duration: _sketchPreloadWarmupDuration,
  )..addStatusListener(_handlePreloadCountdownStatus);
  late final AnimationController _preloadTimerController = AnimationController(
    vsync: this,
    duration: _sketchPreloadDrawingDuration,
  )..addStatusListener(_handlePreloadTimerStatus);
  _OperativeSketchPreloadPhase _preloadPhase =
      _OperativeSketchPreloadPhase.idle;
  bool _isShowingPreloadDecisionDialog = false;
  bool _isShowingQuickDrawPasteDialog = false;
  _OperativeSketchPracticeMode _practiceMode =
      _OperativeSketchPracticeMode.attack;
  late final EndpointSketchCanvasController _sketchController;
  late final EndpointSketchFeedbackController _feedbackController;
  late final List<EndpointSketchNoiseDot> _noiseDots;
  late List<Item> _bonusItems;
  late List<BattleDrawingItemBonusGroup> _bonusItemGroups;
  late BattleDrawingBonusResolution _baseBonusResolution;
  late BattleDrawingBonusResolution _lastBonusResolution;
  Size? _canvasSize;

  bool get _isPreloadSession =>
      _preloadPhase != _OperativeSketchPreloadPhase.idle;
  bool get _isPreloadCountdown =>
      _preloadPhase == _OperativeSketchPreloadPhase.countdown;
  bool get _isPreloadDrawing =>
      _preloadPhase == _OperativeSketchPreloadPhase.drawing;

  int get _preloadRecognizableShapeLimit {
    return widget.player.equipmentCapacity +
        widget.player.remainingEquipmentCapacity;
  }

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
    _rebuildPracticeBonuses();
  }

  void _handleFeedbackChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _resetRecognitionPreview() {
    if (identical(_lastBonusResolution, _baseBonusResolution)) {
      return;
    }
    _lastBonusResolution = _baseBonusResolution;
  }

  Set<ItemEffectHook> _bonusHooksForPracticeMode() {
    switch (_practiceMode) {
      case _OperativeSketchPracticeMode.attack:
        return _operativeAttackBonusHooks;
      case _OperativeSketchPracticeMode.defense:
        return _operativeDefenseBonusHooks;
    }
  }

  void _rebuildPracticeBonuses() {
    _bonusItems = _eligibleItemPlanner.equippedItemsForHooks(
      battler: widget.player,
      hooks: _bonusHooksForPracticeMode(),
    );
    _bonusItemGroups = BattleDrawingGrouping.groupBonusItems(_bonusItems);
    _baseBonusResolution = _bonusResolver.resolve(
      equippedItems: _bonusItems,
      recognizedCounts: const <ItemBonusShape, int>{},
      recognizedShapeCounts: const <BattleDrawingShape, int>{},
    );
    _lastBonusResolution = _baseBonusResolution;
  }

  void _selectPracticeMode(_OperativeSketchPracticeMode mode) {
    if (_isPreloadSession) return;
    if (_practiceMode == mode) return;

    _feedbackController.dismiss();
    setState(() {
      _practiceMode = mode;
      _rebuildPracticeBonuses();
    });
  }

  /// Inicia un trazo nuevo usando el color seleccionado en la paleta visible.
  void _handlePanStart(DragStartDetails details) {
    if (_isPreloadCountdown) {
      return;
    }

    if (_sketchController.toolMode == EndpointSketchToolMode.move) {
      return;
    }

    _feedbackController.dismiss();
    _resetRecognitionPreview();
    if (_sketchController.handlePanStart(details.localPosition)) {
      setState(() {});
    }
  }

  /// Anade nuevos puntos al trazo activo mientras el usuario arrastra el dedo.
  void _handlePanUpdate(DragUpdateDetails details) {
    if (_isPreloadCountdown) {
      return;
    }

    if (_sketchController.toolMode == EndpointSketchToolMode.move) {
      return;
    }

    if (_sketchController.handlePanUpdate(details.localPosition)) {
      _resetRecognitionPreview();
      setState(() {});
    }
  }

  /// Cierra el trazo activo al terminar el gesto y deja el contenido en pantalla.
  void _handlePanEnd(DragEndDetails details) {
    if (_isPreloadCountdown) {
      return;
    }

    _sketchController.handlePanEnd();
  }

  /// Selecciona y levanta un bloque de trazos conectados cuando la herramienta mano esta activa.
  void _handleLongPressStart(LongPressStartDetails details) {
    if (_isPreloadCountdown) {
      return;
    }

    if (_sketchController.toolMode != EndpointSketchToolMode.move) {
      return;
    }

    _feedbackController.dismiss();
    _resetRecognitionPreview();
    if (_sketchController.startMoveSelection(details.localPosition)) {
      setState(() {});
    }
  }

  /// Mueve en bloque la seleccion levantada siguiendo el dedo.
  void _handleLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (_isPreloadCountdown) {
      return;
    }

    if (_sketchController.toolMode != EndpointSketchToolMode.move) {
      return;
    }

    if (_sketchController.updateMoveSelection(details.localPosition)) {
      _resetRecognitionPreview();
      setState(() {});
    }
  }

  /// Suelta el bloque seleccionado en la posicion final.
  void _handleLongPressEnd(LongPressEndDetails details) {
    if (_isPreloadCountdown) {
      return;
    }

    if (_sketchController.endMoveSelection()) {
      setState(() {});
    }
  }

  void _handleLongPressCancel() {
    if (_isPreloadCountdown) {
      return;
    }

    if (_sketchController.endMoveSelection()) {
      setState(() {});
    }
  }

  /// Limpia manualmente todos los trazos visibles del lienzo.
  void _clearStrokes() {
    if (_isPreloadCountdown) return;

    _feedbackController.dismiss();
    if (_sketchController.clear()) {
      _resetRecognitionPreview();
      setState(() {});
    }
  }

  /// Deshace el ultimo trazo completo del lienzo.
  void _undoLastStroke() {
    if (_isPreloadCountdown) return;

    _feedbackController.dismiss();
    if (_sketchController.undoLastStroke()) {
      _resetRecognitionPreview();
      setState(() {});
    }
  }

  /// Cambia el color del pincel que usara el siguiente trazo del jugador.
  void _selectBrushColor(Color color) {
    if (_isPreloadSession) return;

    if (_sketchController.selectBrushColor(color)) {
      setState(() {});
    }
  }

  /// Cambia de forma explicita la herramienta activa del lienzo.
  void _selectToolMode(EndpointSketchToolMode mode) {
    if (_isPreloadSession) return;

    _feedbackController.dismiss();
    if (_sketchController.setToolMode(mode)) {
      setState(() {});
    }
  }

  Future<void> _handlePreloadPressed() async {
    if (_isPreloadSession || _isShowingPreloadDecisionDialog) return;

    _feedbackController.dismiss();
    _isShowingPreloadDecisionDialog = true;
    final accepted = await showEndpointDialog<bool>(
      context: context,
      barrierLabel: 'Confirmar precarga de runa',
      barrierDismissible: false,
      barrierColor: EndpointPalette.overlayScrimStrong,
      builder: (context) {
        return _OperativeSketchPreloadPromptDialog(
          onCancel: () => Navigator.of(context).pop(false),
          onConfirm: () => Navigator.of(context).pop(true),
        );
      },
    );
    if (!mounted) return;

    _isShowingPreloadDecisionDialog = false;
    if (accepted == true) {
      _startPreloadCountdown();
    }
  }

  void _startPreloadCountdown() {
    _preloadCountdownController.stop();
    _preloadTimerController.stop();
    _preloadCountdownController.reset();
    _preloadTimerController.reset();
    _feedbackController.dismiss();
    _sketchController
      ..clear()
      ..selectBrushColor(_brushColors.first)
      ..setToolMode(EndpointSketchToolMode.paint);
    _resetRecognitionPreview();

    setState(() {
      _preloadPhase = _OperativeSketchPreloadPhase.countdown;
    });
    _preloadCountdownController.forward(from: 0);
  }

  void _handlePreloadCountdownStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed ||
        !mounted ||
        !_isPreloadCountdown) {
      return;
    }

    _preloadTimerController.reset();
    setState(() {
      _preloadPhase = _OperativeSketchPreloadPhase.drawing;
    });
    _preloadTimerController.forward(from: 0);
  }

  void _handlePreloadTimerStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed ||
        !mounted ||
        !_isPreloadDrawing ||
        _isShowingPreloadDecisionDialog) {
      return;
    }

    unawaited(
      _showPreloadRetryDialog(
        message: 'Tiempo agotado. ¿Volver a intentar?',
      ),
    );
  }

  Future<void> _handlePreloadDonePressed() async {
    if (!_isPreloadDrawing || _isShowingPreloadDecisionDialog) return;

    _feedbackController.dismiss();
    if (!_sketchController.hasStrokes) {
      await _showPreloadRetryDialog(
        message: 'No hay trazo para precargar. ¿Volver a intentar?',
      );
      return;
    }

    final recognitionResult = _scanCurrentDrawing();
    final recognizedShapeCount = recognitionResult.totalCount;
    final allowedShapeCount = _preloadRecognizableShapeLimit;
    if (recognizedShapeCount > allowedShapeCount) {
      await _showPreloadRetryDialog(
        message:
            'Reconocidas $recognizedShapeCount formas. Permitidas $allowedShapeCount formas. ¿Volver a intentar?',
      );
      return;
    }

    PreparedSketchRuneStore.saveFromStrokes(_sketchController.strokes);
    _preloadCountdownController.reset();
    _preloadTimerController
      ..stop()
      ..reset();
    _feedbackController.show(
      label: 'RUNA PRECARGADA',
      color: EndpointPalette.rewardAccent,
    );
    setState(() {
      _preloadPhase = _OperativeSketchPreloadPhase.idle;
    });
  }

  Future<void> _showPreloadRetryDialog({
    required String message,
  }) async {
    if (_isShowingPreloadDecisionDialog) return;

    _preloadCountdownController.stop();
    _preloadTimerController.stop();
    _isShowingPreloadDecisionDialog = true;
    final shouldRetry = await showEndpointDialog<bool>(
      context: context,
      barrierLabel: 'Reintentar precarga de runa',
      barrierDismissible: false,
      barrierColor: EndpointPalette.overlayScrimStrong,
      builder: (context) {
        return _OperativeSketchPreloadRetryDialog(
          message: message,
          onCancel: () => Navigator.of(context).pop(false),
          onRetry: () => Navigator.of(context).pop(true),
        );
      },
    );
    if (!mounted) return;

    _isShowingPreloadDecisionDialog = false;
    if (shouldRetry == true) {
      _startPreloadCountdown();
      return;
    }

    _finishPreloadSession();
  }

  void _finishPreloadSession() {
    _preloadCountdownController
      ..stop()
      ..reset();
    _preloadTimerController
      ..stop()
      ..reset();
    setState(() {
      _preloadPhase = _OperativeSketchPreloadPhase.idle;
      _lastBonusResolution = _baseBonusResolution;
    });
  }

  OperativeSketchRecognitionResult _scanCurrentDrawing() {
    final canvasSize = _canvasSize;
    if (canvasSize == null ||
        canvasSize.isEmpty ||
        !_sketchController.hasStrokes) {
      return _emptyRecognitionResult;
    }

    return _recognitionHelper.scan(
      strokes: _sketchController.strokePointLists,
      canvasSize: canvasSize,
    );
  }

  /// Ejecuta el helper sobre el dibujo actual y lo traduce a feedback visual.
  BattleDrawingBonusResolution _runRecognitionScan({
    required bool showFeedback,
  }) {
    final canvasSize = _canvasSize;
    if (canvasSize == null || canvasSize.isEmpty) {
      return _baseBonusResolution;
    }

    final result = !_sketchController.hasStrokes
        ? _emptyRecognitionResult
        : _recognitionHelper.scan(
            strokes: _sketchController.strokePointLists,
            canvasSize: canvasSize,
          );
    final resolution = _bonusResolver.resolve(
      equippedItems: _bonusItems,
      recognizedCounts: _recognizedItemCountsFor(result),
      recognizedShapeCounts: _recognizedShapeCountsFor(result),
    );

    setState(() {
      _lastBonusResolution = resolution;
    });

    if (!showFeedback) {
      return resolution;
    }

    if (resolution.hasActivatedItems) {
      final groupedActivatedItems = BattleDrawingGrouping.groupBonusItems(
        resolution.activatedItems,
      );
      _feedbackController.showSequence(
        labels: groupedActivatedItems
            .map(
              (group) => group.count <= 1
                  ? group.specialBonus.description
                  : '${group.specialBonus.description} x${group.count}',
            )
            .toList(growable: false),
        color: EndpointPalette.rewardAccent,
      );
      return resolution;
    }
    return resolution;
  }

  Map<ItemBonusShape, int> _recognizedItemCountsFor(
    OperativeSketchRecognitionResult result,
  ) {
    final counts = <ItemBonusShape, int>{};
    for (final match in result.matches) {
      final shape = match.kind.itemBonusShape;
      if (shape == null || match.count <= 0) continue;
      counts.update(
        shape,
        (value) => value + match.count,
        ifAbsent: () => match.count,
      );
    }
    return counts;
  }

  Map<BattleDrawingShape, int> _recognizedShapeCountsFor(
    OperativeSketchRecognitionResult result,
  ) {
    final counts = <BattleDrawingShape, int>{};
    for (final match in result.matches) {
      final shape = match.kind.battleDrawingShape;
      if (shape == null || match.count <= 0) continue;
      counts.update(
        shape,
        (value) => value + match.count,
        ifAbsent: () => match.count,
      );
    }
    return counts;
  }

  /// Permite lanzar el escaneo bajo demanda desde el boton de comprobacion.
  void _handleCheckPressed() {
    _feedbackController.dismiss();
    if (!_sketchController.hasStrokes) {
      setState(() {
        _lastBonusResolution = _baseBonusResolution;
      });
      return;
    }
    _runRecognitionScan(showFeedback: true);
  }

  bool get _canUseQuickDraw {
    return PreparedSketchRuneStore.hasPreparedRune;
  }

  Future<void> _handleQuickDrawPressed() async {
    final canvasSize = _canvasSize;
    if (canvasSize == null ||
        canvasSize.isEmpty ||
        _isShowingQuickDrawPasteDialog) {
      return;
    }

    final preparedStrokes = PreparedSketchRuneStore.clonePreparedStrokes();
    if (preparedStrokes.isEmpty) {
      _feedbackController.show(
        label: 'Sin runa',
        color: EndpointPalette.warningAccent,
      );
      return;
    }

    _feedbackController.dismiss();
    _isShowingQuickDrawPasteDialog = true;
    final shouldPaste = await showEndpointDialog<bool>(
      context: context,
      barrierLabel: 'Confirmar Quick Draw',
      barrierColor: EndpointPalette.overlayScrimStrong,
      builder: (context) {
        return _OperativeSketchQuickDrawPromptDialog(
          onCancel: () => Navigator.of(context).pop(false),
          onConfirm: () => Navigator.of(context).pop(true),
        );
      },
    );
    if (!mounted) return;

    _isShowingQuickDrawPasteDialog = false;
    if (shouldPaste != true) {
      return;
    }

    final didClear = _sketchController.clear();
    final didPaste = _sketchController.pasteStrokesCentered(
      sourceStrokes: preparedStrokes,
      canvasSize: canvasSize,
    );
    if (didClear || didPaste) {
      _resetRecognitionPreview();
      setState(() {});
    }
    if (didPaste) {
      _feedbackController.show(
        label: 'QUICK DRAW',
        color: EndpointPalette.infoAccent,
      );
    }
  }

  Color _timerAccentFor(double remainingFactor) {
    if (remainingFactor > 0.66) {
      return EndpointPalette.primaryAccent;
    }
    if (remainingFactor > 0.33) {
      return EndpointPalette.warningAccent;
    }
    return EndpointPalette.dangerAccent;
  }

  /// Libera los temporizadores del overlay al cerrar la ventana.
  @override
  void dispose() {
    _feedbackController
      ..removeListener(_handleFeedbackChanged)
      ..dispose();
    _preloadCountdownController
      ..removeStatusListener(_handlePreloadCountdownStatus)
      ..dispose();
    _preloadTimerController
      ..removeStatusListener(_handlePreloadTimerStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sectionValue = _isPreloadSession
        ? (_isPreloadCountdown ? 'PREPARANDO' : 'PRECARGA')
        : _practiceMode == _OperativeSketchPracticeMode.attack
            ? 'ATAQUE'
            : 'BLOQUEO';

    return Stack(
      children: [
        EndpointOverlayScaffold(
          title: _isPreloadSession ? 'PRECARGA' : 'TRAZADO',
          subtitle: _isPreloadSession ? 'RUNA FAVORITA' : '',
          headerContent: _isPreloadSession
              ? null
              : _OperativeSketchPracticeTabs(
                  mode: _practiceMode,
                  onSelectMode: _selectPracticeMode,
                ),
          sectionLabel: 'PRACTICA',
          sectionValue: sectionValue,
          closeTooltip: 'Cerrar lienzo',
          accent: _isPreloadSession
              ? EndpointPalette.rewardAccent
              : EndpointPalette.infoAccent,
          bottomInset: 24,
          maxWidth: 540,
          maxHeight: _isPreloadSession ? 740 : 700,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _OperativeSketchBonusesStrip(
                bonusItemGroups: _bonusItemGroups,
                resolution: _lastBonusResolution,
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
                            _sketchCanvasBorderRadius,
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
                              blurRadius: 20,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            _sketchCanvasBorderRadius - 1,
                          ),
                          child: RawGestureDetector(
                            behavior: HitTestBehavior.opaque,
                            gestures: <Type, GestureRecognizerFactory>{
                              PanGestureRecognizer:
                                  GestureRecognizerFactoryWithHandlers<
                                      PanGestureRecognizer>(
                                () => PanGestureRecognizer(),
                                (PanGestureRecognizer recognizer) {
                                  recognizer
                                    ..onStart = _handlePanStart
                                    ..onUpdate = _handlePanUpdate
                                    ..onEnd = _handlePanEnd
                                    ..onCancel = () => _handlePanEnd(
                                          DragEndDetails(primaryVelocity: 0),
                                        );
                                },
                              ),
                              LongPressGestureRecognizer:
                                  GestureRecognizerFactoryWithHandlers<
                                      LongPressGestureRecognizer>(
                                () => LongPressGestureRecognizer(
                                  duration: _sketchMoveLongPressDuration,
                                ),
                                (LongPressGestureRecognizer recognizer) {
                                  recognizer
                                    ..onLongPressStart = _handleLongPressStart
                                    ..onLongPressMoveUpdate =
                                        _handleLongPressMoveUpdate
                                    ..onLongPressEnd = _handleLongPressEnd
                                    ..onLongPressCancel =
                                        _handleLongPressCancel;
                                },
                              ),
                            },
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: EndpointSketchPainter(
                                      strokes: _sketchController.strokes,
                                      noiseDots: _noiseDots,
                                      selectedStrokeIds:
                                          _sketchController.selectedStrokeIds,
                                      hasLiftedSelection:
                                          _sketchController.hasLiftedSelection,
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
                                if (!_isPreloadSession)
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: 12,
                                    child: Center(
                                      child: EndpointActionButton(
                                        label: 'QUICK DRAW',
                                        icon: Icons.auto_awesome_rounded,
                                        onPressed: _canUseQuickDraw
                                            ? () => unawaited(
                                                  _handleQuickDrawPressed(),
                                                )
                                            : null,
                                        tooltip: _canUseQuickDraw
                                            ? 'Pegar runa precargada en el centro'
                                            : 'No hay runa precargada',
                                        accent: EndpointPalette.infoAccent,
                                        backgroundColor: EndpointPalette.blend(
                                          EndpointPalette.panelBackgroundBattle,
                                          EndpointPalette.infoAccent,
                                          _canUseQuickDraw ? 0.18 : 0.05,
                                        ),
                                        foregroundColor: _canUseQuickDraw
                                            ? EndpointPalette.softForegroundWarm
                                            : EndpointPalette.softForeground,
                                        borderRadius: 999,
                                        borderWidth: 1.4,
                                        height: 34,
                                        useMarquee: false,
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
              if (_isPreloadSession) ...[
                _OperativeSketchPreloadTimerBar(
                  animation: _preloadTimerController,
                  duration: _sketchPreloadDrawingDuration,
                  accentBuilder: _timerAccentFor,
                ),
                const SizedBox(height: 10),
                _OperativeSketchPreloadControls(
                  hasStrokes: _sketchController.hasStrokes,
                  isEnabled: _isPreloadDrawing,
                  onUndo: _undoLastStroke,
                  onClear: _clearStrokes,
                  onCheck: _handleCheckPressed,
                  onDone: () => unawaited(_handlePreloadDonePressed()),
                ),
              ] else ...[
                Wrap(
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
                    _SketchToolModeButton(
                      icon: Icons.cleaning_services_rounded,
                      tooltip: 'Activar borrador',
                      accent: EndpointPalette.warningAccent,
                      isSelected: _sketchController.toolMode ==
                          EndpointSketchToolMode.erase,
                      onPressed: () =>
                          _selectToolMode(EndpointSketchToolMode.erase),
                    ),
                    _SketchToolModeButton(
                      icon: Icons.pan_tool_alt_rounded,
                      tooltip: 'Activar mano para mover trazos conectados',
                      accent: EndpointPalette.infoAccent,
                      isSelected: _sketchController.toolMode ==
                          EndpointSketchToolMode.move,
                      onPressed: () =>
                          _selectToolMode(EndpointSketchToolMode.move),
                    ),
                    _SketchCircularActionButton(
                      icon: Icons.undo_rounded,
                      tooltip: 'Eliminar el ultimo trazo',
                      accent: EndpointPalette.primaryAccent,
                      isEnabled: _sketchController.hasStrokes,
                      onPressed: _undoLastStroke,
                    ),
                    _SketchCircularActionButton(
                      icon: Icons.layers_clear_rounded,
                      tooltip: 'Borrar todos los trazos',
                      accent: EndpointPalette.infoAccent,
                      isEnabled: _sketchController.hasStrokes,
                      onPressed: _clearStrokes,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: EndpointActionButton(
                        label: 'CHECK',
                        icon: Icons.fact_check_rounded,
                        onPressed: _handleCheckPressed,
                        tooltip: 'Escanear el dibujo actual',
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
                    const SizedBox(width: 8),
                    Expanded(
                      child: EndpointActionButton(
                        label: 'Precargar Runas',
                        icon: Icons.auto_fix_high_rounded,
                        onPressed: () => unawaited(_handlePreloadPressed()),
                        tooltip: 'Activar precarga de runas',
                        accent: EndpointPalette.rewardAccent,
                        backgroundColor: EndpointPalette.blend(
                          EndpointPalette.panelBackground,
                          EndpointPalette.rewardAccent,
                          0.1,
                        ),
                        foregroundColor: EndpointPalette.softForeground,
                        height: 44,
                        useMarquee: false,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (_isPreloadCountdown)
          Positioned.fill(
            child: _OperativeSketchPreloadCountdownOverlay(
              animation: _preloadCountdownController,
              duration: _sketchPreloadWarmupDuration,
            ),
          ),
      ],
    );
  }
}

class _OperativeSketchQuickDrawPromptDialog extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _OperativeSketchQuickDrawPromptDialog({
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return _OperativeSketchPreloadDecisionPanel(
      title: 'QUICK DRAW',
      message: '¿Limpiar el canvas actual para pegar el trazo guardado?',
      confirmLabel: 'Si',
      confirmAccent: EndpointPalette.infoAccent,
      onCancel: onCancel,
      onConfirm: onConfirm,
    );
  }
}

class _OperativeSketchPreloadPromptDialog extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _OperativeSketchPreloadPromptDialog({
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return _OperativeSketchPreloadDecisionPanel(
      title: 'PRECARGAR RUNAS',
      message:
          'Para precargar un trazo, deberás dibujarlo en un tiempo de 15 segundos. '
          'El dibujo no puede contener más formas reconocibles que tu límite de equipamiento. '
          'Cada hueco libre en tu equipamiento sumará 1 al límite de formas reconocibles. '
          '¿Preparado?',
      confirmLabel: 'Si',
      confirmAccent: EndpointPalette.rewardAccent,
      onCancel: onCancel,
      onConfirm: onConfirm,
    );
  }
}

class _OperativeSketchPreloadRetryDialog extends StatelessWidget {
  final String message;
  final VoidCallback onCancel;
  final VoidCallback onRetry;

  const _OperativeSketchPreloadRetryDialog({
    required this.message,
    required this.onCancel,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return _OperativeSketchPreloadDecisionPanel(
      title: 'PRECARGA RECHAZADA',
      message: message,
      confirmLabel: 'Si',
      confirmAccent: EndpointPalette.warningAccent,
      onCancel: onCancel,
      onConfirm: onRetry,
    );
  }
}

class _OperativeSketchPreloadDecisionPanel extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final Color confirmAccent;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _OperativeSketchPreloadDecisionPanel({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.confirmAccent,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: EndpointPanel(
            accent: confirmAccent,
            backgroundColor: EndpointPalette.panelBackgroundBattleOpaque,
            borderRadius: 18,
            glowOpacity: 0.1,
            blurRadius: 24,
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EndpointText(
                  title,
                  style: textMediumBold.copyWith(
                    color: confirmAccent,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                EndpointText(
                  message,
                  maxLines: null,
                  style: textMedium.copyWith(
                    color: EndpointPalette.softForeground.withValues(
                      alpha: 0.86,
                    ),
                    height: 1.18,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: EndpointActionButton(
                        label: 'No',
                        onPressed: onCancel,
                        accent: EndpointPalette.primaryAccent,
                        backgroundColor: EndpointPalette.closeButtonBackground,
                        foregroundColor: EndpointPalette.softForeground,
                        height: 42,
                        useMarquee: false,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: EndpointActionButton(
                        label: confirmLabel,
                        onPressed: onConfirm,
                        accent: confirmAccent,
                        backgroundColor: EndpointPalette.blend(
                          EndpointPalette.panelBackgroundBattle,
                          confirmAccent,
                          0.28,
                        ),
                        foregroundColor: EndpointPalette.softForegroundWarm,
                        height: 42,
                        useMarquee: false,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OperativeSketchPreloadCountdownOverlay extends StatelessWidget {
  final Animation<double> animation;
  final Duration duration;

  const _OperativeSketchPreloadCountdownOverlay({
    required this.animation,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: EndpointPalette.overlayScrimStrong.withValues(alpha: 0.72),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              final remainingFactor = (1 - animation.value).clamp(0.0, 1.0);
              final remainingMillis =
                  (duration.inMilliseconds * remainingFactor).ceil();
              final remainingSeconds = max(
                1,
                (remainingMillis / 1000).ceil(),
              );

              return EndpointText(
                '$remainingSeconds',
                style: textTitleMediumBold.copyWith(
                  color: EndpointPalette.softForegroundWarm,
                  fontSize: 92,
                  letterSpacing: 0,
                  shadows: [
                    Shadow(
                      color: EndpointPalette.rewardAccent.withValues(
                        alpha: 0.74,
                      ),
                      blurRadius: 28,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _OperativeSketchPreloadTimerBar extends StatelessWidget {
  final Animation<double> animation;
  final Duration duration;
  final Color Function(double remainingFactor) accentBuilder;

  const _OperativeSketchPreloadTimerBar({
    required this.animation,
    required this.duration,
    required this.accentBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final remainingFactor = (1 - animation.value).clamp(0.0, 1.0);
        final remainingMillis =
            (duration.inMilliseconds * remainingFactor).ceil();
        final remainingSeconds = max(
          0,
          (remainingMillis / 1000).ceil(),
        );
        final accent = accentBuilder(remainingFactor);

        return EndpointPanel(
          accent: accent,
          backgroundColor: EndpointPalette.panelBackgroundBattle,
          borderRadius: 12,
          glowOpacity: 0.06,
          blurRadius: 18,
          spreadRadius: 1,
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EndpointText(
                'TIEMPO RESTANTE',
                style: textSmallBold.copyWith(
                  color: accent,
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 6),
              Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: remainingFactor,
                      minHeight: 16,
                      backgroundColor: EndpointPalette.softForeground
                          .withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                    ),
                  ),
                  EndpointText(
                    '$remainingSeconds s',
                    style: textSmallNumericBold.copyWith(
                      color: EndpointPalette.panelBackgroundOpaque,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OperativeSketchPreloadControls extends StatelessWidget {
  final bool hasStrokes;
  final bool isEnabled;
  final VoidCallback onUndo;
  final VoidCallback onClear;
  final VoidCallback onCheck;
  final VoidCallback onDone;

  const _OperativeSketchPreloadControls({
    required this.hasStrokes,
    required this.isEnabled,
    required this.onUndo,
    required this.onClear,
    required this.onCheck,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: EndpointActionButton(
            label: 'UNDO',
            icon: Icons.undo_rounded,
            onPressed: isEnabled && hasStrokes ? onUndo : null,
            tooltip: 'Eliminar el ultimo trazo',
            accent: EndpointPalette.primaryAccent,
            backgroundColor: EndpointPalette.closeButtonBackground,
            foregroundColor: EndpointPalette.softForeground,
            height: 42,
            textStyle: textSmallBold,
            useMarquee: false,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: EndpointActionButton(
            label: 'LIMPIAR',
            icon: Icons.layers_clear_rounded,
            onPressed: isEnabled && hasStrokes ? onClear : null,
            tooltip: 'Borrar todos los trazos',
            accent: EndpointPalette.infoAccent,
            backgroundColor: EndpointPalette.closeButtonBackground,
            foregroundColor: EndpointPalette.softForeground,
            height: 42,
            textStyle: textSmallBold,
            useMarquee: false,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: EndpointActionButton(
            label: 'CHECK',
            icon: Icons.fact_check_rounded,
            onPressed: isEnabled ? onCheck : null,
            tooltip: 'Escanear el dibujo actual',
            accent: EndpointPalette.warningAccent,
            backgroundColor: EndpointPalette.blend(
              EndpointPalette.panelBackground,
              EndpointPalette.warningAccent,
              0.1,
            ),
            foregroundColor: EndpointPalette.softForegroundWarm,
            height: 42,
            textStyle: textSmallBold,
            useMarquee: false,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: EndpointActionButton(
            label: 'DONE',
            icon: Icons.done_rounded,
            onPressed: isEnabled ? onDone : null,
            tooltip: 'Guardar el trazo para Quick Draw',
            accent: EndpointPalette.rewardAccent,
            backgroundColor: EndpointPalette.blend(
              EndpointPalette.panelBackground,
              EndpointPalette.rewardAccent,
              0.16,
            ),
            foregroundColor: EndpointPalette.softForegroundWarm,
            height: 42,
            textStyle: textSmallBold,
            useMarquee: false,
          ),
        ),
      ],
    );
  }
}

class _OperativeSketchPracticeTabs extends StatelessWidget {
  final _OperativeSketchPracticeMode mode;
  final ValueChanged<_OperativeSketchPracticeMode> onSelectMode;

  const _OperativeSketchPracticeTabs({
    required this.mode,
    required this.onSelectMode,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _OperativeSketchPracticeTabButton(
            label: 'Ataque',
            icon: Icons.flash_on_rounded,
            isSelected: mode == _OperativeSketchPracticeMode.attack,
            accent: EndpointPalette.warningAccent,
            onPressed: () => onSelectMode(_OperativeSketchPracticeMode.attack),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _OperativeSketchPracticeTabButton(
            label: 'Bloqueo',
            icon: Icons.shield_rounded,
            isSelected: mode == _OperativeSketchPracticeMode.defense,
            accent: EndpointPalette.infoAccent,
            onPressed: () => onSelectMode(_OperativeSketchPracticeMode.defense),
          ),
        ),
      ],
    );
  }
}

class _OperativeSketchPracticeTabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color accent;
  final VoidCallback onPressed;

  const _OperativeSketchPracticeTabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.accent,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return EndpointActionButton(
      label: label,
      icon: icon,
      onPressed: onPressed,
      tooltip: 'Cambiar practica a $label',
      accent: accent,
      backgroundColor: EndpointPalette.blend(
        EndpointPalette.panelBackground,
        accent,
        isSelected ? 0.2 : 0.08,
      ),
      foregroundColor: isSelected
          ? EndpointPalette.softForegroundWarm
          : EndpointPalette.softForeground,
      height: 40,
      useMarquee: false,
    );
  }
}

class _OperativeSketchBonusesStrip extends StatelessWidget {
  final List<BattleDrawingItemBonusGroup> bonusItemGroups;
  final BattleDrawingBonusResolution resolution;

  const _OperativeSketchBonusesStrip({
    required this.bonusItemGroups,
    required this.resolution,
  });

  @override
  Widget build(BuildContext context) {
    if (bonusItemGroups.isEmpty) {
      return EndpointPanel(
        accent: EndpointPalette.neutralAccent,
        backgroundColor: EndpointPalette.panelBackgroundSoft,
        borderRadius: 12,
        glowOpacity: 0.04,
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: EndpointText(
          'No hay bonuses de dibujo en el equipo actual.',
          maxLines: null,
          style: textSmallBold.copyWith(
            color: EndpointPalette.softForeground.withValues(alpha: 0.86),
            letterSpacing: 0.6,
          ),
        ),
      );
    }

    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (int index = 0; index < bonusItemGroups.length; index++)
            Padding(
              padding: EdgeInsets.only(
                right: index == bonusItemGroups.length - 1 ? 0 : 8,
              ),
              child: _OperativeSketchBonusCard(
                title: bonusItemGroups[index].representativeItem.displayName,
                subtitle: bonusItemGroups[index].specialBonus.description,
                emoji: bonusItemGroups[index].representativeItem.iconEmoji,
                shape: bonusItemGroups[index].requiredShape,
                accent: _shapeAccent(
                  bonusItemGroups[index].representativeItem.bonusShape,
                ),
                repeatCount: bonusItemGroups[index].count,
                isActivated: resolution
                    .isItemActivated(bonusItemGroups[index].representativeItem),
              ),
            ),
        ],
      ),
    );
  }

  static Color _shapeAccent(ItemBonusShape shape) {
    switch (shape) {
      case ItemBonusShape.triangle:
        return EndpointPalette.warningAccent;
      case ItemBonusShape.square:
        return EndpointPalette.infoAccent;
      case ItemBonusShape.circle:
        return EndpointPalette.primaryAccent;
    }
  }
}

class _OperativeSketchBonusCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String emoji;
  final BattleDrawingShape shape;
  final Color accent;
  final bool isActivated;
  final int repeatCount;

  const _OperativeSketchBonusCard({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.shape,
    required this.accent,
    required this.isActivated,
    this.repeatCount = 1,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isActivated
        ? accent.withValues(alpha: 0.92)
        : EndpointPalette.softForeground.withValues(alpha: 0.24);
    final glowColor =
        isActivated ? accent.withValues(alpha: 0.18) : Colors.transparent;

    return SizedBox(
      width: 88,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: EndpointPanel(
              accent: accent,
              backgroundColor: EndpointPalette.blend(
                EndpointPalette.panelBackground,
                accent,
                isActivated ? 0.12 : 0.05,
              ),
              borderRadius: 12,
              glowOpacity: isActivated ? 0.16 : 0,
              blurRadius: 18,
              spreadRadius: 1,
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: glowColor,
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
                  child: Column(
                    children: [
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Center(
                              child: Opacity(
                                opacity: 0.18,
                                child: EndpointText(
                                  emoji,
                                  style: const TextStyle(fontSize: 34),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Center(
                                  child: AspectRatio(
                                    aspectRatio: 1,
                                    child: CustomPaint(
                                      painter: _OperativeSketchShapePainter(
                                        shape: shape,
                                        strokeColor: accent,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      EndpointText(
                        title,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: textSmallBold.copyWith(
                          color: EndpointPalette.softForeground,
                          fontSize: 9,
                          letterSpacing: 0.4,
                        ),
                      ),
                      EndpointText(
                        subtitle,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: textSmallBold.copyWith(
                          color: accent.withValues(alpha: 0.86),
                          fontSize: 8,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (repeatCount > 1)
            Positioned(
              top: -6,
              right: -6,
              child: _OperativeSketchRepeatBadge(
                count: repeatCount,
                accent: accent,
              ),
            ),
        ],
      ),
    );
  }
}

class _OperativeSketchRepeatBadge extends StatelessWidget {
  final int count;
  final Color accent;

  const _OperativeSketchRepeatBadge({
    required this.count,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: EndpointPalette.blend(
          EndpointPalette.panelBackgroundOpaque,
          accent,
          0.26,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: accent.withValues(alpha: 0.95),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.22),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: EndpointText(
          'x$count',
          style: textSmallNumericBold.copyWith(
            color: EndpointPalette.softForeground,
            fontSize: 9,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _OperativeSketchShapePainter extends CustomPainter {
  final BattleDrawingShape shape;
  final Color strokeColor;

  const _OperativeSketchShapePainter({
    required this.shape,
    required this.strokeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final isAngularShape = shape != BattleDrawingShape.circle;
    final glowPaint = Paint()
      ..color = strokeColor.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = isAngularShape ? StrokeJoin.miter : StrokeJoin.round
      ..strokeWidth = 7
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final corePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = isAngularShape ? StrokeJoin.miter : StrokeJoin.round
      ..strokeWidth = 3.4;

    if (shape == BattleDrawingShape.scissors) {
      _paintScissors(canvas, size, glowPaint, corePaint);
      return;
    }

    final path = _shapePath(size);
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, corePaint);
  }

  Path _shapePath(Size size) {
    Offset fromUnit(double dx, double dy) =>
        Offset(size.width * dx, size.height * dy);

    switch (shape) {
      case BattleDrawingShape.triangle:
        return Path()
          ..moveTo(size.width * 0.5, size.height * 0.16)
          ..lineTo(size.width * 0.79, size.height * 0.78)
          ..lineTo(size.width * 0.21, size.height * 0.78)
          ..close();
      case BattleDrawingShape.square:
        return Path()
          ..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromPoints(
                fromUnit(0.24, 0.24),
                fromUnit(0.76, 0.76),
              ),
              const Radius.circular(2),
            ),
          );
      case BattleDrawingShape.circle:
        return Path()
          ..addOval(
            Rect.fromCenter(
              center: Offset(size.width * 0.5, size.height * 0.5),
              width: size.width * 0.56,
              height: size.height * 0.56,
            ),
          );
      case BattleDrawingShape.scissors:
        return Path();
    }
  }

  void _paintScissors(
    Canvas canvas,
    Size size,
    Paint glowPaint,
    Paint corePaint,
  ) {
    final bladePath = Path()
      ..moveTo(size.width * 0.2, size.height * 0.2)
      ..lineTo(size.width * 0.8, size.height * 0.78)
      ..moveTo(size.width * 0.8, size.height * 0.2)
      ..lineTo(size.width * 0.2, size.height * 0.78);
    canvas.drawPath(bladePath, glowPaint);
    canvas.drawPath(bladePath, corePaint);

    final leftHandle = Rect.fromCircle(
      center: Offset(size.width * 0.35, size.height * 0.72),
      radius: size.shortestSide * 0.13,
    );
    final rightHandle = Rect.fromCircle(
      center: Offset(size.width * 0.65, size.height * 0.72),
      radius: size.shortestSide * 0.13,
    );
    canvas.drawOval(leftHandle, glowPaint);
    canvas.drawOval(leftHandle, corePaint);
    canvas.drawOval(rightHandle, glowPaint);
    canvas.drawOval(rightHandle, corePaint);
  }

  @override
  bool shouldRepaint(covariant _OperativeSketchShapePainter oldDelegate) {
    return oldDelegate.shape != shape || oldDelegate.strokeColor != strokeColor;
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

/// Boton de herramienta circular para borrar o mover trazos del lienzo.
class _SketchToolModeButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color accent;
  final bool isSelected;
  final VoidCallback onPressed;

  const _SketchToolModeButton({
    required this.icon,
    required this.tooltip,
    required this.accent,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isSelected
        ? EndpointPalette.blend(
            EndpointPalette.panelBackground,
            accent,
            0.22,
          )
        : EndpointPalette.panelBackgroundOpaque.withValues(alpha: 0.74);

    return Tooltip(
      message: tooltip,
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
                    isSelected ? accent : Colors.white.withValues(alpha: 0.26),
                width: isSelected ? 2 : 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: isSelected ? 0.3 : 0.12),
                  blurRadius: isSelected ? 12 : 6,
                  spreadRadius: isSelected ? 1 : 0,
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 16,
              color: isSelected
                  ? EndpointPalette.softForegroundWarm
                  : EndpointPalette.softForeground,
            ),
          ),
        ),
      ),
    );
  }
}

/// Boton circular de accion rapida para utilidades puntuales del lienzo.
class _SketchCircularActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color accent;
  final bool isEnabled;
  final VoidCallback onPressed;

  const _SketchCircularActionButton({
    required this.icon,
    required this.tooltip,
    required this.accent,
    required this.isEnabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = EndpointPalette.panelBackgroundOpaque.withValues(
      alpha: isEnabled ? 0.78 : 0.5,
    );

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkResponse(
          onTap: isEnabled ? onPressed : null,
          radius: 22,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: backgroundColor,
              border: Border.all(
                color: isEnabled
                    ? accent.withValues(alpha: 0.9)
                    : Colors.white.withValues(alpha: 0.18),
                width: isEnabled ? 1.8 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: isEnabled ? 0.24 : 0.06),
                  blurRadius: isEnabled ? 10 : 4,
                  spreadRadius: isEnabled ? 1 : 0,
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 16,
              color: isEnabled
                  ? EndpointPalette.softForeground
                  : EndpointPalette.softForeground.withValues(alpha: 0.46),
            ),
          ),
        ),
      ),
    );
  }
}

extension on OperativeSketchRecognitionKind {
  BattleDrawingShape? get battleDrawingShape {
    switch (this) {
      case OperativeSketchRecognitionKind.none:
        return null;
      case OperativeSketchRecognitionKind.triangle:
        return BattleDrawingShape.triangle;
      case OperativeSketchRecognitionKind.square:
        return BattleDrawingShape.square;
      case OperativeSketchRecognitionKind.circle:
        return BattleDrawingShape.circle;
      case OperativeSketchRecognitionKind.scissors:
        return BattleDrawingShape.scissors;
    }
  }
}
