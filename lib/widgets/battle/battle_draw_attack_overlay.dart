import '../_imports.dart';
import '../path/operative_sketch_recognition_helper.dart';
import '../../services/battle_drawing_bonus_resolver.dart';
import '../../services/run_randomizer.dart';

const _battleSketchCanvasBorderRadius = 20.0;
const _battleSketchNoiseSeed = 9187;
const _battleSketchFeedbackLifetime = Duration(seconds: 1);
const _battleSketchFeedbackGap = Duration(milliseconds: 500);
const _battleSketchMissAccent = Color(0xFFC178FF);
const _battleSketchEnemyMalusAccent = Color(0xFFF95A62);
const _battleSketchEraserRadius = 18.0;
const _battleSketchDuration = Duration(seconds: 20);
const _attackBonusHooks = <ItemEffectHook>{
  ItemEffectHook.attackResolved,
  ItemEffectHook.turnStart,
  ItemEffectHook.turnEnd,
};
const _attackEnemyMalusHooks = <ItemEffectHook>{
  ItemEffectHook.receiveDamageResolved,
  ItemEffectHook.defendResolved,
  ItemEffectHook.turnStart,
  ItemEffectHook.turnEnd,
};

class BattleDrawAttackOverlay extends StatefulWidget {
  final Battler attacker;
  final Battler defender;
  final int playerInitialBarrier;
  final RunRandomizer randomizer;
  final bool isQuickDrawAvailable;

  const BattleDrawAttackOverlay({
    super.key,
    required this.attacker,
    required this.defender,
    required this.playerInitialBarrier,
    required this.randomizer,
    required this.isQuickDrawAvailable,
  });

  @override
  State<BattleDrawAttackOverlay> createState() =>
      _BattleDrawAttackOverlayState();
}

class _BattleDrawAttackOverlayState extends State<BattleDrawAttackOverlay>
    with SingleTickerProviderStateMixin {
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
  final BattleDrawingEnemyNuisancePlanner _enemyNuisancePlanner =
      const BattleDrawingEnemyNuisancePlanner();
  late final EndpointSketchCanvasController _sketchController;
  late final EndpointSketchFeedbackController _feedbackController;
  late final List<EndpointSketchNoiseDot> _noiseDots;
  late final List<Item> _bonusItems;
  late final List<BattleDrawingItemBonusGroup> _bonusItemGroups;
  late final List<BattleDrawingEnemyNuisance> _enemyNuisances;
  late final List<BattleDrawingEnemyNuisanceGroup> _enemyNuisanceGroups;
  late final AnimationController _timerController = AnimationController(
    vsync: this,
    duration: _battleSketchDuration,
  )..addStatusListener(_handleTimerStatus);

  Size? _canvasSize;
  int _nextBrushColorIndex = 0;
  bool _isSubmitting = false;
  bool _hasConsumedQuickDraw = false;
  late final BattleDrawingBonusResolution _baseBonusResolution;
  OperativeSketchRecognitionResult _lastRecognitionResult =
      _emptyRecognitionResult;
  late BattleDrawingBonusResolution _lastBonusResolution;

  @override
  void initState() {
    super.initState();
    _bonusItems = _eligibleItemPlanner.equippedItemsForHooks(
      battler: widget.attacker,
      hooks: _attackBonusHooks,
    );
    final enemyMalusItems = _eligibleItemPlanner.equippedItemsForHooks(
      battler: widget.defender,
      hooks: _attackEnemyMalusHooks,
    );
    _enemyNuisances = _enemyNuisancePlanner.build(
      player: widget.attacker,
      enemy: widget.defender,
      playerInitialBarrier: widget.playerInitialBarrier,
      randomizer: widget.randomizer,
      enemyItems: enemyMalusItems,
    );
    _bonusItemGroups = BattleDrawingGrouping.groupBonusItems(_bonusItems);
    _enemyNuisanceGroups =
        BattleDrawingGrouping.groupNuisances(_enemyNuisances);
    _sketchController = EndpointSketchCanvasController(
      initialBrushColor: _brushColors.first,
      eraserRadius: _battleSketchEraserRadius,
    );
    _feedbackController = EndpointSketchFeedbackController(
      lifetime: _battleSketchFeedbackLifetime,
      gap: _battleSketchFeedbackGap,
    )..addListener(_handleFeedbackChanged);
    _noiseDots = buildEndpointSketchNoiseDots(
      seed: _battleSketchNoiseSeed,
      count: 260,
      radiusDelta: 1.3,
    );
    _baseBonusResolution = _bonusResolver.resolve(
      equippedItems: _bonusItems,
      recognizedCounts: const <ItemBonusShape, int>{},
      recognizedShapeCounts: const <BattleDrawingShape, int>{},
      enemyNuisances: _enemyNuisances,
    );
    _lastBonusResolution = _baseBonusResolution;
    _timerController.forward();
  }

  void _handleFeedbackChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _handleTimerStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _isSubmitting) return;
    unawaited(_submitAttack(autoTriggered: true));
  }

  void _handlePanStart(DragStartDetails details) {
    _feedbackController.dismiss();
    _invalidatePreview();
    _advanceBrushColor();
    if (_sketchController.handlePanStart(details.localPosition)) {
      setState(() {});
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final didChange = _sketchController.handlePanUpdate(details.localPosition);
    if (!didChange) return;

    setState(() {});
  }

  void _handlePanEnd(DragEndDetails details) {
    _sketchController.handlePanEnd();
  }

  void _clearStrokes() {
    if (!_sketchController.hasStrokes) return;
    _feedbackController.dismiss();
    if (_sketchController.clear()) {
      setState(() {});
    }
    _invalidatePreview();
  }

  void _undoLastStroke() {
    if (!_sketchController.hasStrokes) return;
    _feedbackController.dismiss();
    if (_sketchController.undoLastStroke()) {
      setState(() {});
    }
    _invalidatePreview();
  }

  void _advanceBrushColor() {
    if (_brushColors.isEmpty) return;
    final color = _brushColors[_nextBrushColorIndex % _brushColors.length];
    _nextBrushColorIndex = (_nextBrushColorIndex + 1) % _brushColors.length;
    _sketchController.selectBrushColor(color);
  }

  void _invalidatePreview() {
    if (_lastRecognitionResult == _emptyRecognitionResult &&
        identical(_lastBonusResolution, _baseBonusResolution)) {
      return;
    }

    setState(() {
      _lastRecognitionResult = _emptyRecognitionResult;
      _lastBonusResolution = _baseBonusResolution;
    });
  }

  void _handleCheckPressed() {
    _runRecognitionScan(showFeedback: true);
  }

  bool get _canUseQuickDraw {
    return widget.isQuickDrawAvailable &&
        !_hasConsumedQuickDraw &&
        PreparedSketchRuneStore.hasPreparedRune;
  }

  void _handleQuickDrawPressed() {
    final canvasSize = _canvasSize;
    if (canvasSize == null || canvasSize.isEmpty || !_canUseQuickDraw) {
      return;
    }

    final preparedStrokes = PreparedSketchRuneStore.clonePreparedStrokes();
    if (preparedStrokes.isEmpty) {
      return;
    }

    _feedbackController.dismiss();
    if (_sketchController.pasteStrokesCentered(
      sourceStrokes: preparedStrokes,
      canvasSize: canvasSize,
    )) {
      _invalidatePreview();
      _feedbackController.show(
        label: 'QUICK DRAW',
        color: EndpointPalette.infoAccent,
      );
      setState(() {
        _hasConsumedQuickDraw = true;
      });
    }
  }

  Future<void> _submitAttack({required bool autoTriggered}) async {
    if (_isSubmitting) return;

    final resolution = _runRecognitionScan(showFeedback: !autoTriggered);
    final overlayResult = BattleDrawOverlayResult(
      resolution: resolution,
      consumedQuickDraw: _hasConsumedQuickDraw,
      achievedPerfect: _isPerfectResolution(resolution),
    );
    setState(() {
      _isSubmitting = true;
    });

    if (!mounted) return;
    Navigator.of(context).pop(overlayResult);
  }

  bool _isPerfectResolution(BattleDrawingBonusResolution resolution) {
    final hasNeutralizedAllNuisances = !resolution.hasTriggeredNuisances;
    final hasActivatedAllBonuses =
        resolution.activatedItems.length >= _bonusItems.length;
    return hasNeutralizedAllNuisances && hasActivatedAllBonuses;
  }

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
      enemyNuisances: _enemyNuisances,
    );

    setState(() {
      _lastRecognitionResult = result;
      _lastBonusResolution = resolution;
    });

    if (!showFeedback) {
      return resolution;
    }

    if (resolution.hasTriggeredNuisances) {
      final groupedTriggeredNuisances = BattleDrawingGrouping.groupNuisances(
        resolution.enemyNuisanceResolution.triggeredNuisances,
      );
      _feedbackController.showSequence(
        labels: groupedTriggeredNuisances
            .map(
              (group) => group.count <= 1
                  ? group.nuisance.failureLabel
                  : '${group.nuisance.failureLabel} x${group.count}',
            )
            .toList(growable: false),
        color: _battleSketchEnemyMalusAccent,
      );
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

    if (result.hasMatch) {
      _feedbackController.showSequence(
        labels: result.displayLabels,
        color: EndpointPalette.warningAccent,
      );
      return resolution;
    }

    _feedbackController.show(
      label: '?',
      color: _battleSketchMissAccent,
    );
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

  @override
  void dispose() {
    _feedbackController
      ..removeListener(_handleFeedbackChanged)
      ..dispose();
    _timerController
      ..removeStatusListener(_handleTimerStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EndpointOverlayScaffold(
      sectionLabel: 'COMBATE',
      sectionValue: 'DIBUJO',
      showHeader: false,
      showCloseButton: false,
      accent: EndpointPalette.warningAccent,
      backgroundColor: EndpointPalette.panelBackgroundOpaque,
      bottomInset: 18,
      maxWidth: 540,
      maxHeight: 760,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BattleDrawTargetsStrip(
            bonusItemGroups: _bonusItemGroups,
            nuisanceGroups: _enemyNuisanceGroups,
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
                          _battleSketchCanvasBorderRadius),
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
                        _battleSketchCanvasBorderRadius - 1,
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
                                      lifetime: _battleSketchFeedbackLifetime,
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
                                  onPressed: _isSubmitting || !_canUseQuickDraw
                                      ? null
                                      : _handleQuickDrawPressed,
                                  tooltip: _canUseQuickDraw
                                      ? 'Pegar runa precargada en el centro'
                                      : 'Quick Draw inactivo',
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
                  tooltip: 'Borrar todos los trazos del ataque',
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
            ],
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _timerController,
            builder: (context, _) {
              final remainingFactor =
                  (1 - _timerController.value).clamp(0.0, 1.0);
              final remainingMillis =
                  (_battleSketchDuration.inMilliseconds * remainingFactor)
                      .ceil();
              final remainingSeconds = max(
                0,
                (remainingMillis / 1000).ceil(),
              );
              final timerAccent = _timerAccentFor(remainingFactor);

              return _BattleDrawCountdownBar(
                remainingFactor: remainingFactor,
                remainingSeconds: remainingSeconds,
                accent: timerAccent,
              );
            },
          ),
          const SizedBox(height: 10),
          EndpointActionButton(
            label: _isSubmitting ? 'RESOLVIENDO' : 'ATACAR',
            icon: Icons.flash_on_rounded,
            onPressed: _isSubmitting
                ? null
                : () => unawaited(_submitAttack(autoTriggered: false)),
            tooltip: 'Resolver el ataque con los bonus detectados',
            accent: EndpointPalette.warningAccent,
            backgroundColor: EndpointPalette.blend(
              EndpointPalette.panelBackgroundBattle,
              EndpointPalette.warningAccent,
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

  Color _timerAccentFor(double remainingFactor) {
    if (remainingFactor > 0.66) {
      return EndpointPalette.primaryAccent;
    }
    if (remainingFactor > 0.33) {
      return EndpointPalette.warningAccent;
    }
    return EndpointPalette.dangerAccent;
  }
}

class _BattleDrawTargetsStrip extends StatelessWidget {
  final List<BattleDrawingItemBonusGroup> bonusItemGroups;
  final List<BattleDrawingEnemyNuisanceGroup> nuisanceGroups;
  final BattleDrawingBonusResolution resolution;

  const _BattleDrawTargetsStrip({
    required this.bonusItemGroups,
    required this.nuisanceGroups,
    required this.resolution,
  });

  @override
  Widget build(BuildContext context) {
    if (nuisanceGroups.isEmpty && bonusItemGroups.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (int index = 0; index < nuisanceGroups.length; index++)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _BattleDrawEnemyNuisanceCard(
                nuisance: nuisanceGroups[index].nuisance,
                repeatCount: nuisanceGroups[index].count,
                isResolved: resolution.enemyNuisanceResolution
                    .isResolved(nuisanceGroups[index].nuisance),
              ),
            ),
          if (nuisanceGroups.isNotEmpty && bonusItemGroups.isNotEmpty)
            const SizedBox(width: 4),
          for (int index = 0; index < bonusItemGroups.length; index++)
            Padding(
              padding: EdgeInsets.only(
                right: index == bonusItemGroups.length - 1 ? 10 : 8,
              ),
              child: _BattleDrawItemCard(
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

class _BattleDrawItemCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String emoji;
  final BattleDrawingShape shape;
  final Color accent;
  final bool isActivated;
  final int repeatCount;

  const _BattleDrawItemCard({
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
                                      painter: _BattleDrawCombatShapePainter(
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
              child: _BattleDrawRepeatBadge(
                count: repeatCount,
                accent: accent,
              ),
            ),
        ],
      ),
    );
  }
}

class _BattleDrawEnemyNuisanceCard extends StatelessWidget {
  final BattleDrawingEnemyNuisance nuisance;
  final bool isResolved;
  final int repeatCount;

  const _BattleDrawEnemyNuisanceCard({
    required this.nuisance,
    required this.isResolved,
    this.repeatCount = 1,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isResolved
        ? EndpointPalette.rewardAccent
        : _battleSketchEnemyMalusAccent;

    return SizedBox(
      width: 122,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: EndpointPanel(
              accent: accent,
              backgroundColor: EndpointPalette.blend(
                EndpointPalette.panelBackgroundBattle,
                accent,
                isResolved ? 0.09 : 0.15,
              ),
              borderRadius: 12,
              glowOpacity: isResolved ? 0.06 : 0.14,
              blurRadius: 14,
              spreadRadius: 1,
              padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
              child: Column(
                children: [
                  SizedBox(
                    width: 34,
                    height: 34,
                    child: CustomPaint(
                      painter: _BattleDrawCombatShapePainter(
                        shape: nuisance.requiredShape,
                        strokeColor: accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  EndpointText(
                    nuisance.requiredShape.label.toUpperCase(),
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: textSmallBold.copyWith(
                      color: EndpointPalette.softForeground,
                      fontSize: 9,
                      letterSpacing: 0.6,
                    ),
                  ),
                  EndpointText(
                    nuisance.pendingDescription,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: textSmallBold.copyWith(
                      color: accent.withValues(alpha: 0.92),
                      fontSize: 8,
                      letterSpacing: 0.35,
                      height: 1.08,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (repeatCount > 1)
            Positioned(
              top: -6,
              right: -6,
              child: _BattleDrawRepeatBadge(
                count: repeatCount,
                accent: accent,
              ),
            ),
        ],
      ),
    );
  }
}

class _BattleDrawRepeatBadge extends StatelessWidget {
  final int count;
  final Color accent;

  const _BattleDrawRepeatBadge({
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

class _BattleDrawCountdownBar extends StatelessWidget {
  final double remainingFactor;
  final int remainingSeconds;
  final Color accent;

  const _BattleDrawCountdownBar({
    required this.remainingFactor,
    required this.remainingSeconds,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
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
                  backgroundColor:
                      EndpointPalette.softForeground.withValues(alpha: 0.08),
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
  }
}

class _BattleDrawCombatShapePainter extends CustomPainter {
  final BattleDrawingShape shape;
  final Color strokeColor;

  const _BattleDrawCombatShapePainter({
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
  bool shouldRepaint(covariant _BattleDrawCombatShapePainter oldDelegate) {
    return oldDelegate.shape != shape || oldDelegate.strokeColor != strokeColor;
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
