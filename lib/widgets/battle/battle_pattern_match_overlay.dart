import '../_imports.dart';
import '../../services/operative_pattern_bonus_service.dart';
import '../../services/operative_pattern_combat_rules.dart';
import '../../services/operative_pattern_resolution_service.dart';

const _battlePatternMatchDuration = Duration(seconds: 15);
const _battlePatternEnemyTravel = 42.0;
const _battlePatternEnemySize = 112.0;
const _battlePatternBlockStartDelay = Duration(milliseconds: 500);
const _battlePatternBlockTravelDuration = Duration(milliseconds: 1100);
const _battlePatternBlockMarkSize = 50.0;

class BattlePatternMatchResult {
  final int attackBonus;
  final int barrierBonus;

  const BattlePatternMatchResult({
    required this.attackBonus,
    required this.barrierBonus,
  });

  factory BattlePatternMatchResult.fromResolution(
    OperativePatternResolution resolution,
  ) {
    return BattlePatternMatchResult(
      attackBonus: resolution.attackBonus,
      barrierBonus: resolution.barrierBonus,
    );
  }

  bool get hasBonus => attackBonus > 0 || barrierBonus > 0;
}

class BattlePatternMatchOverlay extends StatefulWidget {
  final Battler player;
  final Battler enemy;
  final Map<String, Item> equippedItemsByPointKey;
  final int Function(int max)? randomNextInt;

  const BattlePatternMatchOverlay({
    super.key,
    required this.player,
    required this.enemy,
    required this.equippedItemsByPointKey,
    this.randomNextInt,
  });

  @override
  State<BattlePatternMatchOverlay> createState() =>
      _BattlePatternMatchOverlayState();
}

class _BattlePatternMatchOverlayState extends State<BattlePatternMatchOverlay>
    with TickerProviderStateMixin {
  final GlobalKey _matchStackKey = GlobalKey();
  final GlobalKey _enemySpriteKey = GlobalKey();
  final GlobalKey _patternBoardKey = GlobalKey();
  late final AnimationController _enemyMotionController;
  late final AnimationController _blockMotionController;
  late final Map<String, OperativePatternBonus> _bonusesByPointKey;
  late final int _maxPatternPoints;
  late final OperativePatternPoint _blockedPoint;
  Timer? _countdownTimer;
  Timer? _blockStartTimer;
  Animation<Offset>? _blockMarkMotion;
  List<OperativePatternPoint> _patternPoints = const <OperativePatternPoint>[];
  int _secondsRemaining = _battlePatternMatchDuration.inSeconds;
  bool _blockAnimationStarted = false;
  bool _blockAnimationCompleted = false;
  bool _hasSubmitted = false;

  @override
  void initState() {
    super.initState();
    _enemyMotionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
    _blockMotionController = AnimationController(
      vsync: this,
      duration: _battlePatternBlockTravelDuration,
    )..addStatusListener(_handleBlockMotionStatus);
    final randomNextInt = widget.randomNextInt ?? Random().nextInt;
    _blockedPoint =
        operativePatternPoints[randomNextInt(operativePatternPoints.length)];
    _bonusesByPointKey = buildOperativePatternBonusesByPointKey(
      playerLevel: widget.player.level,
      occupiedPointKeys: widget.equippedItemsByPointKey.keys,
      nextInt: randomNextInt,
    );
    _maxPatternPoints = OperativePatternCombatRules.maxPatternPointsFor(
      widget.player,
    );
    _scheduleBlockAnimationConfiguration();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _blockStartTimer?.cancel();
    _blockMotionController.dispose();
    _enemyMotionController.dispose();
    super.dispose();
  }

  void _scheduleBlockAnimationConfiguration() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _configureBlockAnimation();
    });
  }

  void _configureBlockAnimation() {
    if (!mounted || _blockAnimationStarted) return;

    final start = _localCenterFor(_enemySpriteKey);
    final end = _localBlockedPointCenter();
    if (start == null || end == null) {
      _scheduleBlockAnimationConfiguration();
      return;
    }

    _blockMarkMotion = Tween<Offset>(
      begin: start,
      end: end,
    ).animate(
      CurvedAnimation(
        parent: _blockMotionController,
        curve: Curves.easeInOutCubic,
      ),
    );

    setState(() {
      _blockAnimationStarted = true;
    });
    _blockStartTimer?.cancel();
    _blockStartTimer = Timer(_battlePatternBlockStartDelay, () {
      if (!mounted || _blockAnimationCompleted) return;
      _blockMotionController.forward();
    });
  }

  Offset? _localCenterFor(GlobalKey key) {
    final stackRenderObject = _matchStackKey.currentContext?.findRenderObject();
    final targetRenderObject = key.currentContext?.findRenderObject();
    if (stackRenderObject is! RenderBox ||
        targetRenderObject is! RenderBox ||
        !stackRenderObject.hasSize ||
        !targetRenderObject.hasSize ||
        targetRenderObject.size.width <= 0 ||
        targetRenderObject.size.height <= 0) {
      return null;
    }

    final targetCenter = Offset(
      targetRenderObject.size.width / 2,
      targetRenderObject.size.height / 2,
    );
    return stackRenderObject.globalToLocal(
      targetRenderObject.localToGlobal(targetCenter),
    );
  }

  Offset? _localBlockedPointCenter() {
    final stackRenderObject = _matchStackKey.currentContext?.findRenderObject();
    final boardRenderObject =
        _patternBoardKey.currentContext?.findRenderObject();
    if (stackRenderObject is! RenderBox ||
        boardRenderObject is! RenderBox ||
        !stackRenderObject.hasSize ||
        !boardRenderObject.hasSize ||
        boardRenderObject.size.width <= 0 ||
        boardRenderObject.size.height <= 0) {
      return null;
    }

    final localPointCenter = operativePatternBoardLocalCenterFor(
      boardSize: boardRenderObject.size,
      point: _blockedPoint,
    );
    return stackRenderObject.globalToLocal(
      boardRenderObject.localToGlobal(localPointCenter),
    );
  }

  void _handleBlockMotionStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed ||
        _blockAnimationCompleted ||
        !mounted) {
      return;
    }

    setState(() {
      _blockAnimationCompleted = true;
    });
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _hasSubmitted) return;
      if (_secondsRemaining <= 1) {
        _submit();
        return;
      }
      setState(() {
        _secondsRemaining--;
      });
    });
  }

  OperativePatternResolution get _currentResolution {
    return OperativePatternResolutionService.resolve(
      patternPoints: _patternPoints,
      equippedItemsByPointKey: widget.equippedItemsByPointKey,
      bonusesByPointKey: _bonusesByPointKey,
      blockedPointKeys: _blockAnimationCompleted
          ? <String>{_blockedPoint.key}
          : const <String>{},
    );
  }

  BattlePatternMatchResult get _currentResult =>
      BattlePatternMatchResult.fromResolution(_currentResolution);

  void _handlePatternChanged(List<OperativePatternPoint> points) {
    setState(() {
      _patternPoints = points;
    });
  }

  void _submit() {
    if (_hasSubmitted || !_blockAnimationCompleted) return;
    _hasSubmitted = true;
    Navigator.of(context).pop(_currentResult);
  }

  Map<String, OperativePatternPointContent> _buildContentsByPointKey(
    OperativePatternResolution resolution,
  ) {
    return <String, OperativePatternPointContent>{
      for (final entry in widget.equippedItemsByPointKey.entries)
        entry.key: OperativePatternPointContent(
          item: entry.value,
          bonus: entry.value.patternBonus,
          requirement: entry.value.patternRequirement,
          adjacencyBonuses: entry.value.patternAdjacencyBonuses,
          activatedAdjacencyBonuses:
              resolution.activatedAdjacencyBonusesAt(entry.key),
          isBonusEnabled: resolution.isItemBonusEnabledAt(entry.key),
          isPatternBonusActivated: resolution.isItemBonusEnabledAt(entry.key),
        ),
      for (final entry in _bonusesByPointKey.entries)
        entry.key: OperativePatternPointContent(bonus: entry.value),
    };
  }

  @override
  Widget build(BuildContext context) {
    final resolution = _currentResolution;
    final result = BattlePatternMatchResult.fromResolution(resolution);
    final isClosed = resolution.isClosed;
    final blockedPointKeys = _blockAnimationCompleted
        ? <String>{_blockedPoint.key}
        : const <String>{};
    final isBoardDimmed = !_blockAnimationCompleted;
    final isEnemyDimmed = _blockAnimationCompleted;

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 560,
              maxHeight: 740,
            ),
            child: EndpointPanel(
              accent: EndpointPalette.neutralAccent,
              backgroundColor: EndpointPalette.panelBackgroundOpaque,
              borderRadius: 18,
              glowOpacity: 0.12,
              blurRadius: 22,
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Stack(
                key: _matchStackKey,
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _BattlePatternEnemyStage(
                              enemy: widget.enemy,
                              animation: _enemyMotionController,
                              enemySpriteKey: _enemySpriteKey,
                              secondsRemaining: _secondsRemaining,
                            ),
                            _BattlePatternFocusDimmer(
                              isVisible: isEnemyDimmed,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Center(
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: FractionallySizedBox(
                                  widthFactor: 0.76,
                                  heightFactor: 0.76,
                                  child: IgnorePointer(
                                    ignoring: !_blockAnimationCompleted,
                                    child: Transform.rotate(
                                      angle: pi / 4,
                                      child: OperativePatternBoard(
                                        key: _patternBoardKey,
                                        contentsByPointKey:
                                            _buildContentsByPointKey(
                                          resolution,
                                        ),
                                        blockedPointKeys: blockedPointKeys,
                                        keepLineAfterPointerUp: true,
                                        maxPatternPoints: _maxPatternPoints,
                                        accent: EndpointPalette.neutralAccent,
                                        onPatternChanged: _handlePatternChanged,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            _BattlePatternFocusDimmer(
                              isVisible: isBoardDimmed,
                              opacity: 0.58,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _BattlePatternMatchFooter(
                        isClosed: isClosed,
                        attackBonus: result.attackBonus,
                        barrierBonus: result.barrierBonus,
                        pointCount: resolution.distinctPointCount,
                        maxPointCount: _maxPatternPoints,
                        onPressed: _blockAnimationCompleted ? _submit : null,
                      ),
                    ],
                  ),
                  if (!_blockAnimationCompleted && _blockMarkMotion != null)
                    _BattlePatternBlockMotion(
                      animation: _blockMarkMotion!,
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

class _BattlePatternEnemyStage extends StatelessWidget {
  final Battler enemy;
  final Animation<double> animation;
  final Key enemySpriteKey;
  final int secondsRemaining;

  const _BattlePatternEnemyStage({
    required this.enemy,
    required this.animation,
    required this.enemySpriteKey,
    required this.secondsRemaining,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: 0,
          right: 0,
          child: EndpointText(
            '${max(0, secondsRemaining)}',
            style: textMediumNumericBold.copyWith(
              color: EndpointPalette.neutralAccent,
              fontSize: 18,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Center(
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              final phase = sin(animation.value * pi * 2);
              return Transform.translate(
                offset: Offset(phase * _battlePatternEnemyTravel, 0),
                child: child,
              );
            },
            child: EndpointEmojiSprite(
              key: enemySpriteKey,
              emoji: enemy.iconEmoji,
              accent: EndpointPalette.dangerAccent,
              size: _battlePatternEnemySize,
            ),
          ),
        ),
      ],
    );
  }
}

class _BattlePatternFocusDimmer extends StatelessWidget {
  final bool isVisible;
  final double opacity;

  const _BattlePatternFocusDimmer({
    required this.isVisible,
    this.opacity = 0.46,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        opacity: isVisible ? 1 : 0,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: opacity),
          ),
        ),
      ),
    );
  }
}

class _BattlePatternMatchFooter extends StatelessWidget {
  final bool isClosed;
  final int attackBonus;
  final int barrierBonus;
  final int pointCount;
  final int maxPointCount;
  final VoidCallback? onPressed;

  const _BattlePatternMatchFooter({
    required this.isClosed,
    required this.attackBonus,
    required this.barrierBonus,
    required this.pointCount,
    required this.maxPointCount,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _BattlePatternResultPill(
            iconAssetPath: 'assets/images/icons/icon_sword.png',
            value: attackBonus,
            accent: EndpointPalette.dangerAccent,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _BattlePatternResultPill(
            iconAssetPath: 'assets/images/icons/icon_shield.png',
            value: barrierBonus,
            accent: BattlerStat.barrier.accent,
          ),
        ),
        const SizedBox(width: 8),
        _BattlePatternPointLimitPill(
          pointCount: pointCount,
          maxPointCount: maxPointCount,
        ),
        const SizedBox(width: 8),
        EndpointActionButton(
          label: isClosed ? 'MATCHED' : 'MATCH',
          icon: Icons.join_inner_rounded,
          onPressed: onPressed,
          tooltip: isClosed ? 'Resolver patron' : 'Cerrar sin patron cerrado',
          width: 122,
          height: 42,
          useMarquee: false,
          backgroundColor: EndpointPalette.controlBackground,
          foregroundColor: EndpointPalette.softForeground,
          accent: isClosed
              ? EndpointPalette.patternAccent
              : EndpointPalette.neutralAccent,
          textStyle: textSmallBold.copyWith(letterSpacing: 1),
        ),
      ],
    );
  }
}

class _BattlePatternPointLimitPill extends StatelessWidget {
  final int pointCount;
  final int maxPointCount;

  const _BattlePatternPointLimitPill({
    required this.pointCount,
    required this.maxPointCount,
  });

  @override
  Widget build(BuildContext context) {
    final isFull = pointCount >= maxPointCount;
    final accent =
        isFull ? EndpointPalette.warningAccent : EndpointPalette.neutralAccent;

    return Tooltip(
      message: 'Vertices de patron disponibles',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: EndpointPalette.controlBackground,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: accent.withValues(alpha: 0.52)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(9, 6, 9, 6),
          child: EndpointText(
            '$pointCount/$maxPointCount',
            style: textSmallNumericBold.copyWith(
              color: accent,
              fontSize: 13,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}

class _BattlePatternBlockMotion extends StatelessWidget {
  final Animation<Offset> animation;

  const _BattlePatternBlockMotion({
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: const IgnorePointer(
        child: OperativePatternBlockedMark(
          size: _battlePatternBlockMarkSize,
        ),
      ),
      builder: (context, child) {
        final offset = animation.value;
        return Positioned(
          left: offset.dx - (_battlePatternBlockMarkSize / 2),
          top: offset.dy - (_battlePatternBlockMarkSize / 2),
          child: child!,
        );
      },
    );
  }
}

class _BattlePatternResultPill extends StatelessWidget {
  final String iconAssetPath;
  final int value;
  final Color accent;

  const _BattlePatternResultPill({
    required this.iconAssetPath,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: EndpointPalette.controlBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              iconAssetPath,
              width: 16,
              height: 16,
              filterQuality: FilterQuality.none,
              color: accent,
            ),
            const SizedBox(width: 5),
            EndpointText(
              '+$value',
              style: textSmallNumericBold.copyWith(
                color: accent,
                fontSize: 13,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
