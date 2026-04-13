import '../_imports.dart';
import '../path/operative_sketch_recognition_helper.dart';
import '../../services/battle_drawing_bonus_resolver.dart';

const _battleSketchCanvasBorderRadius = 20.0;
const _battleSketchNoiseSeed = 9187;
const _battleSketchFeedbackLifetime = Duration(seconds: 1);
const _battleSketchFeedbackGap = Duration(milliseconds: 500);
const _battleSketchMissAccent = Color(0xFFC178FF);
const _battleSketchEraserRadius = 18.0;
const _battleSketchDuration = Duration(seconds: 15);

class BattleDrawAttackOverlay extends StatefulWidget {
  final Battler attacker;

  const BattleDrawAttackOverlay({
    super.key,
    required this.attacker,
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
  late final EndpointSketchCanvasController _sketchController;
  late final EndpointSketchFeedbackController _feedbackController;
  late final List<EndpointSketchNoiseDot> _noiseDots;
  late final AnimationController _timerController = AnimationController(
    vsync: this,
    duration: _battleSketchDuration,
  )..addStatusListener(_handleTimerStatus);

  Size? _canvasSize;
  bool _isSubmitting = false;
  OperativeSketchRecognitionResult _lastRecognitionResult =
      _emptyRecognitionResult;
  BattleDrawingBonusResolution _lastBonusResolution =
      const BattleDrawingBonusResolution();

  @override
  void initState() {
    super.initState();
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
    if (_sketchController.handlePanStart(details.localPosition)) {
      setState(() {});
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final didChange = _sketchController.handlePanUpdate(details.localPosition);
    if (!didChange) return;

    if (_sketchController.toolMode == EndpointSketchToolMode.erase) {
      _invalidatePreview();
    }
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

  void _selectBrushColor(Color color) {
    if (_sketchController.selectBrushColor(color)) {
      setState(() {});
    }
  }

  void _toggleToolMode() {
    if (_sketchController.toggleToolMode()) {
      setState(() {});
    }
  }

  void _invalidatePreview() {
    if (_lastRecognitionResult == _emptyRecognitionResult &&
        !_lastBonusResolution.hasActivatedItems) {
      return;
    }

    setState(() {
      _lastRecognitionResult = _emptyRecognitionResult;
      _lastBonusResolution = const BattleDrawingBonusResolution();
    });
  }

  void _handleCheckPressed() {
    _runRecognitionScan(showFeedback: true);
  }

  Future<void> _submitAttack({required bool autoTriggered}) async {
    if (_isSubmitting) return;

    final resolution = _runRecognitionScan(showFeedback: !autoTriggered);
    setState(() {
      _isSubmitting = true;
    });

    if (!mounted) return;
    Navigator.of(context).pop(resolution);
  }

  BattleDrawingBonusResolution _runRecognitionScan({
    required bool showFeedback,
  }) {
    final canvasSize = _canvasSize;
    if (canvasSize == null || canvasSize.isEmpty) {
      return const BattleDrawingBonusResolution();
    }

    final result = !_sketchController.hasStrokes
        ? _emptyRecognitionResult
        : _recognitionHelper.scan(
            strokes: _sketchController.strokePointLists,
            canvasSize: canvasSize,
          );
    final resolution = _bonusResolver.resolve(
      equippedItems: widget.attacker.equippedItems,
      recognizedCounts: _recognizedCountsFor(result),
    );

    setState(() {
      _lastRecognitionResult = result;
      _lastBonusResolution = resolution;
    });

    if (!showFeedback) {
      return resolution;
    }

    if (resolution.hasActivatedItems) {
      _feedbackController.showSequence(
        labels: resolution.activatedItems
            .map((item) => item.specialBonus.description)
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

  Map<ItemBonusShape, int> _recognizedCountsFor(
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
      title: 'ATAQUE MANUAL',
      subtitle:
          'Traza las formas que quieras. Solo se activaran los bonus de los objetos equipados.',
      sectionLabel: 'COMBATE',
      sectionValue: 'DIBUJO',
      closeTooltip: 'Cerrar ataque dibujado',
      accent: EndpointPalette.warningAccent,
      backgroundColor: EndpointPalette.panelBackgroundOpaque,
      bottomInset: 18,
      maxWidth: 540,
      maxHeight: 760,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BattleDrawLoadoutStrip(
            attacker: widget.attacker,
            resolution: _lastBonusResolution,
          ),
          const SizedBox(height: 10),
          _BattleDrawRecognitionStrip(
            result: _lastRecognitionResult,
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
            alignment: WrapAlignment.spaceBetween,
            runAlignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final color in _brushColors)
                    _BattleSketchBrushSwatch(
                      color: color,
                      isSelected: _sketchController.toolMode ==
                              EndpointSketchToolMode.paint &&
                          _sketchController.selectedBrushColor == color,
                      onPressed: () => _selectBrushColor(color),
                    ),
                  _BattleSketchToolButton(
                    label: 'Borrar',
                    icon: Icons.cleaning_services_outlined,
                    isSelected: _sketchController.toolMode ==
                        EndpointSketchToolMode.erase,
                    onPressed: _toggleToolMode,
                  ),
                  _BattleSketchToolButton(
                    label: 'Deshacer',
                    icon: Icons.undo_rounded,
                    onPressed:
                        _sketchController.hasStrokes ? _undoLastStroke : null,
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  EndpointActionButton(
                    label: 'Limpiar',
                    icon: Icons.layers_clear_rounded,
                    onPressed:
                        _sketchController.hasStrokes ? _clearStrokes : null,
                    tooltip: 'Borrar todos los trazos del ataque',
                    accent: EndpointPalette.infoAccent,
                    backgroundColor: EndpointPalette.closeButtonBackground,
                    foregroundColor: EndpointPalette.softForeground,
                    useMarquee: false,
                  ),
                  EndpointActionButton(
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
                    useMarquee: false,
                  ),
                ],
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

class _BattleDrawLoadoutStrip extends StatelessWidget {
  final Battler attacker;
  final BattleDrawingBonusResolution resolution;

  const _BattleDrawLoadoutStrip({
    required this.attacker,
    required this.resolution,
  });

  @override
  Widget build(BuildContext context) {
    final equippedItems = attacker.equippedItems;
    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (int index = 0; index < equippedItems.length; index++)
            Padding(
              padding: EdgeInsets.only(
                right: index == equippedItems.length - 1 ? 10 : 8,
              ),
              child: _BattleDrawItemCard(
                title: equippedItems[index].displayName,
                subtitle: equippedItems[index].specialBonus.description,
                emoji: equippedItems[index].iconEmoji,
                shape: equippedItems[index].bonusShape,
                accent: _shapeAccent(equippedItems[index].bonusShape),
                isActivated: resolution.isItemActivated(equippedItems[index]),
              ),
            ),
          _BattleDrawArchetypeCard(
            emoji: attacker.iconEmoji,
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
  final ItemBonusShape shape;
  final Color accent;
  final bool isActivated;

  const _BattleDrawItemCard({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.shape,
    required this.accent,
    required this.isActivated,
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
                          child: CustomPaint(
                            painter: _BattleDrawShapePainter(
                              shape: shape,
                              strokeColor: accent,
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
    );
  }
}

class _BattleDrawArchetypeCard extends StatelessWidget {
  final String emoji;

  const _BattleDrawArchetypeCard({
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      child: EndpointPanel(
        accent: EndpointPalette.primaryAccent,
        backgroundColor: EndpointPalette.blend(
          EndpointPalette.panelBackground,
          EndpointPalette.primaryAccent,
          0.08,
        ),
        borderRadius: 12,
        glowOpacity: 0,
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: EndpointPalette.softForeground.withValues(alpha: 0.24),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
            child: Column(
              children: [
                const Spacer(),
                EndpointText(
                  emoji,
                  style: const TextStyle(fontSize: 34),
                ),
                const Spacer(),
                EndpointText(
                  'ARQUETIPO',
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: textSmallBold.copyWith(
                    color: EndpointPalette.primaryAccent,
                    fontSize: 9,
                    letterSpacing: 0.8,
                  ),
                ),
                EndpointText(
                  'Vista actual',
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: textSmallBold.copyWith(
                    color:
                        EndpointPalette.softForeground.withValues(alpha: 0.74),
                    fontSize: 8,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BattleDrawRecognitionStrip extends StatelessWidget {
  final OperativeSketchRecognitionResult result;
  final BattleDrawingBonusResolution resolution;

  const _BattleDrawRecognitionStrip({
    required this.result,
    required this.resolution,
  });

  @override
  Widget build(BuildContext context) {
    final hasPreview = result.matches.isNotEmpty;
    final label = hasPreview
        ? result.matches
            .map((match) => '${match.kind.label} x${match.count}')
            .join('  |  ')
        : 'Pulsa CHECK para recalcular las formas reconocidas.';
    final activatedLabel = resolution.hasActivatedItems
        ? 'Bonus activos: ${resolution.activatedItems.map((item) => item.specialBonus.description).join("  |  ")}'
        : 'Bonus activos: ninguno';

    return EndpointPanel(
      accent: resolution.hasActivatedItems
          ? EndpointPalette.rewardAccent
          : EndpointPalette.infoAccent,
      backgroundColor: EndpointPalette.panelBackgroundBattle,
      borderRadius: 12,
      glowOpacity: 0,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EndpointText(
            label,
            maxLines: 1,
            style: textSmallBold.copyWith(
              color: EndpointPalette.softForeground,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          EndpointText(
            activatedLabel,
            maxLines: 1,
            style: textSmallBold.copyWith(
              color: resolution.hasActivatedItems
                  ? EndpointPalette.rewardAccent
                  : EndpointPalette.softForeground.withValues(alpha: 0.72),
              fontSize: 9,
              letterSpacing: 0.4,
            ),
          ),
        ],
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

class _BattleSketchToolButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isSelected;

  const _BattleSketchToolButton({
    required this.label,
    required this.icon,
    this.onPressed,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent =
        isSelected ? EndpointPalette.dangerAccent : EndpointPalette.infoAccent;

    return EndpointActionButton(
      label: label,
      icon: icon,
      onPressed: onPressed,
      tooltip: label,
      accent: accent,
      backgroundColor: EndpointPalette.blend(
        EndpointPalette.panelBackground,
        accent,
        isSelected ? 0.14 : 0.08,
      ),
      foregroundColor: EndpointPalette.softForeground,
      useMarquee: false,
    );
  }
}

class _BattleSketchBrushSwatch extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onPressed;

  const _BattleSketchBrushSwatch({
    required this.color,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: isSelected
                ? Colors.white
                : EndpointPalette.softForeground.withValues(alpha: 0.24),
            width: isSelected ? 2.4 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isSelected ? 0.26 : 0.14),
              blurRadius: isSelected ? 18 : 10,
              spreadRadius: isSelected ? 2 : 0,
            ),
          ],
        ),
      ),
    );
  }
}

class _BattleDrawShapePainter extends CustomPainter {
  final ItemBonusShape shape;
  final Color strokeColor;

  const _BattleDrawShapePainter({
    required this.shape,
    required this.strokeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final isAngularShape = shape != ItemBonusShape.circle;
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
    final path = _shapePath(size);
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, corePaint);
  }

  Path _shapePath(Size size) {
    Offset fromUnit(double dx, double dy) =>
        Offset(size.width * dx, size.height * dy);

    switch (shape) {
      case ItemBonusShape.triangle:
        return Path()
          ..moveTo(size.width * 0.5, size.height * 0.16)
          ..lineTo(size.width * 0.79, size.height * 0.78)
          ..lineTo(size.width * 0.21, size.height * 0.78)
          ..close();
      case ItemBonusShape.square:
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
      case ItemBonusShape.circle:
        return Path()
          ..addOval(
            Rect.fromCenter(
              center: Offset(size.width * 0.5, size.height * 0.5),
              width: size.width * 0.56,
              height: size.height * 0.56,
            ),
          );
    }
  }

  @override
  bool shouldRepaint(covariant _BattleDrawShapePainter oldDelegate) {
    return oldDelegate.shape != shape || oldDelegate.strokeColor != strokeColor;
  }
}
