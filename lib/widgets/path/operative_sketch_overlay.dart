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
const _sketchPreloadExtraHoldDuration = Duration(milliseconds: 300);
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
  final BattleDrawingBonusResolver _bonusResolver =
      const BattleDrawingBonusResolver();
  final BattleDrawingEligibleItemPlanner _eligibleItemPlanner =
      const BattleDrawingEligibleItemPlanner();
  Timer? _pendingPreloadTimer;
  bool _isPreloadModeEnabled = false;
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
    if (_practiceMode == mode) return;

    _feedbackController.dismiss();
    setState(() {
      _practiceMode = mode;
      _rebuildPracticeBonuses();
    });
  }

  /// Inicia un trazo nuevo usando el color seleccionado en la paleta visible.
  void _handlePanStart(DragStartDetails details) {
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
    _sketchController.handlePanEnd();
  }

  /// Selecciona y levanta un bloque de trazos conectados cuando la herramienta mano esta activa.
  void _handleLongPressStart(LongPressStartDetails details) {
    if (_isPreloadModeEnabled) {
      _schedulePreloadCapture(details.localPosition);
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
    if (_isPreloadModeEnabled) {
      _cancelPendingPreload();
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
    _cancelPendingPreload();
    if (_isPreloadModeEnabled) {
      return;
    }

    if (_sketchController.endMoveSelection()) {
      setState(() {});
    }
  }

  void _handleLongPressCancel() {
    _cancelPendingPreload();
    if (_isPreloadModeEnabled) {
      return;
    }

    if (_sketchController.endMoveSelection()) {
      setState(() {});
    }
  }

  /// Limpia manualmente todos los trazos visibles del lienzo.
  void _clearStrokes() {
    _feedbackController.dismiss();
    if (_sketchController.clear()) {
      _resetRecognitionPreview();
      setState(() {});
    }
  }

  /// Deshace el ultimo trazo completo del lienzo.
  void _undoLastStroke() {
    _feedbackController.dismiss();
    if (_sketchController.undoLastStroke()) {
      _resetRecognitionPreview();
      setState(() {});
    }
  }

  /// Cambia el color del pincel que usara el siguiente trazo del jugador.
  void _selectBrushColor(Color color) {
    if (_sketchController.selectBrushColor(color)) {
      setState(() {});
    }
  }

  /// Cambia de forma explicita la herramienta activa del lienzo.
  void _selectToolMode(EndpointSketchToolMode mode) {
    _feedbackController.dismiss();
    _cancelPendingPreload();
    if (_sketchController.setToolMode(mode)) {
      setState(() {});
    }
  }

  void _togglePreloadMode() {
    _feedbackController.dismiss();
    _cancelPendingPreload();
    setState(() {
      _isPreloadModeEnabled = !_isPreloadModeEnabled;
    });
  }

  void _schedulePreloadCapture(Offset position) {
    _cancelPendingPreload();
    _pendingPreloadTimer = Timer(_sketchPreloadExtraHoldDuration, () {
      _pendingPreloadTimer = null;
      if (!mounted || !_isPreloadModeEnabled) {
        return;
      }
      _capturePreloadedRuneAt(position);
    });
  }

  void _cancelPendingPreload() {
    _pendingPreloadTimer?.cancel();
    _pendingPreloadTimer = null;
  }

  void _capturePreloadedRuneAt(Offset position) {
    final connectedStrokes = _sketchController.exportConnectedStrokesAt(
      position,
    );
    if (connectedStrokes.isEmpty) {
      _feedbackController.show(
        label: 'Sin trazo',
        color: EndpointPalette.warningAccent,
      );
      return;
    }

    PreparedSketchRuneStore.saveFromStrokes(connectedStrokes);
    _feedbackController.show(
      label: 'RUNA PRECARGADA',
      color: EndpointPalette.rewardAccent,
    );
    setState(() {});
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

  void _handleQuickDrawPressed() {
    final canvasSize = _canvasSize;
    if (canvasSize == null || canvasSize.isEmpty) {
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
    if (_sketchController.pasteStrokesCentered(
      sourceStrokes: preparedStrokes,
      canvasSize: canvasSize,
    )) {
      _resetRecognitionPreview();
      _feedbackController.show(
        label: 'QUICK DRAW',
        color: EndpointPalette.infoAccent,
      );
      setState(() {});
    }
  }

  /// Libera los temporizadores del overlay al cerrar la ventana.
  @override
  void dispose() {
    _cancelPendingPreload();
    _feedbackController
      ..removeListener(_handleFeedbackChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EndpointOverlayScaffold(
      title: 'TRAZADO',
      headerContent: _OperativeSketchPracticeTabs(
        mode: _practiceMode,
        onSelectMode: _selectPracticeMode,
      ),
      sectionLabel: 'PRACTICA',
      sectionValue: _practiceMode == _OperativeSketchPracticeMode.attack
          ? 'ATAQUE'
          : 'BLOQUEO',
      closeTooltip: 'Cerrar lienzo',
      accent: EndpointPalette.infoAccent,
      bottomInset: 24,
      maxWidth: 540,
      maxHeight: 700,
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
                                ..onLongPressCancel = _handleLongPressCancel;
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
                                      feedback: _feedbackController.feedback,
                                      lifetime:
                                          _sketchRecognitionFeedbackLifetime,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 12,
                              child: Center(
                                child: EndpointActionButton(
                                  label: 'QUICK DRAW',
                                  icon: Icons.auto_awesome_rounded,
                                  onPressed:
                                      _canUseQuickDraw
                                          ? _handleQuickDrawPressed
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
                isSelected:
                    _sketchController.toolMode == EndpointSketchToolMode.erase,
                onPressed: () => _selectToolMode(EndpointSketchToolMode.erase),
              ),
              _SketchToolModeButton(
                icon: Icons.pan_tool_alt_rounded,
                tooltip: 'Activar mano para mover trazos conectados',
                accent: EndpointPalette.infoAccent,
                isSelected:
                    _sketchController.toolMode == EndpointSketchToolMode.move,
                onPressed: () => _selectToolMode(EndpointSketchToolMode.move),
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
                  onPressed: _togglePreloadMode,
                  tooltip: _isPreloadModeEnabled
                      ? 'Modo precarga activo: manten pulsado un trazo para guardarlo'
                      : 'Activar modo precarga de runas',
                  accent: EndpointPalette.rewardAccent,
                  backgroundColor: EndpointPalette.blend(
                    EndpointPalette.panelBackground,
                    EndpointPalette.rewardAccent,
                    _isPreloadModeEnabled ? 0.2 : 0.1,
                  ),
                  foregroundColor: _isPreloadModeEnabled
                      ? EndpointPalette.softForegroundWarm
                      : EndpointPalette.softForeground,
                  height: 44,
                  useMarquee: false,
                ),
              ),
            ],
          ),
        ],
      ),
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
