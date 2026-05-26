import '../_imports.dart';
import '../../services/operative_pattern_adjacency_service.dart';
import '../../services/operative_pattern_bonus_service.dart';

const _operativePatternBoardRadius = 18.0;
const _operativePatternAspectRatio = 1.0;
const _operativePatternBoardScale = 0.68;
const _operativePatternDiamondRotation = pi / 4;
const _operativePatternContentCounterRotation =
    -_operativePatternDiamondRotation;
const _operativePatternEmptyBonusDialogSize = 132.0;
const _operativePatternCoordinateHoldDuration = Duration(seconds: 1);
const operativePatternQuickInspectHoldDuration = Duration(milliseconds: 500);
const _operativePatternCoordinateHoldMoveTolerance = 12.0;
const _operativePatternHitRadiusFactor = 0.72;

extension _OperativePatternBonusVisualTokens on OperativePatternBonus {
  Color get accent {
    return switch (kind) {
      OperativePatternBonusKind.attack => EndpointPalette.dangerAccent,
      OperativePatternBonusKind.barrier => BattlerStat.barrier.accent,
    };
  }

  String get iconAssetPath {
    return switch (kind) {
      OperativePatternBonusKind.attack => 'assets/images/icons/icon_sword.png',
      OperativePatternBonusKind.barrier =>
        'assets/images/icons/icon_shield.png',
    };
  }
}

class OperativePatternPointContent {
  final Item? item;
  final OperativePatternBonus? bonus;
  final OperativePatternRequirement? requirement;
  final List<OperativePatternAdjacencyBonus> adjacencyBonuses;
  final List<OperativePatternAdjacencyBonus> activatedAdjacencyBonuses;
  final bool isBonusEnabled;
  final bool isPatternBonusActivated;
  final bool hasAura;

  const OperativePatternPointContent({
    this.item,
    this.bonus,
    this.requirement,
    this.adjacencyBonuses = const <OperativePatternAdjacencyBonus>[],
    this.activatedAdjacencyBonuses = const <OperativePatternAdjacencyBonus>[],
    this.isBonusEnabled = true,
    this.isPatternBonusActivated = false,
    this.hasAura = false,
  }) : assert(item != null || bonus != null);
}

class OperativePatternAdjacencyGuideSegment {
  final Offset start;
  final Offset end;
  final Color accent;
  final bool isMatched;

  const OperativePatternAdjacencyGuideSegment({
    required this.start,
    required this.end,
    required this.accent,
    required this.isMatched,
  });
}

class OperativePatternAdjacencyGuidePainter extends CustomPainter {
  final List<OperativePatternAdjacencyGuideSegment> segments;
  final double endpointInset;

  const OperativePatternAdjacencyGuidePainter({
    required this.segments,
    this.endpointInset = 14,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final segment in segments) {
      final delta = segment.end - segment.start;
      final distance = delta.distance;
      if (distance == 0) continue;

      final direction = delta / distance;
      final inset = min(endpointInset, distance * 0.32);
      final start = segment.start + (direction * inset);
      final midpoint = Offset.lerp(segment.start, segment.end, 0.5)!;
      final end = midpoint - (direction * min(3.0, distance * 0.04));
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..lineTo(end.dx, end.dy);
      if (segment.isMatched) {
        final glowPaint = Paint()
          ..color = segment.accent.withValues(alpha: 0.46)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 8
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawPath(path, glowPaint);
      }

      final corePaint = Paint()
        ..color = segment.accent.withValues(
          alpha: segment.isMatched ? 0.92 : 0.34,
        )
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = segment.isMatched ? 3.1 : 2.1;
      canvas.drawPath(path, corePaint);
      _drawArrowHead(
        canvas: canvas,
        tip: end,
        direction: direction,
        color: corePaint.color,
        strokeWidth: corePaint.strokeWidth,
      );
    }
  }

  void _drawArrowHead({
    required Canvas canvas,
    required Offset tip,
    required Offset direction,
    required Color color,
    required double strokeWidth,
  }) {
    final arrowLength = 8.0 + strokeWidth * 1.4;
    const wingAngle = pi * 0.78;
    final directionAngle = atan2(direction.dy, direction.dx);
    final firstWing = Offset(
      cos(directionAngle + wingAngle) * arrowLength,
      sin(directionAngle + wingAngle) * arrowLength,
    );
    final secondWing = Offset(
      cos(directionAngle - wingAngle) * arrowLength,
      sin(directionAngle - wingAngle) * arrowLength,
    );
    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth;
    final arrowPath = Path()
      ..moveTo((tip + firstWing).dx, (tip + firstWing).dy)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo((tip + secondWing).dx, (tip + secondWing).dy);

    canvas.drawPath(arrowPath, arrowPaint);
  }

  @override
  bool shouldRepaint(
    covariant OperativePatternAdjacencyGuidePainter oldDelegate,
  ) {
    return oldDelegate.segments != segments ||
        oldDelegate.endpointInset != endpointInset;
  }
}

class OperativePatternOverlay extends StatefulWidget {
  final Map<String, Item> equippedItemsByPointKey;
  final int playerLevel;
  final List<OperativePatternWallSegment> wallSegments;

  const OperativePatternOverlay({
    super.key,
    this.equippedItemsByPointKey = const <String, Item>{},
    this.playerLevel = Battler.initialLevel,
    this.wallSegments = const <OperativePatternWallSegment>[],
  });

  static String pointKey(int x, int y) => operativePatternPointKey(x, y);

  @override
  State<OperativePatternOverlay> createState() =>
      _OperativePatternOverlayState();
}

class _OperativePatternOverlayState extends State<OperativePatternOverlay> {
  late Map<String, OperativePatternBonus> _emptyBonusesByPointKey;

  @override
  void initState() {
    super.initState();
    _syncEmptyBonusColors();
  }

  @override
  void didUpdateWidget(covariant OperativePatternOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.equippedItemsByPointKey != widget.equippedItemsByPointKey ||
        oldWidget.playerLevel != widget.playerLevel) {
      _syncEmptyBonusColors();
    }
  }

  void _handlePointLongPressed(OperativePatternPoint point) {
    unawaited(_openPointDetails(point));
  }

  void _syncEmptyBonusColors() {
    _emptyBonusesByPointKey = buildOperativePatternBonusesByPointKey(
      playerLevel: widget.playerLevel,
      occupiedPointKeys: widget.equippedItemsByPointKey.keys,
    );
  }

  Future<void> _openPointDetails(OperativePatternPoint point) async {
    final item = widget.equippedItemsByPointKey[point.key];
    if (item != null) {
      await showEndpointDialog<void>(
        context: context,
        barrierLabel: 'Detalle de objeto equipado',
        barrierColor: EndpointPalette.overlayScrim,
        builder: (context) {
          return EndpointItemDetailsDialog(
            item: item,
            accent: item.rarity.accent,
            price: item.sellValue,
            priceLabel: 'VENTA',
            statusText: 'Estado actual: equipado',
          );
        },
      );
      return;
    }

    final bonus = _emptyBonusesByPointKey[point.key] ??
        const OperativePatternBonus(
          kind: OperativePatternBonusKind.barrier,
          amount: 1,
        );
    await showEndpointDialog<void>(
      context: context,
      barrierLabel: 'Detalle de bonus de patron',
      barrierColor: EndpointPalette.overlayScrim,
      builder: (context) {
        return _OperativePatternEmptyBonusDialog(
          bonus: bonus,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return EndpointOverlayScaffold(
      title: 'PATRON',
      subtitle: 'OBJETOS',
      sectionLabel: 'MAPA',
      sectionValue: '9 PUNTOS',
      closeTooltip: 'Cerrar patron',
      accent: EndpointPalette.patternAccent,
      bottomInset: 24,
      maxWidth: 540,
      maxHeight: 700,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: _operativePatternAspectRatio,
              child: Center(
                child: FractionallySizedBox(
                  widthFactor: _operativePatternBoardScale,
                  heightFactor: _operativePatternBoardScale,
                  child: Transform.rotate(
                    angle: _operativePatternDiamondRotation,
                    child: OperativePatternBoard(
                      onPointLongPressed: _handlePointLongPressed,
                      contentsByPointKey: _buildContentsByPointKey(),
                      wallSegments: widget.wallSegments,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, OperativePatternPointContent> _buildContentsByPointKey() {
    return <String, OperativePatternPointContent>{
      for (final entry in widget.equippedItemsByPointKey.entries)
        entry.key: OperativePatternPointContent(
          item: entry.value,
          bonus: entry.value.hasPatternBonus ? entry.value.patternBonus : null,
          requirement: entry.value.hasPatternBonus
              ? entry.value.patternRequirement
              : null,
          adjacencyBonuses: entry.value.patternAdjacencyBonuses,
          hasAura: entry.value.hasPatternAura,
        ),
      for (final entry in _emptyBonusesByPointKey.entries)
        entry.key: OperativePatternPointContent(bonus: entry.value),
    };
  }
}

Offset operativePatternBoardLocalCenterFor({
  required Size boardSize,
  required OperativePatternPoint point,
}) {
  return _OperativePatternGridLayout.fromBoardSize(boardSize).centerFor(point);
}

OperativePatternWallSegment? operativePatternNearestWallSegmentFor({
  required Size boardSize,
  required Offset localPosition,
  double maxDistanceFactor = 0.16,
}) {
  final layout = _OperativePatternGridLayout.fromBoardSize(boardSize);
  final candidates = <OperativePatternWallSegment>[];
  for (final point in operativePatternPoints) {
    for (final delta in const [
      (x: 1, y: 0),
      (x: 0, y: 1),
    ]) {
      final neighbor = operativePatternPointAt(
        x: point.x + delta.x,
        y: point.y + delta.y,
      );
      if (neighbor == null) continue;
      candidates.add(OperativePatternWallSegment(a: point, b: neighbor));
    }
  }

  OperativePatternWallSegment? nearest;
  var nearestDistance = double.infinity;
  for (final candidate in candidates) {
    final a = layout.centerFor(candidate.a);
    final b = layout.centerFor(candidate.b);
    final midpoint = Offset.lerp(a, b, 0.5)!;
    final distance = (localPosition - midpoint).distance;
    if (distance >= nearestDistance) continue;
    nearestDistance = distance;
    nearest = candidate;
  }

  final maxDistance = boardSize.shortestSide * maxDistanceFactor;
  return nearestDistance <= maxDistance ? nearest : null;
}

class OperativePatternBoard extends StatefulWidget {
  final ValueChanged<OperativePatternPoint>? onPointTapped;
  final ValueChanged<OperativePatternPoint>? onPointLongPressed;
  final ValueChanged<List<OperativePatternPoint>>? onPatternChanged;
  final Map<String, OperativePatternPointContent> contentsByPointKey;
  final List<OperativePatternWallSegment> wallSegments;
  final Set<String> disabledWallSegmentKeys;
  final OperativePatternWallSegment? previewWallSegment;
  final Set<String> animatedWallSegmentKeys;
  final Color wallAccent;
  final double previewWallOpacity;
  final Set<String> blockedPointKeys;
  final List<OperativePatternPoint>? displayedPatternPoints;
  final bool keepLineAfterPointerUp;
  final bool isPatternInputEnabled;
  final int? maxPatternPoints;
  final Color accent;
  final Duration longPressDuration;

  const OperativePatternBoard({
    super.key,
    this.onPointTapped,
    this.onPointLongPressed,
    this.onPatternChanged,
    required this.contentsByPointKey,
    this.wallSegments = const <OperativePatternWallSegment>[],
    this.disabledWallSegmentKeys = const <String>{},
    this.previewWallSegment,
    this.animatedWallSegmentKeys = const <String>{},
    this.wallAccent = EndpointPalette.dangerAccent,
    this.previewWallOpacity = 0.5,
    this.blockedPointKeys = const <String>{},
    this.displayedPatternPoints,
    this.keepLineAfterPointerUp = false,
    this.isPatternInputEnabled = true,
    this.maxPatternPoints,
    this.accent = EndpointPalette.patternAccent,
    this.longPressDuration = _operativePatternCoordinateHoldDuration,
  });

  @override
  State<OperativePatternBoard> createState() => _OperativePatternBoardState();
}

class _OperativePatternBoardState extends State<OperativePatternBoard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wallPulseController;
  Timer? _coordinateHoldTimer;
  int? _activePointer;
  Offset? _activeFinger;
  Offset? _coordinateHoldOrigin;
  List<OperativePatternPoint> _activePatternPoints =
      const <OperativePatternPoint>[];
  List<OperativePatternPoint> _completedPatternPoints =
      const <OperativePatternPoint>[];

  @override
  void initState() {
    super.initState();
    _wallPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 920),
    );
    _syncWallPulseController();
  }

  @override
  void didUpdateWidget(covariant OperativePatternBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animatedWallSegmentKeys != widget.animatedWallSegmentKeys) {
      _syncWallPulseController();
    }
  }

  void _syncWallPulseController() {
    if (widget.animatedWallSegmentKeys.isEmpty) {
      _wallPulseController.stop();
      _wallPulseController.value = 0;
      return;
    }
    if (!_wallPulseController.isAnimating) {
      _wallPulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _coordinateHoldTimer?.cancel();
    _wallPulseController.dispose();
    super.dispose();
  }

  void _handlePointerDown(
    PointerDownEvent event,
    _OperativePatternGridLayout layout,
  ) {
    if (!widget.isPatternInputEnabled) return;
    final point = layout.pointAt(event.localPosition);
    if (point == null || _isPointBlocked(point)) {
      _clearActivePattern();
      return;
    }

    final onPointTapped = widget.onPointTapped;
    if (onPointTapped != null) {
      _clearActivePattern();
      onPointTapped(point);
      return;
    }

    _coordinateHoldTimer?.cancel();
    _activePointer = event.pointer;
    _coordinateHoldOrigin = event.localPosition;
    _completedPatternPoints = const <OperativePatternPoint>[];
    _activePatternPoints = <OperativePatternPoint>[point];
    _activeFinger = event.localPosition;

    final onPointLongPressed = widget.onPointLongPressed;
    if (onPointLongPressed != null) {
      _coordinateHoldTimer = Timer(
        widget.longPressDuration,
        () {
          if (!mounted || _activePointer != event.pointer) return;
          onPointLongPressed(point);
        },
      );
    }

    setState(() {});
    _notifyPatternChanged(_activePatternPoints);
  }

  void _handlePointerMove(
    PointerMoveEvent event,
    _OperativePatternGridLayout layout,
  ) {
    if (!widget.isPatternInputEnabled) return;
    if (_activePointer != event.pointer || _activePatternPoints.isEmpty) {
      return;
    }
    if (OperativePatternRequirement.isClosedPattern(_activePatternPoints)) {
      return;
    }

    final holdOrigin = _coordinateHoldOrigin;
    if (holdOrigin != null &&
        (event.localPosition - holdOrigin).distance >
            _operativePatternCoordinateHoldMoveTolerance) {
      _coordinateHoldTimer?.cancel();
      _coordinateHoldOrigin = null;
    }

    final lastPatternCenter = layout.centerFor(_activePatternPoints.last);
    final constrainedFinger = layout.constrainSegmentByWalls(
      from: lastPatternCenter,
      to: event.localPosition,
      wallSegments: _activeWallSegments,
      connectedWallKeys: _connectedWallKeys,
    );
    final crossedPoints = _acceptedCrossedPoints(
      layout.pointsCrossedBySegment(
        from: lastPatternCenter,
        to: constrainedFinger,
        excludedPoints: <OperativePatternPoint>{
          ..._recentPatternPointsBlockedForReuse(),
          ..._blockedPoints,
        },
      ),
    );

    setState(() {
      if (crossedPoints.isNotEmpty) {
        _activePatternPoints = <OperativePatternPoint>[
          ..._activePatternPoints,
          ...crossedPoints,
        ];
      }
      _activeFinger = constrainedFinger;
    });

    if (crossedPoints.isNotEmpty) {
      _notifyPatternChanged(_activePatternPoints);
    }
  }

  void _handlePointerEnd(PointerEvent event) {
    if (!widget.isPatternInputEnabled) return;
    if (_activePointer != event.pointer) return;
    if (widget.keepLineAfterPointerUp) {
      _coordinateHoldTimer?.cancel();
      final completedPattern = List<OperativePatternPoint>.unmodifiable(
        _activePatternPoints,
      );
      setState(() {
        _activePointer = null;
        _activeFinger = null;
        _coordinateHoldOrigin = null;
        _activePatternPoints = const <OperativePatternPoint>[];
        _completedPatternPoints = completedPattern;
      });
      _notifyPatternChanged(completedPattern);
      return;
    }

    _clearActivePattern();
  }

  void _clearActivePattern() {
    _coordinateHoldTimer?.cancel();
    _activePointer = null;
    _activeFinger = null;
    _coordinateHoldOrigin = null;

    if (_activePatternPoints.isEmpty && _completedPatternPoints.isEmpty) {
      return;
    }

    setState(() {
      _activePatternPoints = const <OperativePatternPoint>[];
      _completedPatternPoints = const <OperativePatternPoint>[];
    });
    _notifyPatternChanged(const <OperativePatternPoint>[]);
  }

  List<Offset> _linePointCenters(_OperativePatternGridLayout layout) {
    return _displayedPatternPoints
        .map(layout.centerFor)
        .toList(growable: false);
  }

  List<OperativePatternAdjacencyGuideSegment> _adjacencyGuideSegments(
    _OperativePatternGridLayout layout,
  ) {
    final evaluations = OperativePatternAdjacencyService.evaluate(
      itemsByPointKey: {
        for (final entry in widget.contentsByPointKey.entries)
          if (entry.value.item != null) entry.key: entry.value.item!,
      },
      adjacencyBonusesForItem: (point, item) =>
          widget.contentsByPointKey[point.key]?.adjacencyBonuses ??
          item.patternAdjacencyBonuses,
    );

    return <OperativePatternAdjacencyGuideSegment>[
      for (final evaluation in evaluations)
        OperativePatternAdjacencyGuideSegment(
          start: layout.centerFor(evaluation.sourcePoint),
          end: layout.centerFor(evaluation.targetPoint),
          accent: evaluation.bonus.requiredTag.accent,
          isMatched: evaluation.isMatched,
        ),
    ];
  }

  Set<OperativePatternPoint> _recentPatternPointsBlockedForReuse() {
    if (_activePatternPoints.length <= 2) {
      return _activePatternPoints.toSet();
    }

    return _activePatternPoints.skip(_activePatternPoints.length - 2).toSet();
  }

  Set<OperativePatternPoint> get _blockedPoints {
    return operativePatternPoints
        .where((point) => _isPointBlocked(point))
        .toSet();
  }

  bool _isPointBlocked(OperativePatternPoint point) {
    return widget.blockedPointKeys.contains(point.key);
  }

  List<OperativePatternPoint> get _displayedPatternPoints {
    final override = widget.displayedPatternPoints;
    if (override != null) return override;
    if (_activePatternPoints.isNotEmpty) return _activePatternPoints;
    return _completedPatternPoints;
  }

  bool get _isDisplayedPatternClosed {
    return OperativePatternRequirement.isClosedPattern(
      _displayedPatternPoints,
    );
  }

  List<OperativePatternPoint> _acceptedCrossedPoints(
    List<OperativePatternPoint> crossedPoints,
  ) {
    if (_activePatternPoints.isEmpty ||
        OperativePatternRequirement.isClosedPattern(_activePatternPoints)) {
      return const <OperativePatternPoint>[];
    }

    final maxPatternPoints = widget.maxPatternPoints;
    final hasPointLimit = maxPatternPoints != null && maxPatternPoints > 0;
    final acceptedPoints = <OperativePatternPoint>[];
    final firstPoint = _activePatternPoints.first;
    var distinctPointCount =
        OperativePatternRequirement.distinctPointCount(_activePatternPoints);

    for (final point in crossedPoints) {
      final closesPattern = point == firstPoint &&
          (_activePatternPoints.length + acceptedPoints.length) >= 3;
      final previousPoint = acceptedPoints.isEmpty
          ? _activePatternPoints.last
          : acceptedPoints.last;
      if (_isSegmentBlocked(previousPoint, point)) break;

      if (closesPattern) {
        acceptedPoints.add(point);
        break;
      }

      if (hasPointLimit && distinctPointCount >= maxPatternPoints) continue;

      acceptedPoints.add(point);
      distinctPointCount++;
    }

    return List<OperativePatternPoint>.unmodifiable(acceptedPoints);
  }

  bool _isSegmentBlocked(
    OperativePatternPoint from,
    OperativePatternPoint to,
  ) {
    final connectedWallKeys = _connectedWallKeys;
    return _activeWallSegments.any(
      (wall) => wall.blocks(
        from,
        to,
        isConnected: connectedWallKeys.contains(wall.key),
      ),
    );
  }

  Set<String> get _connectedWallKeys {
    final endpointUseCounts = <String, int>{};
    for (final wall in _activeWallSegments) {
      endpointUseCounts.update(wall.a.key, (count) => count + 1,
          ifAbsent: () => 1);
      endpointUseCounts.update(wall.b.key, (count) => count + 1,
          ifAbsent: () => 1);
    }

    return <String>{
      for (final wall in _activeWallSegments)
        if ((endpointUseCounts[wall.a.key] ?? 0) > 1 ||
            (endpointUseCounts[wall.b.key] ?? 0) > 1)
          wall.key,
    };
  }

  List<OperativePatternWallSegment> get _activeWallSegments {
    if (widget.disabledWallSegmentKeys.isEmpty) return widget.wallSegments;

    return widget.wallSegments
        .where((wall) => !widget.disabledWallSegmentKeys.contains(wall.key))
        .toList(growable: false);
  }

  List<OperativePatternWallSegment> get _disabledWallSegments {
    if (widget.disabledWallSegmentKeys.isEmpty) {
      return const <OperativePatternWallSegment>[];
    }

    return widget.wallSegments
        .where((wall) => widget.disabledWallSegmentKeys.contains(wall.key))
        .toList(growable: false);
  }

  void _notifyPatternChanged(List<OperativePatternPoint> points) {
    widget.onPatternChanged?.call(
      List<OperativePatternPoint>.unmodifiable(points),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = _OperativePatternGridLayout.fromBoardSize(
          Size(constraints.maxWidth, constraints.maxHeight),
        );
        final displayedPatternPoints = _displayedPatternPoints;
        final isClosedPattern = _isDisplayedPatternClosed;
        final lineCenters = _linePointCenters(layout);
        final adjacencyGuideSegments = _adjacencyGuideSegments(layout);
        final lineFinger = _activeFinger;
        final activeWallSegments = _activeWallSegments;
        final disabledWallSegments = _disabledWallSegments;

        return AnimatedBuilder(
          animation: _wallPulseController,
          builder: (context, _) {
            final wallPulse = widget.animatedWallSegmentKeys.isEmpty
                ? 0.0
                : _wallPulseController.value;
            final animatedWallSegments = activeWallSegments
                .where((wall) => widget.animatedWallSegmentKeys.contains(
                      wall.key,
                    ))
                .toList(growable: false);
            final staticWallSegments = activeWallSegments
                .where((wall) => !widget.animatedWallSegmentKeys.contains(
                      wall.key,
                    ))
                .toList(growable: false);

            return Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (event) => _handlePointerDown(event, layout),
              onPointerMove: (event) => _handlePointerMove(event, layout),
              onPointerUp: _handlePointerEnd,
              onPointerCancel: _handlePointerEnd,
              child: SizedBox.expand(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: EndpointPalette.blend(
                      EndpointPalette.panelBackground,
                      widget.accent,
                      0.08,
                    ),
                    borderRadius: BorderRadius.circular(
                      _operativePatternBoardRadius,
                    ),
                    border: Border.all(
                      color: EndpointPalette.softForeground
                          .withValues(alpha: 0.72),
                      width: 1.6,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.accent.withValues(alpha: 0.12),
                        blurRadius: 22,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      _operativePatternBoardRadius - 1,
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: Alignment.center,
                                radius: 0.9,
                                colors: [
                                  widget.accent.withValues(alpha: 0.12),
                                  EndpointPalette.panelBackground.withValues(
                                    alpha: 0.86,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (adjacencyGuideSegments.isNotEmpty)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: OperativePatternAdjacencyGuidePainter(
                                  segments: adjacencyGuideSegments,
                                  endpointInset: layout.dotSize * 0.58,
                                ),
                              ),
                            ),
                          ),
                        if (lineCenters.isNotEmpty)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: _OperativePatternDragLinePainter(
                                  points: lineCenters,
                                  finger: lineFinger,
                                  accent: widget.accent,
                                  isClosed: isClosedPattern,
                                ),
                              ),
                            ),
                          ),
                        if (staticWallSegments.isNotEmpty)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: _OperativePatternWallPainter(
                                  wallSegments: staticWallSegments,
                                  connectedWallKeys: _connectedWallKeys,
                                  layout: layout,
                                  accent: widget.wallAccent,
                                ),
                              ),
                            ),
                          ),
                        if (animatedWallSegments.isNotEmpty)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: _OperativePatternWallPainter(
                                  wallSegments: animatedWallSegments,
                                  connectedWallKeys: _connectedWallKeys,
                                  layout: layout,
                                  accent: widget.wallAccent,
                                  pulse: wallPulse,
                                ),
                              ),
                            ),
                          ),
                        if (disabledWallSegments.isNotEmpty)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: _OperativePatternWallPainter(
                                  wallSegments: disabledWallSegments,
                                  connectedWallKeys: const <String>{},
                                  layout: layout,
                                  accent: EndpointPalette.softForeground,
                                  opacity: 0.34,
                                ),
                              ),
                            ),
                          ),
                        if (widget.previewWallSegment != null)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: _OperativePatternWallPainter(
                                  wallSegments: [widget.previewWallSegment!],
                                  connectedWallKeys: _connectedWallKeys,
                                  layout: layout,
                                  accent: widget.wallAccent,
                                  opacity: widget.previewWallOpacity,
                                ),
                              ),
                            ),
                          ),
                        Positioned.fill(
                          child: _OperativePatternGrid(
                            layout: layout,
                            activePoints: displayedPatternPoints.toSet(),
                            contentsByPointKey: widget.contentsByPointKey,
                            blockedPointKeys: widget.blockedPointKeys,
                            accent: widget.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _OperativePatternGrid extends StatelessWidget {
  final _OperativePatternGridLayout layout;
  final Set<OperativePatternPoint> activePoints;
  final Map<String, OperativePatternPointContent> contentsByPointKey;
  final Set<String> blockedPointKeys;
  final Color accent;

  const _OperativePatternGrid({
    required this.layout,
    required this.activePoints,
    required this.contentsByPointKey,
    required this.blockedPointKeys,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (final point in operativePatternPoints)
          _OperativePatternDot(
            point: point,
            center: layout.centerFor(point),
            size: layout.dotSize,
            isActive: activePoints.contains(point),
            isBlocked: blockedPointKeys.contains(point.key),
            content: contentsByPointKey[point.key],
            accent: accent,
          ),
      ],
    );
  }
}

class _OperativePatternDot extends StatelessWidget {
  final OperativePatternPoint point;
  final Offset center;
  final double size;
  final bool isActive;
  final bool isBlocked;
  final OperativePatternPointContent? content;
  final Color accent;

  const _OperativePatternDot({
    required this.point,
    required this.center,
    required this.size,
    required this.isActive,
    required this.isBlocked,
    required this.content,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: center.dx - (size / 2),
      top: center.dy - (size / 2),
      width: size,
      height: size,
      child: AnimatedScale(
        scale: isActive ? 1.1 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutBack,
        child: Semantics(
          label: isBlocked
              ? 'Punto ${point.label}, bloqueado'
              : 'Punto ${point.label}',
          child: _OperativePatternDotVisual(
            size: size,
            isActive: isActive,
            isBlocked: isBlocked,
            content: content,
            accent: accent,
          ),
        ),
      ),
    );
  }
}

class _OperativePatternGridLayout {
  final Size boardSize;
  final double side;
  final double dotSize;
  final double hitRadius;

  const _OperativePatternGridLayout({
    required this.boardSize,
    required this.side,
    required this.dotSize,
    required this.hitRadius,
  });

  factory _OperativePatternGridLayout.fromBoardSize(Size boardSize) {
    final side = min(boardSize.width * 0.94, boardSize.height * 0.94);
    final dotSize = (side * 0.14).clamp(22.0, 42.0).toDouble();

    return _OperativePatternGridLayout(
      boardSize: boardSize,
      side: side,
      dotSize: dotSize,
      hitRadius: dotSize * _operativePatternHitRadiusFactor,
    );
  }

  Offset centerFor(OperativePatternPoint point) {
    final topLeft = Offset(
      (boardSize.width - side) / 2,
      (boardSize.height - side) / 2,
    );
    final pointCenter = operativePatternPointCenter(
      point: point,
      boardSide: side,
    );

    return topLeft + pointCenter;
  }

  OperativePatternPoint? pointAt(Offset position) {
    OperativePatternPoint? nearestPoint;
    var nearestDistance = double.infinity;

    for (final point in operativePatternPoints) {
      final distance = (position - centerFor(point)).distance;
      if (distance <= hitRadius && distance < nearestDistance) {
        nearestPoint = point;
        nearestDistance = distance;
      }
    }

    return nearestPoint;
  }

  List<OperativePatternPoint> pointsCrossedBySegment({
    required Offset from,
    required Offset to,
    required Set<OperativePatternPoint> excludedPoints,
  }) {
    final segment = to - from;
    final segmentLengthSquared = segment.distanceSquared;
    if (segmentLengthSquared == 0) {
      final point = pointAt(to);
      if (point == null || excludedPoints.contains(point)) {
        return const <OperativePatternPoint>[];
      }
      return <OperativePatternPoint>[point];
    }

    final hits = <_OperativePatternPointHit>[];
    for (final point in operativePatternPoints) {
      if (excludedPoints.contains(point)) continue;

      final center = centerFor(point);
      final centerFromSegmentStart = center - from;
      final projection = ((centerFromSegmentStart.dx * segment.dx) +
              (centerFromSegmentStart.dy * segment.dy)) /
          segmentLengthSquared;
      if (projection < 0 || projection > 1) continue;

      final closestPoint = from + (segment * projection);
      if ((center - closestPoint).distance <= hitRadius) {
        hits.add(_OperativePatternPointHit(point: point, order: projection));
      }
    }

    hits.sort((a, b) => a.order.compareTo(b.order));
    return hits.map((hit) => hit.point).toList(growable: false);
  }

  Offset constrainSegmentByWalls({
    required Offset from,
    required Offset to,
    required List<OperativePatternWallSegment> wallSegments,
    required Set<String> connectedWallKeys,
  }) {
    final segment = to - from;
    if (segment.distanceSquared == 0 || wallSegments.isEmpty) return to;

    double? nearestIntersection;
    for (final wall in wallSegments) {
      final wallLine = wallLineFor(
        wall,
        isConnected: connectedWallKeys.contains(wall.key),
      );
      final intersection = _segmentIntersectionParameter(
        from,
        to,
        wallLine.start,
        wallLine.end,
      );
      if (intersection == null) continue;
      if (intersection <= 0 || intersection > 1) continue;
      if (nearestIntersection == null || intersection < nearestIntersection) {
        nearestIntersection = intersection;
      }
    }

    if (nearestIntersection == null) return to;
    return from + segment * max(0, nearestIntersection - 0.02);
  }

  _OperativePatternWallLine wallLineFor(
    OperativePatternWallSegment wall, {
    required bool isConnected,
  }) {
    final aCenter = centerFor(wall.a);
    final bCenter = centerFor(wall.b);
    final delta = bCenter - aCenter;
    final distance = delta.distance;
    if (distance <= 0) {
      return _OperativePatternWallLine(start: aCenter, end: aCenter);
    }

    final midpoint = Offset.lerp(aCenter, bCenter, 0.5)!;
    final normal = Offset(-delta.dy / distance, delta.dx / distance);
    final halfLength = distance *
        (isConnected
            ? OperativePatternWallSegment.connectedHalfLength
            : OperativePatternWallSegment.baseHalfLength);
    return _OperativePatternWallLine(
      start: midpoint - normal * halfLength,
      end: midpoint + normal * halfLength,
    );
  }

  double? _segmentIntersectionParameter(
    Offset a,
    Offset b,
    Offset c,
    Offset d,
  ) {
    final r = b - a;
    final s = d - c;
    final denominator = _cross(r, s);
    if (denominator.abs() < 0.000001) return null;

    final cMinusA = c - a;
    final t = _cross(cMinusA, s) / denominator;
    final u = _cross(cMinusA, r) / denominator;
    if (t < 0 || t > 1 || u < 0 || u > 1) return null;

    return t;
  }

  double _cross(Offset a, Offset b) {
    return (a.dx * b.dy) - (a.dy * b.dx);
  }
}

class _OperativePatternPointHit {
  final OperativePatternPoint point;
  final double order;

  const _OperativePatternPointHit({
    required this.point,
    required this.order,
  });
}

class _OperativePatternWallLine {
  final Offset start;
  final Offset end;

  const _OperativePatternWallLine({
    required this.start,
    required this.end,
  });
}

class _OperativePatternDotVisual extends StatelessWidget {
  final double size;
  final bool isActive;
  final bool isBlocked;
  final OperativePatternPointContent? content;
  final Color accent;

  const _OperativePatternDotVisual({
    required this.size,
    required this.isActive,
    required this.isBlocked,
    required this.content,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final currentItem = content?.item;
    final bonus = content?.bonus;
    final requirement = content?.requirement;
    final isBonusEnabled = content?.isBonusEnabled ?? true;
    final isPatternBonusActivated = content?.isPatternBonusActivated ?? false;
    final hasAura = content?.hasAura ?? false;
    final activatedAdjacencyBonuses = content?.activatedAdjacencyBonuses ??
        const <OperativePatternAdjacencyBonus>[];
    final hasPatternActivation =
        currentItem != null && isActive && isPatternBonusActivated;
    final hasAdjacencyActivation =
        isActive && activatedAdjacencyBonuses.isNotEmpty;
    final activeAccent = currentItem?.rarity.accent ?? bonus?.accent ?? accent;

    if (currentItem != null) {
      final itemFontSize = bonus == null
          ? (size * 0.78).clamp(22.0, 34.0).toDouble()
          : (size * 0.48).clamp(16.0, 23.0).toDouble();
      return SizedBox.square(
        dimension: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                margin: EdgeInsets.all(size * 0.06),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: EndpointPalette.blend(
                    EndpointPalette.panelBackground,
                    activeAccent,
                    isActive ? 0.26 : 0.13,
                  ),
                  border: Border.all(
                    color: activeAccent.withValues(
                      alpha: isBonusEnabled
                          ? (isActive ? 0.94 : 0.48)
                          : (isActive ? 0.58 : 0.28),
                    ),
                    width: isActive ? 2.2 : 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: activeAccent.withValues(
                        alpha: isActive ? 0.42 : 0.16,
                      ),
                      blurRadius: isActive ? 18 : 10,
                      spreadRadius: isActive ? 2 : 0,
                    ),
                  ],
                ),
              ),
            ),
            if (hasAura)
              _OperativePatternItemAura(
                size: size,
                accent: activeAccent,
              ),
            Center(
              child: Transform.rotate(
                angle: _operativePatternContentCounterRotation,
                child: EndpointText(
                  currentItem.iconEmoji,
                  style: TextStyle(
                    fontSize: itemFontSize,
                    height: 1,
                    shadows: [
                      if (isActive)
                        Shadow(
                          color: activeAccent.withValues(alpha: 0.84),
                          blurRadius: 18,
                        ),
                      if (isActive)
                        Shadow(
                          color: activeAccent.withValues(alpha: 0.54),
                          blurRadius: 28,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (bonus != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: size * 0.04,
                child: Center(
                  child: Transform.rotate(
                    angle: _operativePatternContentCounterRotation,
                    child: _OperativePatternBonusVisual(
                      bonus: bonus,
                      size: size * 0.56,
                      isActive: isActive,
                      isEnabled: isBonusEnabled,
                    ),
                  ),
                ),
              ),
            if (requirement != null)
              Positioned(
                right: 0,
                top: 0,
                child: Transform.rotate(
                  angle: _operativePatternContentCounterRotation,
                  child: _OperativePatternRequirementBadge(
                    requirement: requirement,
                    size: size,
                    isEnabled: isBonusEnabled,
                  ),
                ),
              ),
            if (isBlocked)
              OperativePatternBlockedMark(
                size: size,
                counterRotate: true,
              ),
            _OperativePatternActivationBurst(
              size: size,
              accent: activeAccent,
              hasPatternActivation: hasPatternActivation,
              hasAdjacencyActivation: hasAdjacencyActivation,
            ),
          ],
        ),
      );
    }

    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: EndpointPalette.blend(
                EndpointPalette.panelBackground,
                activeAccent,
                isActive ? 0.28 : 0.14,
              ),
              border: Border.all(
                color: activeAccent.withValues(alpha: isActive ? 1 : 0.86),
                width: isActive ? 2.4 : 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: activeAccent.withValues(alpha: isActive ? 0.5 : 0.2),
                  blurRadius: isActive ? 18 : 12,
                  spreadRadius: isActive ? 3 : 1,
                ),
              ],
            ),
            child: Center(
              child: Transform.rotate(
                angle: _operativePatternContentCounterRotation,
                child: _OperativePatternBonusVisual(
                  bonus: bonus ??
                      const OperativePatternBonus(
                        kind: OperativePatternBonusKind.barrier,
                        amount: 1,
                      ),
                  size: size,
                  isActive: isActive,
                  isEnabled: true,
                ),
              ),
            ),
          ),
          if (isBlocked)
            OperativePatternBlockedMark(
              size: size,
              counterRotate: true,
            ),
          _OperativePatternActivationBurst(
            size: size,
            accent: activeAccent,
            hasPatternActivation: false,
            hasAdjacencyActivation: false,
          ),
        ],
      ),
    );
  }
}

class _OperativePatternActivationBurst extends StatelessWidget {
  final double size;
  final Color accent;
  final bool hasPatternActivation;
  final bool hasAdjacencyActivation;

  const _OperativePatternActivationBurst({
    required this.size,
    required this.accent,
    required this.hasPatternActivation,
    required this.hasAdjacencyActivation,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasPatternActivation && !hasAdjacencyActivation) {
      return const SizedBox.shrink();
    }

    final hasFullActivation = hasPatternActivation && hasAdjacencyActivation;
    final icon = hasFullActivation
        ? Icons.local_fire_department_rounded
        : hasAdjacencyActivation
            ? Icons.hub_rounded
            : Icons.auto_awesome_rounded;
    final effectAccent =
        hasFullActivation ? EndpointPalette.warningAccent : accent;
    final burstSize = (size * 0.54).clamp(18.0, 26.0).toDouble();

    return Positioned(
      left: size * 0.05,
      bottom: size * 0.02,
      child: Transform.rotate(
        angle: _operativePatternContentCounterRotation,
        child: TweenAnimationBuilder<double>(
          key: ValueKey('$hasPatternActivation-$hasAdjacencyActivation'),
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.7 + (value * 0.3),
              child: Opacity(
                opacity: value.clamp(0.0, 1.0).toDouble(),
                child: child,
              ),
            );
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: EndpointPalette.panelBackgroundOpaque.withValues(
                alpha: 0.82,
              ),
              boxShadow: [
                BoxShadow(
                  color: effectAccent.withValues(alpha: 0.48),
                  blurRadius: hasFullActivation ? 20 : 12,
                  spreadRadius: hasFullActivation ? 3 : 1,
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(max(2, size * 0.05)),
              child: Icon(
                icon,
                size: burstSize,
                color: effectAccent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OperativePatternItemAura extends StatelessWidget {
  final double size;
  final Color accent;

  const _OperativePatternItemAura({
    required this.size,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final boltSize = (size * 0.32).clamp(12.0, 18.0).toDouble();
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          alignment: Alignment.center,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: EndpointPalette.warningAccent.withValues(
                      alpha: 0.42,
                    ),
                    blurRadius: 24,
                    spreadRadius: 5,
                  ),
                  BoxShadow(
                    color: accent.withValues(alpha: 0.34),
                    blurRadius: 18,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: SizedBox.square(dimension: size * 0.82),
            ),
            for (final spec in const <({double x, double y, double turns})>[
              (x: -0.34, y: -0.36, turns: -0.08),
              (x: 0.36, y: -0.26, turns: 0.09),
              (x: -0.28, y: 0.34, turns: 0.13),
            ])
              Transform.translate(
                offset: Offset(size * spec.x, size * spec.y),
                child: Transform.rotate(
                  angle: _operativePatternContentCounterRotation +
                      (pi * spec.turns),
                  child: Icon(
                    Icons.bolt_rounded,
                    size: boltSize,
                    color: EndpointPalette.warningAccent.withValues(
                      alpha: 0.96,
                    ),
                    shadows: [
                      Shadow(
                        color: EndpointPalette.warningAccent.withValues(
                          alpha: 0.7,
                        ),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class OperativePatternBlockedMark extends StatelessWidget {
  final double size;
  final bool counterRotate;

  const OperativePatternBlockedMark({
    super.key,
    required this.size,
    this.counterRotate = false,
  });

  @override
  Widget build(BuildContext context) {
    final markSize = (size * 1.04).clamp(28.0, 54.0).toDouble();
    final mark = Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          Icons.close_rounded,
          size: markSize,
          color: EndpointPalette.panelBackgroundOpaque.withValues(alpha: 0.82),
        ),
        Icon(
          Icons.close_rounded,
          size: markSize * 0.9,
          color: EndpointPalette.dangerAccent,
        ),
      ],
    );

    if (!counterRotate) return mark;
    return Transform.rotate(
      angle: _operativePatternContentCounterRotation,
      child: mark,
    );
  }
}

class _OperativePatternWallPainter extends CustomPainter {
  final List<OperativePatternWallSegment> wallSegments;
  final Set<String> connectedWallKeys;
  final _OperativePatternGridLayout layout;
  final Color accent;
  final double opacity;
  final double pulse;

  const _OperativePatternWallPainter({
    required this.wallSegments,
    required this.connectedWallKeys,
    required this.layout,
    required this.accent,
    this.opacity = 1,
    this.pulse = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final wall in wallSegments) {
      final wallLine = layout.wallLineFor(
        wall,
        isConnected: connectedWallKeys.contains(wall.key),
      );
      final delta = wallLine.end - wallLine.start;
      final distance = delta.distance;
      if (distance <= 0) continue;

      final direction = delta / distance;
      final normal = Offset(-direction.dy, direction.dx);
      final pulseScale = 1 + 0.18 * pulse;
      final pulseAlpha = 1 + 0.22 * pulse;

      final glowPaint = Paint()
        ..color = accent.withValues(
          alpha: (0.32 * opacity * pulseAlpha).clamp(0.0, 1.0),
        )
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 12 * pulseScale
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      final corePaint = Paint()
        ..color = accent.withValues(alpha: 0.95 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 5.2 * pulseScale;
      final edgePaint = Paint()
        ..color = EndpointPalette.softForeground.withValues(
          alpha: 0.78 * opacity,
        )
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.5 * pulseScale;

      canvas.drawLine(wallLine.start, wallLine.end, glowPaint);
      canvas.drawLine(wallLine.start, wallLine.end, corePaint);
      canvas.drawLine(
          wallLine.start + normal * 4, wallLine.end + normal * 4, edgePaint);
      canvas.drawLine(
          wallLine.start - normal * 4, wallLine.end - normal * 4, edgePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _OperativePatternWallPainter oldDelegate) {
    return oldDelegate.wallSegments != wallSegments ||
        oldDelegate.connectedWallKeys != connectedWallKeys ||
        oldDelegate.layout != layout ||
        oldDelegate.accent != accent ||
        oldDelegate.opacity != opacity ||
        oldDelegate.pulse != pulse;
  }
}

class OperativePatternWallGlyph extends StatelessWidget {
  final Color accent;
  final bool enabled;
  final bool animate;
  final double width;
  final double height;

  const OperativePatternWallGlyph({
    super.key,
    required this.accent,
    this.enabled = true,
    this.animate = false,
    this.width = 52,
    this.height = 26,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled ? accent : EndpointPalette.softForeground;
    final opacity = enabled ? 1.0 : 0.36;
    if (!animate) {
      return CustomPaint(
        size: Size(width, height),
        painter: _OperativePatternWallGlyphPainter(
          accent: color,
          opacity: opacity,
        ),
      );
    }

    return _PulsingOperativePatternWallGlyph(
      accent: color,
      opacity: opacity,
      width: width,
      height: height,
    );
  }
}

class _PulsingOperativePatternWallGlyph extends StatefulWidget {
  final Color accent;
  final double opacity;
  final double width;
  final double height;

  const _PulsingOperativePatternWallGlyph({
    required this.accent,
    required this.opacity,
    required this.width,
    required this.height,
  });

  @override
  State<_PulsingOperativePatternWallGlyph> createState() =>
      _PulsingOperativePatternWallGlyphState();
}

class _PulsingOperativePatternWallGlyphState
    extends State<_PulsingOperativePatternWallGlyph>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 920),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size(widget.width, widget.height),
          painter: _OperativePatternWallGlyphPainter(
            accent: widget.accent,
            opacity: widget.opacity,
            pulse: _controller.value,
          ),
        );
      },
    );
  }
}

class _OperativePatternWallGlyphPainter extends CustomPainter {
  final Color accent;
  final double opacity;
  final double pulse;

  const _OperativePatternWallGlyphPainter({
    required this.accent,
    required this.opacity,
    this.pulse = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final start = Offset(size.width * 0.18, size.height / 2);
    final end = Offset(size.width * 0.82, size.height / 2);
    const normal = Offset(0, 1);
    final pulseScale = 1 + 0.18 * pulse;
    final pulseAlpha = 1 + 0.22 * pulse;
    final glowPaint = Paint()
      ..color = accent.withValues(
        alpha: (0.32 * opacity * pulseAlpha).clamp(0.0, 1.0),
      )
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 12 * pulseScale
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    final corePaint = Paint()
      ..color = accent.withValues(alpha: 0.95 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.2 * pulseScale;
    final edgePaint = Paint()
      ..color = EndpointPalette.softForeground.withValues(
        alpha: 0.78 * opacity,
      )
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.5 * pulseScale;

    canvas.drawLine(start, end, glowPaint);
    canvas.drawLine(start, end, corePaint);
    canvas.drawLine(start + normal * 4, end + normal * 4, edgePaint);
    canvas.drawLine(start - normal * 4, end - normal * 4, edgePaint);
  }

  @override
  bool shouldRepaint(covariant _OperativePatternWallGlyphPainter oldDelegate) {
    return oldDelegate.accent != accent ||
        oldDelegate.opacity != opacity ||
        oldDelegate.pulse != pulse;
  }
}

class _OperativePatternBonusVisual extends StatelessWidget {
  final OperativePatternBonus bonus;
  final double size;
  final bool isActive;
  final bool isEnabled;

  const _OperativePatternBonusVisual({
    required this.bonus,
    required this.size,
    required this.isActive,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final accent = bonus.accent;
    final enabledOpacity = isEnabled ? 1.0 : 0.36;

    return SizedBox(
      width: size,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              bonus.iconAssetPath,
              width: (size * 0.34).clamp(10.0, 15.0).toDouble(),
              height: (size * 0.34).clamp(10.0, 15.0).toDouble(),
              filterQuality: FilterQuality.none,
              color: accent.withValues(
                alpha: (isActive ? 1 : 0.9) * enabledOpacity,
              ),
            ),
            SizedBox(width: max(1, size * 0.04)),
            EndpointText(
              '+${bonus.amount}',
              style: textSmallNumericBold.copyWith(
                color: accent.withValues(
                  alpha: (isActive ? 1.0 : 0.92) * enabledOpacity,
                ),
                fontSize: (size * 0.42).clamp(13.0, 18.0).toDouble(),
                letterSpacing: 0,
                shadows: [
                  Shadow(
                    color: accent.withValues(alpha: isEnabled ? 0.38 : 0.1),
                    blurRadius: isActive ? 12 : 7,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OperativePatternRequirementBadge extends StatelessWidget {
  final OperativePatternRequirement requirement;
  final double size;
  final bool isEnabled;

  const _OperativePatternRequirementBadge({
    required this.requirement,
    required this.size,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final badgeSize = (size * 0.34).clamp(13.0, 18.0).toDouble();
    final foreground = isEnabled
        ? EndpointPalette.softForeground
        : EndpointPalette.softForeground.withValues(alpha: 0.48);

    return SizedBox(
      width: badgeSize,
      height: badgeSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: EndpointPalette.panelBackgroundOpaque.withValues(
            alpha: isEnabled ? 0.82 : 0.58,
          ),
          border: Border.all(
            color: foreground.withValues(alpha: isEnabled ? 0.72 : 0.28),
            width: 1,
          ),
        ),
        child: Center(
          child: EndpointText(
            requirement.shortLabel,
            maxLines: 1,
            style: textSmallBold.copyWith(
              color: foreground,
              fontSize: (badgeSize * 0.42).clamp(6.0, 8.0).toDouble(),
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _OperativePatternEmptyBonusDialog extends StatelessWidget {
  final OperativePatternBonus bonus;

  const _OperativePatternEmptyBonusDialog({
    required this.bonus,
  });

  @override
  Widget build(BuildContext context) {
    final accent = bonus.accent;
    final foreground = EndpointPalette.soften(accent, amount: 0.48);
    final surface = EndpointPalette.blend(
      EndpointPalette.panelBackground,
      accent,
      0.1,
    );

    return EndpointDetailsDialogScaffold(
      accent: accent,
      backgroundColor: EndpointPalette.panelBackgroundOpaque,
      foregroundColor: foreground,
      closeBackgroundColor: surface,
      maxWidth: 240,
      maxHeightFactor: 0.42,
      child: Center(
        child: SizedBox.square(
          dimension: _operativePatternEmptyBonusDialogSize,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: accent.withValues(alpha: 0.92),
                width: 1.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.24),
                  blurRadius: 22,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    bonus.iconAssetPath,
                    width: 34,
                    height: 34,
                    filterQuality: FilterQuality.none,
                    color: accent,
                  ),
                  const SizedBox(width: 8),
                  EndpointText(
                    '+${bonus.amount}',
                    style: textLargeNumericBold.copyWith(
                      color: accent,
                      fontSize: 44,
                      letterSpacing: 0.4,
                      shadows: [
                        Shadow(
                          color: accent.withValues(alpha: 0.36),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OperativePatternDragLinePainter extends CustomPainter {
  final List<Offset> points;
  final Offset? finger;
  final Color accent;
  final bool isClosed;

  const _OperativePatternDragLinePainter({
    required this.points,
    required this.finger,
    required this.accent,
    required this.isClosed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    if (isClosed && points.length >= 4) {
      final sealPath = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        sealPath.lineTo(point.dx, point.dy);
      }
      sealPath.close();

      final sealFillPaint = Paint()
        ..color = accent.withValues(alpha: 0.11)
        ..style = PaintingStyle.fill;
      final sealStrokePaint = Paint()
        ..color = accent.withValues(alpha: 0.34)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(sealPath, sealFillPaint);
      canvas.drawPath(sealPath, sealStrokePaint);
    }

    final glowPaint = Paint()
      ..color = accent.withValues(alpha: 0.24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    final corePaint = Paint()
      ..color = EndpointPalette.neutralAccent.withValues(alpha: 0.76)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    final resolvedFinger = finger;
    if (resolvedFinger != null) {
      path.lineTo(resolvedFinger.dx, resolvedFinger.dy);
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, corePaint);
  }

  @override
  bool shouldRepaint(covariant _OperativePatternDragLinePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.finger != finger ||
        oldDelegate.accent != accent ||
        oldDelegate.isClosed != isClosed;
  }
}
