import '../_imports.dart';

enum _HackathonStage {
  intro,
  countdown,
  playing,
  scoreReveal,
  reward,
}

class HackathonBoothEventPage extends StatefulWidget {
  final Battler player;
  final EventPathNode node;
  final RunRandomizer randomizer;
  final PathEventService eventService;

  const HackathonBoothEventPage({
    super.key,
    required this.player,
    required this.node,
    required this.randomizer,
    this.eventService = const PathEventService(),
  });

  @override
  State<HackathonBoothEventPage> createState() =>
      _HackathonBoothEventPageState();
}

class _HackathonBoothEventPageState extends State<HackathonBoothEventPage> {
  static const _roundLengths = [3, 4, 5, 6, 7, 9];
  static const _gameDuration = Duration(seconds: 30);

  _HackathonStage _stage = _HackathonStage.intro;
  Timer? _countdownTimer;
  Timer? _gameTimer;
  Timer? _scoreRevealTimer;
  Duration _remaining = _gameDuration;
  int _preStartTick = 3;
  int _score = 0;
  int _roundIndex = 0;
  int _flavorPageIndex = 0;
  List<Set<int>> _targets = const [];
  final Set<int> _drawnPoints = <int>{};
  bool _showGreat = false;
  bool _claimedReward = false;

  bool get _isFlavorIntroVisible =>
      widget.node.flavorTexts.isNotEmpty &&
      _flavorPageIndex < widget.node.flavorTexts.length;

  Set<int> get _currentTarget =>
      _targets.isEmpty ? const <int>{} : _targets[_roundIndex];

  double get _timerProgress =>
      (_remaining.inMilliseconds / _gameDuration.inMilliseconds)
          .clamp(0.0, 1.0)
          .toDouble();

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _gameTimer?.cancel();
    _scoreRevealTimer?.cancel();
    super.dispose();
  }

  void _advanceFlavorIntro() {
    if (!_isFlavorIntroVisible) return;
    setState(() => _flavorPageIndex++);
  }

  void _close() {
    Navigator.of(context).pop(
      PathEventVisitResult(
        player: widget.player,
        outcomeText: 'Los cyber-nerds vuelven a su cola de builds.',
      ),
    );
  }

  void _startChallenge() {
    _targets = _buildTargets();
    _drawnPoints.clear();
    _preStartTick = 3;
    _score = 0;
    _roundIndex = 0;
    _remaining = _gameDuration;
    setState(() {
      _stage = _HackathonStage.countdown;
      _showGreat = false;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_preStartTick > 1) {
        setState(() => _preStartTick--);
        return;
      }
      if (_preStartTick == 1) {
        setState(() => _preStartTick = 0);
        return;
      }
      timer.cancel();
      _beginTimedGame();
    });
  }

  void _beginTimedGame() {
    setState(() => _stage = _HackathonStage.playing);
    final startedAt = DateTime.now();
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final elapsed = DateTime.now().difference(startedAt);
      final remaining = _gameDuration - elapsed;
      if (remaining <= Duration.zero) {
        _finishGame();
        return;
      }
      setState(() => _remaining = remaining);
    });
  }

  void _finishGame() {
    _gameTimer?.cancel();
    _countdownTimer?.cancel();
    setState(() {
      _remaining = Duration.zero;
      _stage = _HackathonStage.scoreReveal;
      _showGreat = false;
    });
    _scoreRevealTimer?.cancel();
    _scoreRevealTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _stage = _HackathonStage.reward);
    });
  }

  void _registerPoint(int index) {
    if (_stage != _HackathonStage.playing) return;
    setState(() => _drawnPoints.add(index));
  }

  void _submitDrawnShape() {
    if (_stage != _HackathonStage.playing || _drawnPoints.isEmpty) return;
    final matched = _setsMatch(_drawnPoints, _currentTarget);
    if (!matched) {
      setState(() => _drawnPoints.clear());
      return;
    }

    _score++;
    if (_score >= _roundLengths.length) {
      _finishGame();
      return;
    }

    setState(() {
      _roundIndex = min(_roundIndex + 1, _targets.length - 1);
      _drawnPoints.clear();
      _showGreat = true;
    });
    Timer(const Duration(milliseconds: 650), () {
      if (!mounted || _stage != _HackathonStage.playing) return;
      setState(() => _showGreat = false);
    });
  }

  void _claimReward() {
    if (_claimedReward) return;
    _claimedReward = true;
    Navigator.of(context).pop(
      widget.eventService.resolveHackathonReward(
        player: widget.player,
        score: _score,
        randomizer: widget.randomizer,
      ),
    );
  }

  List<Set<int>> _buildTargets() {
    return List<Set<int>>.unmodifiable(
      _roundLengths.map(_buildTargetShape),
    );
  }

  Set<int> _buildTargetShape(int pointCount) {
    final selected = <int>{widget.randomizer.nextInt(9)};
    while (selected.length < pointCount) {
      final frontier = selected
          .expand(_neighborsFor)
          .where((index) => !selected.contains(index))
          .toList(growable: false);
      if (frontier.isEmpty) {
        selected.add(widget.randomizer.nextInt(9));
        continue;
      }
      selected.add(frontier[widget.randomizer.nextInt(frontier.length)]);
    }
    return Set<int>.unmodifiable(selected);
  }

  List<int> _neighborsFor(int index) {
    final row = index ~/ 3;
    final col = index % 3;
    final neighbors = <int>[];
    for (var rowDelta = -1; rowDelta <= 1; rowDelta++) {
      for (var colDelta = -1; colDelta <= 1; colDelta++) {
        if (rowDelta == 0 && colDelta == 0) continue;
        final nextRow = row + rowDelta;
        final nextCol = col + colDelta;
        if (nextRow < 0 || nextRow > 2 || nextCol < 0 || nextCol > 2) {
          continue;
        }
        neighbors.add((nextRow * 3) + nextCol);
      }
    }
    return neighbors;
  }

  bool _setsMatch(Set<int> left, Set<int> right) {
    if (left.length != right.length) return false;
    return left.every(right.contains);
  }

  @override
  Widget build(BuildContext context) {
    return EndpointCenterStageScene(
      showTitle: widget.node.showTitle,
      background: EndpointGradients.event(widget.node.accent),
      foregroundOverlay: _isFlavorIntroVisible
          ? EndpointEventFlavorIntroOverlay(
              pages: widget.node.flavorTexts,
              pageIndex: _flavorPageIndex,
              emoji: widget.node.flavorEmoji ?? widget.node.iconEmoji,
              accent: widget.node.accent,
              onAdvance: _advanceFlavorIntro,
            )
          : null,
      onClose: _close,
      closeTooltip: EndpointStrings.backToRoute,
      accent: widget.node.accent,
      emoji: widget.node.iconEmoji,
      title: widget.node.eventTitle,
      content: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_stage == _HackathonStage.intro) return _buildIntroContent();
    return _buildGameContent();
  }

  Widget _buildIntroContent() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640),
      child: EndpointPanel(
        accent: widget.node.accent,
        backgroundColor: EndpointPalette.panelBackgroundSoft,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EndpointText(
              widget.node.description,
              textAlign: TextAlign.center,
              maxLines: null,
              style: textMedium.copyWith(
                color: EndpointPalette.softForeground.withAlpha(214),
              ),
            ),
            const SizedBox(height: 14),
            EndpointActionButton(
              label: 'Aceptar trial',
              icon: Icons.play_arrow_rounded,
              onPressed: _startChallenge,
              tooltip: 'Iniciar reto de patrones',
              accent: widget.node.accent,
              expands: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameContent() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560, maxHeight: 680),
      child: AspectRatio(
        aspectRatio: 0.72,
        child: Stack(
          children: [
            EndpointPanel(
              accent: widget.node.accent,
              backgroundColor: EndpointPalette.panelBackgroundSoft,
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Expanded(
                    flex: 25,
                    child: _HackathonMatrix(
                      points: _currentTarget,
                      accent: widget.node.accent,
                      readOnly: true,
                    ),
                  ),
                  Expanded(
                    flex: 50,
                    child: _HackathonMatrix(
                      points: _drawnPoints,
                      accent: widget.node.accent,
                      onPoint: _registerPoint,
                      onSubmit: _submitDrawnShape,
                    ),
                  ),
                  Expanded(
                    flex: 25,
                    child: _buildTimerArea(),
                  ),
                ],
              ),
            ),
            if (_stage == _HackathonStage.countdown) _buildCountdownOverlay(),
            if (_stage == _HackathonStage.scoreReveal) _buildScoreOverlay(),
            if (_showGreat) _buildGreatOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerArea() {
    if (_stage == _HackathonStage.reward) {
      return Center(
        child: EndpointActionButton(
          label: _score <= 1 ? 'Cerrar trial' : 'Reclamar premio',
          icon: Icons.card_giftcard_rounded,
          onPressed: _claimReward,
          tooltip: 'Cerrar Hackathon Booth',
          accent: widget.node.accent,
          expands: true,
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _timerProgress,
              minHeight: 12,
              backgroundColor: EndpointPalette.panelBackground,
              valueColor: AlwaysStoppedAnimation<Color>(widget.node.accent),
            ),
          ),
          const SizedBox(height: 8),
          EndpointText(
            '${(_remaining.inMilliseconds / 1000).ceil()}s',
            style: textMediumNumericBold.copyWith(
              color: EndpointPalette.softForeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownOverlay() {
    final label = _preStartTick == 0 ? 'GO!' : '$_preStartTick';
    return _HackathonOverlay(
      child: EndpointText(
        label,
        style: textLargeNumericBold.copyWith(
          color: widget.node.accent,
          fontSize: 56,
        ),
      ),
    );
  }

  Widget _buildScoreOverlay() {
    return _HackathonOverlay(
      child: EndpointText(
        'Score: $_score/6',
        style: textLargeNumericBold.copyWith(
          color: EndpointPalette.softForeground,
          fontSize: 34,
        ),
      ),
    );
  }

  Widget _buildGreatOverlay() {
    return IgnorePointer(
      child: Center(
        child: EndpointText(
          'Great!',
          style: textLargeBold.copyWith(
            color: widget.node.accent,
            fontSize: 30,
          ),
        ),
      ),
    );
  }
}

class _HackathonOverlay extends StatelessWidget {
  final Widget child;

  const _HackathonOverlay({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withAlpha(168),
        child: Center(child: child),
      ),
    );
  }
}

class _HackathonMatrix extends StatelessWidget {
  final Set<int> points;
  final Color accent;
  final bool readOnly;
  final ValueChanged<int>? onPoint;
  final VoidCallback? onSubmit;

  const _HackathonMatrix({
    required this.points,
    required this.accent,
    this.readOnly = false,
    this.onPoint,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final painter = _HackathonMatrixPainter(
      points: points,
      accent: accent,
      readOnly: readOnly,
    );
    final canvas = CustomPaint(
      painter: painter,
      child: const SizedBox.expand(),
    );
    if (readOnly) return canvas;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanDown: (details) => _handlePosition(details.localPosition, context),
      onPanUpdate: (details) => _handlePosition(details.localPosition, context),
      onPanEnd: (_) => onSubmit?.call(),
      onTapUp: (_) => onSubmit?.call(),
      child: canvas,
    );
  }

  void _handlePosition(Offset position, BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    final size = box?.size;
    if (size == null) return;
    final index = _nearestPointIndex(position, size);
    if (index == null) return;
    onPoint?.call(index);
  }
}

class _HackathonMatrixPainter extends CustomPainter {
  final Set<int> points;
  final Color accent;
  final bool readOnly;

  const _HackathonMatrixPainter({
    required this.points,
    required this.accent,
    required this.readOnly,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final anchors = _matrixAnchors(size);
    final linePaint = Paint()
      ..color = accent.withAlpha(readOnly ? 190 : 230)
      ..strokeWidth = readOnly ? 3 : 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final gridPaint = Paint()
      ..color = EndpointPalette.softForeground.withAlpha(54)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;

    for (var index = 0; index < 9; index++) {
      for (final neighbor in _cardinalNeighbors(index)) {
        if (neighbor <= index) continue;
        canvas.drawLine(anchors[index], anchors[neighbor], gridPaint);
      }
    }

    final orderedPoints = points.toList(growable: false)..sort();
    for (var index = 1; index < orderedPoints.length; index++) {
      canvas.drawLine(
        anchors[orderedPoints[index - 1]],
        anchors[orderedPoints[index]],
        linePaint,
      );
    }

    for (var index = 0; index < anchors.length; index++) {
      final isActive = points.contains(index);
      final fillPaint = Paint()
        ..color = isActive
            ? accent
            : EndpointPalette.panelBackground.withAlpha(readOnly ? 180 : 230);
      final strokePaint = Paint()
        ..color = isActive
            ? EndpointPalette.soften(accent)
            : EndpointPalette.softForeground.withAlpha(118)
        ..strokeWidth = isActive ? 2.6 : 1.4
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(anchors[index], isActive ? 9 : 7, fillPaint);
      canvas.drawCircle(anchors[index], isActive ? 9 : 7, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HackathonMatrixPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.accent != accent ||
        oldDelegate.readOnly != readOnly;
  }
}

List<int> _cardinalNeighbors(int index) {
  final row = index ~/ 3;
  final col = index % 3;
  final neighbors = <int>[];
  if (row > 0) neighbors.add(index - 3);
  if (row < 2) neighbors.add(index + 3);
  if (col > 0) neighbors.add(index - 1);
  if (col < 2) neighbors.add(index + 1);
  return neighbors;
}

List<Offset> _matrixAnchors(Size size) {
  final side = min(size.width, size.height) * 0.72;
  final center = Offset(size.width / 2, size.height / 2);
  final spacing = side / 2;
  final anchors = <Offset>[];
  for (var row = 0; row < 3; row++) {
    for (var col = 0; col < 3; col++) {
      final x = (col - 1) * spacing;
      final y = (row - 1) * spacing;
      anchors.add(
        center + Offset((x - y) * 0.72, (x + y) * 0.42),
      );
    }
  }
  return anchors;
}

int? _nearestPointIndex(Offset position, Size size) {
  final anchors = _matrixAnchors(size);
  final threshold = min(size.width, size.height) * 0.11;
  var nearestIndex = -1;
  var nearestDistance = double.infinity;
  for (var index = 0; index < anchors.length; index++) {
    final distance = (anchors[index] - position).distance;
    if (distance >= nearestDistance) continue;
    nearestDistance = distance;
    nearestIndex = index;
  }

  if (nearestIndex < 0 || nearestDistance > threshold) return null;
  return nearestIndex;
}
