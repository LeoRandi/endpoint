import '../_imports.dart';
import '../path/operative_sketch_recognition_helper.dart';
import '../../services/battle_drawing_bonus_resolver.dart';

const _battleSketchCanvasBorderRadius = 20.0;
const _battleSketchNoiseSeed = 9187;
const _battleSketchFeedbackLifetime = Duration(seconds: 1);
const _battleSketchFeedbackGap = Duration(milliseconds: 500);
const _battleSketchMissAccent = Color(0xFFC178FF);
const _battleSketchEraserRadius = 18.0;
const _battleSketchDuration = Duration(seconds: 30);

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
  final List<_BattleSketchStroke> _strokes = <_BattleSketchStroke>[];
  late final List<_BattleSketchNoiseDot> _noiseDots = _buildNoiseDots();
  late final AnimationController _timerController = AnimationController(
    vsync: this,
    duration: _battleSketchDuration,
  )..addStatusListener(_handleTimerStatus);

  Timer? _feedbackTimer;
  _BattleSketchFeedback? _feedback;
  Size? _canvasSize;
  Color _selectedBrushColor = _brushColors.first;
  _BattleSketchToolMode _toolMode = _BattleSketchToolMode.paint;
  int _feedbackVersion = 0;
  int _nextStrokeId = 0;
  int? _activeStrokeId;
  Offset? _lastDragPosition;
  bool _isSubmitting = false;
  OperativeSketchRecognitionResult _lastRecognitionResult =
      _emptyRecognitionResult;
  BattleDrawingBonusResolution _lastBonusResolution =
      const BattleDrawingBonusResolution();

  @override
  void initState() {
    super.initState();
    _timerController.forward();
  }

  void _handleTimerStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _isSubmitting) return;
    unawaited(_submitAttack(autoTriggered: true));
  }

  void _handlePanStart(DragStartDetails details) {
    _dismissFeedback();
    _invalidatePreview();
    _lastDragPosition = details.localPosition;
    if (_toolMode == _BattleSketchToolMode.erase) {
      _eraseBetween(details.localPosition, details.localPosition);
      return;
    }

    final stroke = _BattleSketchStroke(
      id: _nextStrokeId++,
      color: _selectedBrushColor,
      points: <Offset>[details.localPosition],
    );
    setState(() {
      _strokes.add(stroke);
      _activeStrokeId = stroke.id;
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_toolMode == _BattleSketchToolMode.erase) {
      final start = _lastDragPosition ?? details.localPosition;
      _eraseBetween(start, details.localPosition);
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

  void _handlePanEnd(DragEndDetails details) {
    _lastDragPosition = null;
    _activeStrokeId = null;
  }

  void _clearStrokes() {
    if (_strokes.isEmpty) return;
    _dismissFeedback();
    setState(() {
      _strokes.clear();
      _activeStrokeId = null;
    });
    _invalidatePreview();
  }

  void _undoLastStroke() {
    if (_strokes.isEmpty) return;
    _dismissFeedback();
    setState(() {
      _strokes.removeLast();
      _activeStrokeId = null;
    });
    _invalidatePreview();
  }

  void _selectBrushColor(Color color) {
    if (_selectedBrushColor == color &&
        _toolMode == _BattleSketchToolMode.paint) {
      return;
    }
    setState(() {
      _selectedBrushColor = color;
      _toolMode = _BattleSketchToolMode.paint;
    });
  }

  void _toggleToolMode() {
    setState(() {
      _toolMode = _toolMode == _BattleSketchToolMode.paint
          ? _BattleSketchToolMode.erase
          : _BattleSketchToolMode.paint;
    });
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

  bool _eraseBetween(Offset start, Offset end) {
    if (_strokes.isEmpty) return false;

    final updatedStrokes = <_BattleSketchStroke>[];
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

    if (!didChange) return false;

    setState(() {
      _strokes
        ..clear()
        ..addAll(updatedStrokes);
    });
    _invalidatePreview();
    return true;
  }

  List<_BattleSketchStroke> _eraseStrokeSegment({
    required _BattleSketchStroke stroke,
    required Offset start,
    required Offset end,
  }) {
    if (stroke.points.isEmpty) return const <_BattleSketchStroke>[];

    final keptPointGroups = <List<Offset>>[];
    var currentGroup = <Offset>[];
    var touched = false;

    for (final point in stroke.points) {
      final shouldErase =
          _distanceToSegment(point, start, end) <= _battleSketchEraserRadius;
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
      return <_BattleSketchStroke>[stroke];
    }

    return keptPointGroups
        .map(
          (points) => _BattleSketchStroke(
            id: _nextStrokeId++,
            color: stroke.color,
            points: points,
          ),
        )
        .toList(growable: false);
  }

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

    final result = _strokes.isEmpty
        ? _emptyRecognitionResult
        : _recognitionHelper.scan(
            strokes: _strokes.map((stroke) => stroke.points),
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
      _showFeedbackSequence(
        labels: resolution.activatedItems
            .map((item) => item.specialBonus.description)
            .toList(growable: false),
        color: EndpointPalette.rewardAccent,
      );
      return resolution;
    }

    if (result.hasMatch) {
      _showFeedbackSequence(
        labels: result.displayLabels,
        color: EndpointPalette.warningAccent,
      );
      return resolution;
    }

    _showFeedback(label: '?', color: _battleSketchMissAccent);
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

  void _showFeedback({
    required String label,
    required Color color,
  }) {
    _feedbackTimer?.cancel();
    final feedback = _BattleSketchFeedback(
      label: label,
      color: color,
      version: ++_feedbackVersion,
    );
    setState(() {
      _feedback = feedback;
    });
    _feedbackTimer = Timer(_battleSketchFeedbackLifetime, () {
      if (!mounted) return;
      setState(() {
        if (_feedback?.version == feedback.version) {
          _feedback = null;
        }
      });
    });
  }

  void _showFeedbackSequence({
    required List<String> labels,
    required Color color,
  }) {
    if (labels.isEmpty) return;

    _feedbackTimer?.cancel();
    _playFeedbackAt(labels: labels, color: color, index: 0);
  }

  void _playFeedbackAt({
    required List<String> labels,
    required Color color,
    required int index,
  }) {
    if (!mounted || index >= labels.length) return;

    final feedback = _BattleSketchFeedback(
      label: labels[index],
      color: color,
      version: ++_feedbackVersion,
    );
    setState(() {
      _feedback = feedback;
    });

    _feedbackTimer = Timer(_battleSketchFeedbackLifetime, () {
      if (!mounted) return;
      setState(() {
        if (_feedback?.version == feedback.version) {
          _feedback = null;
        }
      });

      if (index + 1 >= labels.length) return;
      _feedbackTimer = Timer(_battleSketchFeedbackGap, () {
        _playFeedbackAt(
          labels: labels,
          color: color,
          index: index + 1,
        );
      });
    });
  }

  void _dismissFeedback() {
    _feedbackTimer?.cancel();
    _feedbackTimer = null;
    _feedback = null;
  }

  List<_BattleSketchNoiseDot> _buildNoiseDots() {
    final seededRandom = Random(_battleSketchNoiseSeed);
    return List<_BattleSketchNoiseDot>.generate(260, (index) {
      final tint = index.isEven
          ? EndpointPalette.softForeground
          : EndpointPalette.soften(EndpointPalette.infoAccent, amount: 0.2);
      return _BattleSketchNoiseDot(
        relativeOffset: Offset(
          seededRandom.nextDouble(),
          seededRandom.nextDouble(),
        ),
        radius: 0.4 + (seededRandom.nextDouble() * 1.3),
        color: tint.withValues(
          alpha: 0.04 + (seededRandom.nextDouble() * 0.12),
        ),
      );
    });
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
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
                                painter: _BattleSketchPainter(
                                  strokes:
                                      List<_BattleSketchStroke>.unmodifiable(
                                    _strokes,
                                  ),
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
                                    child: _BattleSketchFeedbackBanner(
                                      feedback: _feedback,
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
                      isSelected: _toolMode == _BattleSketchToolMode.paint &&
                          _selectedBrushColor == color,
                      onPressed: () => _selectBrushColor(color),
                    ),
                  _BattleSketchToolButton(
                    label: 'Borrar',
                    icon: Icons.cleaning_services_outlined,
                    isSelected: _toolMode == _BattleSketchToolMode.erase,
                    onPressed: _toggleToolMode,
                  ),
                  _BattleSketchToolButton(
                    label: 'Deshacer',
                    icon: Icons.undo_rounded,
                    onPressed: _strokes.isEmpty ? null : _undoLastStroke,
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
                    onPressed: _strokes.isEmpty ? null : _clearStrokes,
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

enum _BattleSketchToolMode {
  paint,
  erase,
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

class _BattleSketchFeedback {
  final String label;
  final Color color;
  final int version;

  const _BattleSketchFeedback({
    required this.label,
    required this.color,
    required this.version,
  });
}

class _BattleSketchFeedbackBanner extends StatelessWidget {
  final _BattleSketchFeedback? feedback;

  const _BattleSketchFeedbackBanner({
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
              duration: _battleSketchFeedbackLifetime,
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

class _BattleSketchStroke {
  final int id;
  final Color color;
  final List<Offset> points;

  const _BattleSketchStroke({
    required this.id,
    required this.color,
    required this.points,
  });

  _BattleSketchStroke copyWith({
    List<Offset>? points,
  }) {
    return _BattleSketchStroke(
      id: id,
      color: color,
      points: points ?? this.points,
    );
  }
}

class _BattleSketchNoiseDot {
  final Offset relativeOffset;
  final double radius;
  final Color color;

  const _BattleSketchNoiseDot({
    required this.relativeOffset,
    required this.radius,
    required this.color,
  });
}

class _BattleSketchPainter extends CustomPainter {
  final List<_BattleSketchStroke> strokes;
  final List<_BattleSketchNoiseDot> noiseDots;

  const _BattleSketchPainter({
    required this.strokes,
    required this.noiseDots,
  });

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

  void _paintStroke(Canvas canvas, _BattleSketchStroke stroke) {
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

  @override
  bool shouldRepaint(covariant _BattleSketchPainter oldDelegate) {
    return true;
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
