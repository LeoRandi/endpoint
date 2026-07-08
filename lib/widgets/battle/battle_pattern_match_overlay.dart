import '_imports.dart';
import 'package:flutter/foundation.dart';
import 'battle_pattern_match_presenter.dart';

class BattlePatternAnimationTargets {
  final Rect playerSpriteRect;
  final Rect enemySpriteRect;
  final Rect playerStatusRect;
  final Rect enemyStatusRect;

  const BattlePatternAnimationTargets({
    required this.playerSpriteRect,
    required this.enemySpriteRect,
    required this.playerStatusRect,
    required this.enemyStatusRect,
  });
}

class BattlePatternVisualBattlers {
  final Battler player;
  final Battler enemy;

  const BattlePatternVisualBattlers({
    required this.player,
    required this.enemy,
  });
}

const _enemyPatternPointStepDuration = Duration(milliseconds: 750);
const _augmentPatternHintInitialDelay = Duration(seconds: 2);
const _augmentPatternHintDrawDuration = Duration(milliseconds: 1400);
const _augmentPatternHintHoldDuration = Duration(seconds: 1);
const _augmentPatternHintFadeDuration = Duration(milliseconds: 600);
const _augmentPatternHintGapDuration = Duration(seconds: 1);
const _battleActionPileEntryFadeDuration = Duration(milliseconds: 320);

enum _BattlePatternBlockPlacementMode {
  wall,
  point,
}

class BattlePatternEnemyBlockAction {
  final OperativePatternWallSegment? wallSegment;
  final OperativePatternPoint? point;

  const BattlePatternEnemyBlockAction.wall(
    OperativePatternWallSegment this.wallSegment,
  ) : point = null;

  const BattlePatternEnemyBlockAction.point(OperativePatternPoint this.point)
      : wallSegment = null;

  bool get isEmpty => wallSegment == null && point == null;
}

class _AugmentPatternHint {
  final int augmentId;
  final RarityTier tier;
  final List<OperativePatternPoint> points;

  const _AugmentPatternHint({
    required this.augmentId,
    required this.tier,
    required this.points,
  });

  String get signature {
    return '$augmentId:${tier.name}:${points.map((point) => point.key).join(",")}';
  }
}

bool _hasPassCardWallDisableActive(Battler battler) {
  return false;
}

bool _containsOrderedPattern(
  List<List<String>> patterns,
  List<String> candidate,
) {
  return patterns.any((pattern) {
    if (pattern.length != candidate.length) return false;
    for (var index = 0; index < pattern.length; index++) {
      if (pattern[index] != candidate[index]) return false;
    }
    return true;
  });
}

class BattlePatternMatchResult {
  final int attackBonus;
  final int barrierBonus;
  final int healthBonus;
  final int blockingPointsAvailable;
  final int enemyBlockingPointsRemaining;
  final Set<String> activatedItemPointKeys;
  final List<OperativePatternWallSegment> playerWallSegments;
  final Set<String> playerBlockedPointKeys;
  final BattlePatternBlockMode blockMode;
  final BattlePatternMatchContext patternContext;
  final List<BattlePatternActionPileEntry> actionPile;

  const BattlePatternMatchResult({
    required this.attackBonus,
    required this.barrierBonus,
    this.healthBonus = 0,
    required this.blockingPointsAvailable,
    required this.enemyBlockingPointsRemaining,
    required this.activatedItemPointKeys,
    required this.playerWallSegments,
    required this.playerBlockedPointKeys,
    required this.blockMode,
    required this.patternContext,
    this.actionPile = const <BattlePatternActionPileEntry>[],
  });

  factory BattlePatternMatchResult.fromResolution(
    OperativePatternResolution resolution,
    BattlePatternBlockMode blockMode,
    BattlePatternMatchContext patternContext,
    Map<String, Item> equippedItemsByPointKey,
    Map<String, OperativePatternBonus> bonusesByPointKey,
    int blockingPointsAvailable,
    int enemyBlockingPointsRemaining,
    List<OperativePatternWallSegment> playerWallSegments,
    Set<String> playerBlockedPointKeys,
  ) {
    final activatedItemPointKeys = <String>{
      for (final entry in resolution.itemActivationByPointKey.entries)
        if (entry.value) entry.key,
      ...resolution.activatedAdjacencyBonusesByPointKey.keys,
    };

    return BattlePatternMatchResult(
      attackBonus: resolution.attackBonus,
      barrierBonus: resolution.barrierBonus,
      healthBonus: resolution.healthBonus,
      blockingPointsAvailable: blockingPointsAvailable,
      enemyBlockingPointsRemaining: enemyBlockingPointsRemaining,
      activatedItemPointKeys: Set<String>.unmodifiable(
        activatedItemPointKeys,
      ),
      playerWallSegments: List<OperativePatternWallSegment>.unmodifiable(
        playerWallSegments,
      ),
      playerBlockedPointKeys: Set<String>.unmodifiable(
        playerBlockedPointKeys,
      ),
      blockMode: blockMode,
      patternContext: patternContext,
      actionPile: BattlePatternMatchPresenter.buildActionPile(
        patternPoints: patternContext.patternPoints,
        equippedItemsByPointKey: equippedItemsByPointKey,
        bonusesByPointKey: bonusesByPointKey,
        resolution: resolution,
      ),
    );
  }

  bool get hasBonus => attackBonus > 0 || barrierBonus > 0 || healthBonus > 0;
}

class EnemyBattlePatternMatchResult {
  final int attackBonus;
  final int barrierBonus;
  final int healthBonus;
  final int blockingPointsRemaining;
  final List<OperativePatternWallSegment> wallSegments;
  final Set<String> blockedPointKeys;
  final Set<String> activatedItemPointKeys;
  final BattlePatternMatchContext patternContext;
  final List<BattlePatternActionPileEntry> actionPile;

  const EnemyBattlePatternMatchResult({
    required this.attackBonus,
    required this.barrierBonus,
    this.healthBonus = 0,
    required this.blockingPointsRemaining,
    required this.wallSegments,
    required this.blockedPointKeys,
    required this.activatedItemPointKeys,
    required this.patternContext,
    this.actionPile = const <BattlePatternActionPileEntry>[],
  });

  factory EnemyBattlePatternMatchResult.fromResolution(
    OperativePatternResolution resolution,
    BattlePatternMatchContext patternContext,
    Map<String, Item> equippedItemsByPointKey,
    Map<String, OperativePatternBonus> bonusesByPointKey,
    int blockingPointsRemaining,
    List<OperativePatternWallSegment> wallSegments,
    Set<String> blockedPointKeys,
  ) {
    final activatedItemPointKeys = <String>{
      for (final entry in resolution.itemActivationByPointKey.entries)
        if (entry.value) entry.key,
      ...resolution.activatedAdjacencyBonusesByPointKey.keys,
    };

    return EnemyBattlePatternMatchResult(
      attackBonus: resolution.attackBonus,
      barrierBonus: resolution.barrierBonus,
      healthBonus: resolution.healthBonus,
      blockingPointsRemaining: blockingPointsRemaining,
      wallSegments: List<OperativePatternWallSegment>.unmodifiable(
        wallSegments,
      ),
      blockedPointKeys: Set<String>.unmodifiable(blockedPointKeys),
      activatedItemPointKeys: Set<String>.unmodifiable(
        activatedItemPointKeys,
      ),
      patternContext: patternContext,
      actionPile: BattlePatternMatchPresenter.buildActionPile(
        patternPoints: patternContext.patternPoints,
        equippedItemsByPointKey: equippedItemsByPointKey,
        bonusesByPointKey: bonusesByPointKey,
        resolution: resolution,
      ),
    );
  }
}

class BattlePatternMatchOverlay extends StatefulWidget {
  final Battler player;
  final Battler enemy;
  final Map<String, Item> equippedItemsByPointKey;
  final List<OperativePatternWallSegment> wallSegments;
  final Set<String> blockedPointKeys;
  final BattlePatternEnemyBlockAction? pendingEnemyBlockAction;
  final int enemyTier;
  final int combatRound;
  final int availableBlockingPoints;
  final int enemyBlockingPoints;
  final bool enemyBanksBlockingPoints;
  final List<PlayerActionEffectIntent> actionEffects;
  final Map<String, int> itemPointUseCounts;
  final BattlePatternBlockMode? previousYellowBlockMode;
  final List<List<String>> bannedPatternPointKeys;
  final int Function(int max)? randomNextInt;
  final Future<void> Function(BattlePatternMatchResult result)? onResolve;
  final ValueListenable<Widget?>? combatAnimationOverlay;
  final ValueListenable<BattlePatternVisualBattlers>? visualBattlers;
  final ValueChanged<BattlePatternAnimationTargets?>? onAnimationTargetsChanged;
  final Future<void> Function(Item item)? onPlayerItemPressed;
  final Future<void> Function(Item item)? onEnemyItemPressed;
  final ValueChanged<Augment>? onPlayerAugmentPressed;
  final ValueChanged<Augment>? onEnemyAugmentPressed;

  const BattlePatternMatchOverlay({
    super.key,
    required this.player,
    required this.enemy,
    required this.equippedItemsByPointKey,
    this.wallSegments = const <OperativePatternWallSegment>[],
    this.blockedPointKeys = const <String>{},
    this.pendingEnemyBlockAction,
    this.enemyTier = 1,
    this.combatRound = 1,
    required this.availableBlockingPoints,
    required this.enemyBlockingPoints,
    this.enemyBanksBlockingPoints = false,
    this.actionEffects = const <PlayerActionEffectIntent>[],
    this.itemPointUseCounts = const <String, int>{},
    this.previousYellowBlockMode,
    this.bannedPatternPointKeys = const <List<String>>[],
    this.randomNextInt,
    this.onResolve,
    this.combatAnimationOverlay,
    this.visualBattlers,
    this.onAnimationTargetsChanged,
    this.onPlayerItemPressed,
    this.onEnemyItemPressed,
    this.onPlayerAugmentPressed,
    this.onEnemyAugmentPressed,
  });

  @override
  State<BattlePatternMatchOverlay> createState() =>
      _BattlePatternMatchOverlayState();
}

class _BattlePatternMatchOverlayState extends State<BattlePatternMatchOverlay> {
  final GlobalKey _matchStackKey = GlobalKey();
  final GlobalKey _enemySpriteKey = GlobalKey();
  final GlobalKey _enemyStatusKey = GlobalKey();
  final GlobalKey _playerSpriteKey = GlobalKey();
  final GlobalKey _playerStatusKey = GlobalKey();
  late final Map<String, OperativePatternBonus> _bonusesByPointKey;
  late final int _maxPatternPoints;
  late final int _availableBlockingPointsAtTurnStart;
  late final int _initialWallCount;
  late final int _initialBlockedPointCount;
  late final BattlePatternBlockPlan _blockPlan;
  late List<OperativePatternWallSegment> _wallSegments;
  late Set<String> _blockedPointKeys;
  List<OperativePatternPoint> _patternPoints = const <OperativePatternPoint>[];
  bool _blockAnimationCompleted = false;
  bool _hasSwappedToPlayerCorners = false;
  bool _hasSubmitted = false;

  @override
  void initState() {
    super.initState();
    final randomNextInt = widget.randomNextInt ?? Random().nextInt;
    _blockPlan = BattlePatternBlockPlanService.resolve(
      enemyTier: widget.enemyTier,
      combatRound: widget.combatRound,
      maxBlockingPoints: 0,
      equippedItemsByPointKey: widget.equippedItemsByPointKey,
      itemPointUseCounts: widget.itemPointUseCounts,
      previousYellowBlockMode: widget.previousYellowBlockMode,
      nextInt: randomNextInt,
    );
    _bonusesByPointKey = buildOperativePatternBonusesByPointKey(
      playerLevel: widget.player.level,
      occupiedPointKeys: widget.equippedItemsByPointKey.keys,
      adaptableOccupiedPointKeys: _adaptationEligiblePointKeys(),
      maxAdaptableBonusAmount: _adaptationBonusCap(),
      allowedKinds: _availableActionBonusKinds(widget.player),
      nextInt: randomNextInt,
    );
    _maxPatternPoints = OperativePatternCombatRules.maxPatternPointsFor(
      widget.player,
    );
    _availableBlockingPointsAtTurnStart =
        max(0, widget.availableBlockingPoints);
    _wallSegments = const <OperativePatternWallSegment>[];
    _blockedPointKeys = const <String>{};
    _initialWallCount = _wallSegments.length;
    _initialBlockedPointCount = _blockedPointKeys.length;
    _blockAnimationCompleted = true;
    _hasSwappedToPlayerCorners = true;
  }

  @override
  void dispose() {
    widget.onAnimationTargetsChanged?.call(null);
    super.dispose();
  }

  OperativePatternResolution get _currentResolution {
    return OperativePatternResolutionService.resolve(
      patternPoints: _patternPoints,
      equippedItemsByPointKey: widget.equippedItemsByPointKey,
      bonusesByPointKey: _bonusesByPointKey,
      adaptationMaxEmptyItemBonus: _adaptationBonusCap(),
      shouldDilutePositiveBonuses: widget.player.hasBonusDilution,
      blockedPointKeys: _blockedPointKeys,
    );
  }

  int _adaptationBonusCap() {
    return 0;
  }

  Iterable<String> _adaptationEligiblePointKeys() {
    if (_adaptationBonusCap() <= 0) return const <String>[];

    return widget.equippedItemsByPointKey.entries
        .where((entry) => _isAdaptationEligibleItem(entry.value))
        .map((entry) => entry.key);
  }

  bool _isAdaptationEligibleItem(Item item) {
    return item.patternEffects.isEmpty;
  }

  BattlePatternMatchResult get _currentResult =>
      BattlePatternMatchResult.fromResolution(
        _currentResolution,
        _blockPlan.mode,
        _currentPatternContext(_currentResolution),
        widget.equippedItemsByPointKey,
        _bonusesByPointKey,
        _availableBlockingPoints,
        _enemyBlockingPointsRemaining,
        _wallSegments,
        _blockedPointKeys,
      );

  int get _enemyBlockingPointsRemaining {
    final spentBlockingPoints =
        (max(0, _wallSegments.length - _initialWallCount) *
                OperativePatternCombatRules.wallBlockingPointCost) +
            (max(0, _blockedPointKeys.length - _initialBlockedPointCount) *
                OperativePatternCombatRules.pointBlockingPointCost);
    return max(0, widget.enemyBlockingPoints - spentBlockingPoints);
  }

  int get _availableBlockingPoints {
    return max(0, _availableBlockingPointsAtTurnStart);
  }

  int get _displayedBlockingPoints {
    return _availableBlockingPoints;
  }

  int get _effectiveMaxPatternPoints {
    return _maxPatternPoints;
  }

  BattlePatternMatchContext _currentPatternContext(
    OperativePatternResolution resolution,
  ) {
    return BattlePatternMatchPresenter.buildContext(
      patternPoints: _patternPoints,
      equippedItemsByPointKey: widget.equippedItemsByPointKey,
      resolution: resolution,
      otherArchetypeItemCount: _otherArchetypeActivatedItemCount(resolution),
    );
  }

  int _otherArchetypeActivatedItemCount(OperativePatternResolution resolution) {
    final playerArchetype = widget.player.archetypeId;
    if (playerArchetype == null) return 0;

    var count = 0;
    for (final entry in resolution.itemActivationByPointKey.entries) {
      if (!entry.value) continue;
      final item = widget.equippedItemsByPointKey[entry.key];
      if (item == null) continue;
      if (_itemIsFromAnotherArchetype(item, playerArchetype)) {
        count++;
      }
    }
    return count;
  }

  bool _itemIsFromAnotherArchetype(Item item, ArchetypeId playerArchetype) {
    final playerAffinity = playerArchetype.itemAffinity;
    return item.affinity.isSpecific && item.affinity != playerAffinity;
  }

  void _handlePatternChanged(List<OperativePatternPoint> points) {
    setState(() {
      _patternPoints = points;
    });
  }

  void _handlePointLongPressed(OperativePatternPoint point) {
    final item = widget.equippedItemsByPointKey[point.key];
    if (item == null) return;
    final handleItemPressed = widget.onPlayerItemPressed;
    if (handleItemPressed == null) return;
    unawaited(handleItemPressed(item));
  }

  Future<void> _submit() async {
    if (_hasSubmitted || !_blockAnimationCompleted) return;
    if (!OperativePatternRequirement.isClosedPattern(_patternPoints)) return;
    if (_isCurrentPatternBanned) return;
    _hasSubmitted = true;
    final result = _currentResult;
    await widget.onResolve?.call(result);
    if (!mounted) return;
    Navigator.of(context).pop(result);
  }

  bool get _isCurrentPatternBanned => _containsOrderedPattern(
        widget.bannedPatternPointKeys,
        _patternPoints.map((point) => point.key).toList(growable: false),
      );

  List<_AugmentPatternHint> _augmentPatternHintsFor(Battler player) {
    final hints = <_AugmentPatternHint>[];
    final maxPatternPoints = OperativePatternCombatRules.maxPatternPointsFor(
      player,
    );

    for (final augment in player.augments) {
      final bestHintByPattern = <String, _AugmentPatternHint>{};
      var tierIndex = 0;
      for (final entry in augment.effects.patternEffects.entries) {
        if (tierIndex > augment.rarity.index) break;
        if (entry.key.length > maxPatternPoints) {
          tierIndex++;
          continue;
        }

        final patternSignature = entry.key.map((point) => point.key).join(',');
        bestHintByPattern[patternSignature] = _AugmentPatternHint(
          augmentId: augment.id,
          tier: RarityTier.values[tierIndex],
          points: entry.key,
        );
        tierIndex++;
      }
      hints.addAll(bestHintByPattern.values);
    }

    return List<_AugmentPatternHint>.unmodifiable(hints);
  }

  String _augmentPatternHintSignature(List<_AugmentPatternHint> hints) {
    return hints.map((hint) => hint.signature).join('|');
  }

  Map<String, OperativePatternPointContent> _buildContentsByPointKey(
    OperativePatternResolution resolution,
  ) {
    return BattlePatternMatchPresenter.buildContentsByPointKey(
      equippedItemsByPointKey: widget.equippedItemsByPointKey,
      bonusesByPointKey: _bonusesByPointKey,
      resolution: resolution,
      isFallbackBonusEligible: _isAdaptationEligibleItem,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolution = _currentResolution;
    final augmentPatternHints = _augmentPatternHintsFor(widget.player);
    final result = BattlePatternMatchResult.fromResolution(
      resolution,
      _blockPlan.mode,
      _currentPatternContext(resolution),
      widget.equippedItemsByPointKey,
      _bonusesByPointKey,
      _availableBlockingPoints,
      _enemyBlockingPointsRemaining,
      _wallSegments,
      _blockedPointKeys,
    );
    final blockedPointKeys = _blockedPointKeys;
    final isBoardDimmed = !_blockAnimationCompleted;
    final disabledWallSegmentKeys = _hasPassCardWallDisableActive(
      widget.player,
    )
        ? _wallSegments.map((wall) => wall.key).toSet()
        : const <String>{};
    final isPlayerCornerFront = _hasSwappedToPlayerCorners;
    final enemyMaxPatternPoints =
        OperativePatternCombatRules.maxPatternPointsFor(
      widget.enemy,
    );
    final enemyBlockingPoints = _enemyBlockingPointsRemaining;
    final enemyMaxBlockingPoints = max(widget.enemyBlockingPoints, 0);

    return _BattlePatternCombatPage(
      stackKey: _matchStackKey,
      turnAccent: EndpointPalette.patternAccent,
      top: _PatternVisualBattlerHeader(
        visualBattlers: widget.visualBattlers,
        fallbackBattler: widget.enemy,
        side: BattleCombatantSide.enemy,
        accent: EndpointPalette.dangerAccent,
        spriteKey: _enemySpriteKey,
        statusKey: _enemyStatusKey,
        spriteOnLeft: true,
      ),
      topAugments: _PatternAugmentStrip(
        augments: widget.enemy.augments,
        accent: EndpointPalette.dangerAccent,
        alignEnd: true,
        items: widget.enemy.equippedItems,
        onItemPressed: widget.onEnemyItemPressed,
        onAugmentPressed: widget.onEnemyAugmentPressed,
      ),
      matrix: _PatternMatrixCard(
        accent: EndpointPalette.patternAccent,
        entryAccent: EndpointPalette.dangerAccent,
        summary: _BattleActionPilePreview(
          entries: result.actionPile,
          accent: EndpointPalette.patternAccent,
        ),
        cornerSwapKey: isPlayerCornerFront ? 'player-front' : 'enemy-front',
        animateCornerSwap: isPlayerCornerFront,
        pointCount: isPlayerCornerFront ? resolution.distinctPointCount : 0,
        maxPointCount: isPlayerCornerFront
            ? _effectiveMaxPatternPoints
            : enemyMaxPatternPoints,
        blockingCount: isPlayerCornerFront
            ? _displayedBlockingPoints
            : enemyBlockingPoints,
        maxBlockingCount: isPlayerCornerFront
            ? max(
                _availableBlockingPointsAtTurnStart,
                _displayedBlockingPoints,
              )
            : enemyMaxBlockingPoints,
        rearPointCount: isPlayerCornerFront ? 0 : resolution.distinctPointCount,
        rearMaxPointCount: isPlayerCornerFront
            ? enemyMaxPatternPoints
            : _effectiveMaxPatternPoints,
        rearBlockingCount: isPlayerCornerFront
            ? enemyBlockingPoints
            : _displayedBlockingPoints,
        rearMaxBlockingCount: isPlayerCornerFront
            ? enemyMaxBlockingPoints
            : max(
                _availableBlockingPointsAtTurnStart,
                _displayedBlockingPoints,
              ),
        round: widget.combatRound,
        purgeDoctrine: widget.player.purgeDoctrine,
        finishEnabled: _blockAnimationCompleted &&
            OperativePatternRequirement.isClosedPattern(_patternPoints) &&
            !_isCurrentPatternBanned,
        finishTooltip: _isCurrentPatternBanned
            ? 'No puedes repetir el Patron usado en tu turno anterior.'
            : 'Terminar turno y resolver el Patron.',
        onFinish: _submit,
        dimPatternPoints: false,
        dimBlockPoints: false,
        dimFinishButton: isBoardDimmed || _isCurrentPatternBanned,
        isPatternCornerActive: !isBoardDimmed,
        isBlockCornerActive: false,
        isRearPatternCornerActive: false,
        isRearBlockCornerActive: false,
        showBlockingCorners: false,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: FractionallySizedBox(
                  widthFactor: 0.79,
                  heightFactor: 0.79,
                  child: IgnorePointer(
                    ignoring: !_blockAnimationCompleted,
                    child: _PatternDimmedRegion(
                      isDimmed: isBoardDimmed,
                      child: Transform.rotate(
                        angle: pi / 4,
                        child: OperativePatternBoard(
                          contentsByPointKey: _buildContentsByPointKey(
                            resolution,
                          ),
                          underlay: _AugmentPatternHintUnderlay(
                            hints: augmentPatternHints,
                            hintSignature: _augmentPatternHintSignature(
                              augmentPatternHints,
                            ),
                          ),
                          blockedPointKeys: blockedPointKeys,
                          reinforcedPointKey:
                              widget.player.reinforcedPatternPointKey,
                          keepLineAfterPointerUp: true,
                          maxPatternPoints: _effectiveMaxPatternPoints,
                          wallSegments: _wallSegments,
                          disabledWallSegmentKeys: disabledWallSegmentKeys,
                          previewWallSegment: null,
                          previewBlockedPointKey: null,
                          wallAccent: EndpointPalette.dangerAccent,
                          accent: EndpointPalette.patternAccent,
                          longPressDuration:
                              operativePatternQuickInspectHoldDuration,
                          onPointLongPressed: _handlePointLongPressed,
                          onPatternChanged: _handlePatternChanged,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomAugments: _PatternAugmentStrip(
        augments: widget.player.augments,
        accent: EndpointPalette.patternAccent,
        items: widget.player.equippedItems,
        onItemPressed: widget.onPlayerItemPressed,
        onAugmentPressed: widget.onPlayerAugmentPressed,
      ),
      bottom: _PatternVisualBattlerHeader(
        visualBattlers: widget.visualBattlers,
        fallbackBattler: widget.player,
        side: BattleCombatantSide.player,
        accent: EndpointPalette.patternAccent,
        spriteKey: _playerSpriteKey,
        statusKey: _playerStatusKey,
        spriteOnLeft: false,
      ),
      overlay: null,
      combatAnimationOverlay: widget.combatAnimationOverlay,
      onAnimationTargetsChanged: widget.onAnimationTargetsChanged,
      enemySpriteKey: _enemySpriteKey,
      enemyStatusKey: _enemyStatusKey,
      playerSpriteKey: _playerSpriteKey,
      playerStatusKey: _playerStatusKey,
    );
  }
}

class EnemyBattlePatternMatchOverlay extends StatefulWidget {
  final Battler player;
  final Battler enemy;
  final Map<String, Item> equippedItemsByPointKey;
  final List<OperativePatternWallSegment> wallSegments;
  final Set<String> blockedPointKeys;
  final int maxBlockingPoints;
  final int maxWallActions;
  final bool enemyOverchargesPattern;
  final int combatRound;
  final int Function(int max)? randomNextInt;
  final List<List<String>> bannedPatternPointKeys;
  final Future<void> Function(EnemyBattlePatternMatchResult result)? onResolve;
  final ValueListenable<Widget?>? combatAnimationOverlay;
  final ValueListenable<BattlePatternVisualBattlers>? visualBattlers;
  final ValueChanged<BattlePatternAnimationTargets?>? onAnimationTargetsChanged;
  final Future<void> Function(Item item)? onPlayerItemPressed;
  final Future<void> Function(Item item)? onEnemyItemPressed;
  final ValueChanged<Augment>? onPlayerAugmentPressed;
  final ValueChanged<Augment>? onEnemyAugmentPressed;

  const EnemyBattlePatternMatchOverlay({
    super.key,
    required this.player,
    required this.enemy,
    required this.equippedItemsByPointKey,
    this.wallSegments = const <OperativePatternWallSegment>[],
    this.blockedPointKeys = const <String>{},
    required this.maxBlockingPoints,
    this.maxWallActions = 1,
    required this.enemyOverchargesPattern,
    this.combatRound = 1,
    this.randomNextInt,
    this.bannedPatternPointKeys = const <List<String>>[],
    this.onResolve,
    this.combatAnimationOverlay,
    this.visualBattlers,
    this.onAnimationTargetsChanged,
    this.onPlayerItemPressed,
    this.onEnemyItemPressed,
    this.onPlayerAugmentPressed,
    this.onEnemyAugmentPressed,
  });

  @override
  State<EnemyBattlePatternMatchOverlay> createState() =>
      _EnemyBattlePatternMatchOverlayState();
}

class _EnemyBattlePatternMatchOverlayState
    extends State<EnemyBattlePatternMatchOverlay>
    with TickerProviderStateMixin {
  final GlobalKey _matchStackKey = GlobalKey();
  final GlobalKey _enemyPatternBoardKey = GlobalKey();
  final GlobalKey _enemySpriteKey = GlobalKey();
  final GlobalKey _enemyStatusKey = GlobalKey();
  final GlobalKey _playerSpriteKey = GlobalKey();
  final GlobalKey _playerStatusKey = GlobalKey();
  late final Map<String, OperativePatternBonus> _bonusesByPointKey;
  late final int _maxPatternPoints;
  late final int Function(int max) _nextInt;
  late final int _initialWallCount;
  late final int _initialBlockedPointCount;
  late List<OperativePatternWallSegment> _wallSegments;
  List<OperativePatternWallSegment>? _wallSegmentsBeforeAction;
  late Set<String> _blockedPointKeys;
  Set<String>? _blockedPointKeysBeforeAction;
  OperativePatternWallSegment? _previewWallSegment;
  OperativePatternPoint? _previewBlockedPoint;
  String? _draggedWallKey;
  String? _draggedBlockedPointKey;
  _BattlePatternBlockPlacementMode _blockPlacementMode =
      _BattlePatternBlockPlacementMode.point;
  List<OperativePatternPoint> _displayedEnemyPatternPoints =
      const <OperativePatternPoint>[];
  final bool _isAnimatingBlock = false;
  int _wallActionsUsed = 0;
  bool _isSwappingCorners = false;
  bool _isPlayingEnemyPattern = false;
  bool _hasSwappedToEnemyCorners = false;
  bool _hasSubmitted = false;

  @override
  void initState() {
    super.initState();
    _nextInt = widget.randomNextInt ?? Random().nextInt;
    _bonusesByPointKey = buildOperativePatternBonusesByPointKey(
      playerLevel: widget.enemy.level,
      occupiedPointKeys: widget.equippedItemsByPointKey.keys,
      allowedKinds: _availableActionBonusKinds(widget.enemy),
      nextInt: _nextInt,
    );
    _maxPatternPoints = OperativePatternCombatRules.maxPatternPointsFor(
      widget.enemy,
    );
    _wallSegments = const <OperativePatternWallSegment>[];
    _blockedPointKeys = const <String>{};
    _initialWallCount = _wallSegments.length;
    _initialBlockedPointCount = _blockedPointKeys.length;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_playEnemyPattern());
    });
  }

  @override
  void dispose() {
    widget.onAnimationTargetsChanged?.call(null);
    super.dispose();
  }

  OperativePatternResolution get _currentResolution {
    return OperativePatternResolutionService.resolve(
      patternPoints: _displayedEnemyPatternPoints,
      equippedItemsByPointKey: widget.equippedItemsByPointKey,
      bonusesByPointKey: _bonusesByPointKey,
      blockedPointKeys: _blockedPointKeys,
    );
  }

  EnemyBattlePatternMatchResult get _currentResult =>
      EnemyBattlePatternMatchResult.fromResolution(
        _currentResolution,
        _currentPatternContext(_currentResolution),
        widget.equippedItemsByPointKey,
        _bonusesByPointKey,
        _blockingPointsRemaining,
        _wallSegments,
        _blockedPointKeys,
      );

  int get _blockingPointsRemaining {
    final spentBlockingPoints =
        (max(0, _wallSegments.length - _initialWallCount) *
                OperativePatternCombatRules.wallBlockingPointCost) +
            (max(0, _blockedPointKeys.length - _initialBlockedPointCount) *
                OperativePatternCombatRules.pointBlockingPointCost);
    return max(0, widget.maxBlockingPoints - spentBlockingPoints);
  }

  bool get _canUseWallAction {
    return !_isAnimatingBlock &&
        !_isSwappingCorners &&
        !_isPlayingEnemyPattern &&
        _wallActionsUsed < max(1, widget.maxWallActions) &&
        _blockingPointsRemaining > 0;
  }

  bool get _canPlaceWall {
    return _canUseWallAction &&
        _blockingPointsRemaining >=
            OperativePatternCombatRules.wallBlockingPointCost;
  }

  bool get _canPlacePointBlock {
    return _canUseWallAction &&
        _blockingPointsRemaining >=
            OperativePatternCombatRules.pointBlockingPointCost;
  }

  bool get _canPlaceSelectedBlockMode {
    return switch (_blockPlacementMode) {
      _BattlePatternBlockPlacementMode.wall => _canPlaceWall,
      _BattlePatternBlockPlacementMode.point => _canPlacePointBlock,
    };
  }

  bool get _canMoveWall {
    return !_isAnimatingBlock &&
        !_isSwappingCorners &&
        !_isPlayingEnemyPattern &&
        _blockingPointsRemaining <= 0 &&
        _wallSegments.isNotEmpty;
  }

  bool get _canMovePointBlock {
    return !_isAnimatingBlock &&
        !_isSwappingCorners &&
        !_isPlayingEnemyPattern &&
        _blockingPointsRemaining <= 0 &&
        _blockedPointKeys.isNotEmpty;
  }

  bool get _canMovePlacedBlock => _canMoveWall || _canMovePointBlock;

  BattlePatternMatchContext _currentPatternContext(
    OperativePatternResolution resolution,
  ) {
    return BattlePatternMatchPresenter.buildContext(
      patternPoints: _displayedEnemyPatternPoints,
      equippedItemsByPointKey: widget.equippedItemsByPointKey,
      resolution: resolution,
    );
  }

  Map<String, OperativePatternPointContent> _buildContentsByPointKey(
    OperativePatternResolution resolution,
  ) {
    return BattlePatternMatchPresenter.buildContentsByPointKey(
      equippedItemsByPointKey: widget.equippedItemsByPointKey,
      bonusesByPointKey: _bonusesByPointKey,
      resolution: resolution,
    );
  }

  void _handlePointLongPressed(OperativePatternPoint point) {
    final item = widget.equippedItemsByPointKey[point.key];
    if (item == null) return;
    final handleItemPressed = widget.onEnemyItemPressed;
    if (handleItemPressed == null) return;
    unawaited(handleItemPressed(item));
  }

  void _toggleBlockPlacementMode() {
    if (_isSwappingCorners || _isPlayingEnemyPattern) return;

    setState(() {
      _previewWallSegment = null;
      _previewBlockedPoint = null;
      _blockPlacementMode =
          _blockPlacementMode == _BattlePatternBlockPlacementMode.wall
              ? _BattlePatternBlockPlacementMode.point
              : _BattlePatternBlockPlacementMode.wall;
    });
  }

  void _handleWallDragStart(DragStartDetails details) {
    if (!_canPlaceSelectedBlockMode) return;
    _draggedWallKey = null;
    _draggedBlockedPointKey = null;
    _updateBlockPreview(details.globalPosition);
  }

  void _handleWallDragUpdate(DragUpdateDetails details) {
    if (!_canPlaceSelectedBlockMode) return;
    _updateBlockPreview(details.globalPosition);
  }

  void _handleWallDragEnd(DragEndDetails details) {
    final previewWall = _previewWallSegment;
    final previewPoint = _previewBlockedPoint;
    if (previewWall == null && previewPoint == null) {
      setState(() {
        _previewWallSegment = null;
        _previewBlockedPoint = null;
      });
      return;
    }

    if (previewWall != null && _canPlaceWall) {
      final wallKeys = _wallSegments.map((wall) => wall.key).toSet();
      final nextWalls = List<OperativePatternWallSegment>.from(_wallSegments);
      if (!wallKeys.contains(previewWall.key)) {
        nextWalls.add(previewWall);
      }
      setState(() {
        _wallSegmentsBeforeAction = _wallSegments;
        _blockedPointKeysBeforeAction = _blockedPointKeys;
        _wallSegments = List<OperativePatternWallSegment>.unmodifiable(
          nextWalls,
        );
        _previewWallSegment = null;
        _previewBlockedPoint = null;
        _wallActionsUsed++;
      });
      return;
    }

    if (previewPoint != null && _canPlacePointBlock) {
      final nextBlockedPointKeys = Set<String>.from(_blockedPointKeys)
        ..add(previewPoint.key);
      setState(() {
        _wallSegmentsBeforeAction = _wallSegments;
        _blockedPointKeysBeforeAction = _blockedPointKeys;
        _blockedPointKeys = Set<String>.unmodifiable(nextBlockedPointKeys);
        _previewWallSegment = null;
        _previewBlockedPoint = null;
        _wallActionsUsed++;
      });
      return;
    }

    setState(() {
      _previewWallSegment = null;
      _previewBlockedPoint = null;
    });
  }

  void _handlePlacedWallDragStart(DragStartDetails details) {
    if (!_canMovePlacedBlock) return;

    final point = _nearestExistingBlockedPoint(details.globalPosition);
    final wall = _nearestExistingWall(details.globalPosition);
    if (point == null && wall == null) return;

    if (point != null) {
      _draggedWallKey = null;
      _draggedBlockedPointKey = point.key;
      _updatePreviewPointBlock(
        details.globalPosition,
        ignoredBlockedPointKey: point.key,
      );
      return;
    }

    _draggedBlockedPointKey = null;
    _draggedWallKey = wall!.key;
    _updatePreviewWall(details.globalPosition);
  }

  void _handlePlacedWallDragUpdate(DragUpdateDetails details) {
    if (!_canMovePlacedBlock) return;

    final draggedBlockedPointKey = _draggedBlockedPointKey;
    if (draggedBlockedPointKey != null) {
      _updatePreviewPointBlock(
        details.globalPosition,
        ignoredBlockedPointKey: draggedBlockedPointKey,
      );
      return;
    }

    if (_draggedWallKey == null) return;
    _updatePreviewWall(details.globalPosition);
  }

  void _handlePlacedWallDragEnd(DragEndDetails details) {
    final draggedWallKey = _draggedWallKey;
    final draggedBlockedPointKey = _draggedBlockedPointKey;
    final preview = _previewWallSegment;
    final previewPoint = _previewBlockedPoint;
    if (!_canMovePlacedBlock ||
        (draggedWallKey == null && draggedBlockedPointKey == null)) {
      setState(() {
        _draggedWallKey = null;
        _draggedBlockedPointKey = null;
        _previewWallSegment = null;
        _previewBlockedPoint = null;
      });
      return;
    }

    if (draggedBlockedPointKey != null) {
      if (previewPoint == null ||
          previewPoint.key == draggedBlockedPointKey ||
          (_blockedPointKeys.contains(previewPoint.key) &&
              previewPoint.key != draggedBlockedPointKey)) {
        setState(() {
          _draggedWallKey = null;
          _draggedBlockedPointKey = null;
          _previewWallSegment = null;
          _previewBlockedPoint = null;
        });
        return;
      }

      final nextBlockedPointKeys = Set<String>.from(_blockedPointKeys)
        ..remove(draggedBlockedPointKey)
        ..add(previewPoint.key);
      setState(() {
        _wallSegmentsBeforeAction = _wallSegments;
        _blockedPointKeysBeforeAction = _blockedPointKeys;
        _blockedPointKeys = Set<String>.unmodifiable(nextBlockedPointKeys);
        _draggedWallKey = null;
        _draggedBlockedPointKey = null;
        _previewWallSegment = null;
        _previewBlockedPoint = null;
      });
      return;
    }

    if (!_canMoveWall || draggedWallKey == null || preview == null) {
      setState(() {
        _draggedWallKey = null;
        _draggedBlockedPointKey = null;
        _previewWallSegment = null;
        _previewBlockedPoint = null;
      });
      return;
    }

    final nextWalls = List<OperativePatternWallSegment>.from(_wallSegments);
    final movedIndex =
        nextWalls.indexWhere((wall) => wall.key == draggedWallKey);
    final duplicateIndex =
        nextWalls.indexWhere((wall) => wall.key == preview.key);
    if (preview.key == draggedWallKey ||
        movedIndex < 0 ||
        (duplicateIndex >= 0 && duplicateIndex != movedIndex)) {
      setState(() {
        _draggedWallKey = null;
        _draggedBlockedPointKey = null;
        _previewWallSegment = null;
        _previewBlockedPoint = null;
      });
      return;
    }

    nextWalls[movedIndex] = preview;
    setState(() {
      _wallSegmentsBeforeAction = _wallSegments;
      _blockedPointKeysBeforeAction = _blockedPointKeys;
      _wallSegments = List<OperativePatternWallSegment>.unmodifiable(
        nextWalls,
      );
      _draggedWallKey = null;
      _draggedBlockedPointKey = null;
      _previewWallSegment = null;
      _previewBlockedPoint = null;
    });
  }

  void _handleRedoWallAction() {
    final previousWalls = _wallSegmentsBeforeAction;
    final previousBlockedPointKeys = _blockedPointKeysBeforeAction;
    if (previousWalls == null || previousBlockedPointKeys == null) return;

    setState(() {
      _wallSegments = previousWalls;
      _blockedPointKeys = previousBlockedPointKeys;
      _wallSegmentsBeforeAction = null;
      _blockedPointKeysBeforeAction = null;
      _previewWallSegment = null;
      _previewBlockedPoint = null;
      _draggedWallKey = null;
      _draggedBlockedPointKey = null;
      _wallActionsUsed = 0;
    });
  }

  OperativePatternWallSegment? _nearestExistingWall(Offset globalPosition) {
    final boardRenderObject =
        _enemyPatternBoardKey.currentContext?.findRenderObject();
    if (boardRenderObject is! RenderBox ||
        !boardRenderObject.hasSize ||
        boardRenderObject.size.width <= 0 ||
        boardRenderObject.size.height <= 0) {
      return null;
    }

    final localPosition = boardRenderObject.globalToLocal(globalPosition);
    final nearest = operativePatternNearestWallSegmentFor(
      boardSize: boardRenderObject.size,
      localPosition: localPosition,
    );
    if (nearest == null) return null;

    final nearestKey = nearest.key;
    for (final wall in _wallSegments) {
      if (wall.key == nearestKey) return wall;
    }
    return null;
  }

  OperativePatternPoint? _nearestExistingBlockedPoint(Offset globalPosition) {
    final boardRenderObject =
        _enemyPatternBoardKey.currentContext?.findRenderObject();
    if (boardRenderObject is! RenderBox ||
        !boardRenderObject.hasSize ||
        boardRenderObject.size.width <= 0 ||
        boardRenderObject.size.height <= 0) {
      return null;
    }

    final localPosition = boardRenderObject.globalToLocal(globalPosition);
    final nearest = operativePatternNearestPointFor(
      boardSize: boardRenderObject.size,
      localPosition: localPosition,
      maxDistanceFactor: 0.26,
    );
    if (nearest == null || !_blockedPointKeys.contains(nearest.key)) {
      return null;
    }
    return nearest;
  }

  void _updateBlockPreview(Offset globalPosition) {
    final boardRenderObject =
        _enemyPatternBoardKey.currentContext?.findRenderObject();
    if (boardRenderObject is! RenderBox ||
        !boardRenderObject.hasSize ||
        boardRenderObject.size.width <= 0 ||
        boardRenderObject.size.height <= 0) {
      return;
    }

    final localPosition = boardRenderObject.globalToLocal(globalPosition);
    if (_blockPlacementMode == _BattlePatternBlockPlacementMode.wall) {
      final previewWall = _canPlaceWall
          ? operativePatternNearestWallSegmentFor(
              boardSize: boardRenderObject.size,
              localPosition: localPosition,
            )
          : null;
      if (previewWall == _previewWallSegment && _previewBlockedPoint == null) {
        return;
      }

      setState(() {
        _previewWallSegment = previewWall;
        _previewBlockedPoint = null;
      });
      return;
    }

    final previewPoint = _canPlacePointBlock
        ? operativePatternNearestPointFor(
            boardSize: boardRenderObject.size,
            localPosition: localPosition,
            maxDistanceFactor: 0.26,
          )
        : null;
    if (previewPoint != null && !_blockedPointKeys.contains(previewPoint.key)) {
      if (_previewBlockedPoint == previewPoint && _previewWallSegment == null) {
        return;
      }
      setState(() {
        _previewBlockedPoint = previewPoint;
        _previewWallSegment = null;
      });
      return;
    }

    setState(() {
      _previewWallSegment = null;
      _previewBlockedPoint = null;
    });
  }

  void _updatePreviewPointBlock(
    Offset globalPosition, {
    required String ignoredBlockedPointKey,
  }) {
    final boardRenderObject =
        _enemyPatternBoardKey.currentContext?.findRenderObject();
    if (boardRenderObject is! RenderBox ||
        !boardRenderObject.hasSize ||
        boardRenderObject.size.width <= 0 ||
        boardRenderObject.size.height <= 0) {
      return;
    }

    final localPosition = boardRenderObject.globalToLocal(globalPosition);
    final previewPoint = operativePatternNearestPointFor(
      boardSize: boardRenderObject.size,
      localPosition: localPosition,
      maxDistanceFactor: 0.26,
    );
    final isAvailable = previewPoint != null &&
        (!_blockedPointKeys.contains(previewPoint.key) ||
            previewPoint.key == ignoredBlockedPointKey);
    final nextPreviewPoint = isAvailable ? previewPoint : null;
    if (_previewBlockedPoint == nextPreviewPoint &&
        _previewWallSegment == null) {
      return;
    }

    setState(() {
      _previewBlockedPoint = nextPreviewPoint;
      _previewWallSegment = null;
    });
  }

  void _updatePreviewWall(Offset globalPosition) {
    final boardRenderObject =
        _enemyPatternBoardKey.currentContext?.findRenderObject();
    if (boardRenderObject is! RenderBox ||
        !boardRenderObject.hasSize ||
        boardRenderObject.size.width <= 0 ||
        boardRenderObject.size.height <= 0) {
      return;
    }

    final localPosition = boardRenderObject.globalToLocal(globalPosition);
    final preview = operativePatternNearestWallSegmentFor(
      boardSize: boardRenderObject.size,
      localPosition: localPosition,
    );
    if (preview == _previewWallSegment) return;

    setState(() {
      _previewWallSegment = preview;
      _previewBlockedPoint = null;
    });
  }

  Future<void> _playEnemyPattern() async {
    if (_isSwappingCorners || _isPlayingEnemyPattern || _hasSubmitted) return;

    final pattern = _buildClosedEnemyPatternOrPass();
    setState(() {
      _isSwappingCorners = true;
      _hasSwappedToEnemyCorners = true;
      _displayedEnemyPatternPoints = const <OperativePatternPoint>[];
    });
    await Future<void>.delayed(const Duration(milliseconds: 430));
    if (!mounted || _hasSubmitted) return;
    setState(() {
      _isSwappingCorners = false;
      _isPlayingEnemyPattern = true;
    });

    for (var i = 0; i < pattern.length; i++) {
      if (!mounted) return;
      await Future<void>.delayed(_enemyPatternPointStepDuration);
      if (!mounted) return;
      setState(() {
        _displayedEnemyPatternPoints = List<OperativePatternPoint>.unmodifiable(
          pattern.take(i + 1),
        );
      });
    }

    if (!mounted || _hasSubmitted) return;
    _hasSubmitted = true;
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;
    final result = _currentResult;
    await widget.onResolve?.call(result);
    if (!mounted) return;
    Navigator.of(context).pop(result);
  }

  List<OperativePatternPoint> _buildClosedEnemyPatternOrPass() {
    return BattlePatternEnemyPlanner.buildClosedPatternOrPass(
      maxPatternPoints: _enemyEffectiveMaxPatternPoints,
      blockedPointKeys: _blockedPointKeys,
      equippedItemsByPointKey: widget.equippedItemsByPointKey,
      bonusesByPointKey: _bonusesByPointKey,
      activeWalls: _activeWallSegmentsForEnemyPattern,
      bannedPatternPointKeys: widget.bannedPatternPointKeys,
    );
  }

  List<OperativePatternWallSegment> get _activeWallSegmentsForEnemyPattern {
    if (!_hasPassCardWallDisableActive(widget.enemy)) return _wallSegments;

    return const <OperativePatternWallSegment>[];
  }

  int get _enemyEffectiveMaxPatternPoints {
    return _maxPatternPoints + (widget.enemyOverchargesPattern ? 1 : 0);
  }

  @override
  Widget build(BuildContext context) {
    final resolution = _currentResolution;
    final enemyBlockingPoints =
        OperativePatternCombatRules.maxBlockingPointsFor(
      widget.enemy,
    );
    final enemyDisplayedBlockingPoints = max(
      0,
      enemyBlockingPoints - (widget.enemyOverchargesPattern ? 1 : 0),
    );
    final waitingForBlocks =
        _canPlaceWall || _canPlacePointBlock || _canMovePlacedBlock;
    final disabledWallSegmentKeys = _hasPassCardWallDisableActive(
      widget.enemy,
    )
        ? _wallSegments.map((wall) => wall.key).toSet()
        : const <String>{};
    final isEnemyCornerFront = _hasSwappedToEnemyCorners;
    final playerMaxPatternPoints =
        OperativePatternCombatRules.maxPatternPointsFor(
      widget.player,
    );
    final playerBlockingPoints = _blockingPointsRemaining;
    final animatedWallSegmentKeys = _canMoveWall
        ? _wallSegments.map((wall) => wall.key).toSet()
        : const <String>{};
    final isEnemyMatrixInputLocked =
        _isSwappingCorners || _isPlayingEnemyPattern;
    final displayedBlockedPointKeys = _draggedBlockedPointKey == null
        ? _blockedPointKeys
        : Set<String>.unmodifiable(
            Set<String>.from(_blockedPointKeys)
              ..remove(_draggedBlockedPointKey),
          );

    return _BattlePatternCombatPage(
      stackKey: _matchStackKey,
      turnAccent: EndpointPalette.dangerAccent,
      top: _PatternVisualBattlerHeader(
        visualBattlers: widget.visualBattlers,
        fallbackBattler: widget.enemy,
        side: BattleCombatantSide.enemy,
        accent: EndpointPalette.dangerAccent,
        spriteKey: _enemySpriteKey,
        statusKey: _enemyStatusKey,
        spriteOnLeft: true,
      ),
      topAugments: _PatternAugmentStrip(
        augments: widget.enemy.augments,
        accent: EndpointPalette.dangerAccent,
        alignEnd: true,
        items: widget.enemy.equippedItems,
        onItemPressed: widget.onEnemyItemPressed,
        onAugmentPressed: widget.onEnemyAugmentPressed,
      ),
      matrix: _PatternMatrixCard(
        accent: EndpointPalette.dangerAccent,
        entryAccent: EndpointPalette.patternAccent,
        summary: null,
        cornerSwapKey: isEnemyCornerFront ? 'enemy-front' : 'player-front',
        animateCornerSwap: isEnemyCornerFront,
        pointCount: isEnemyCornerFront ? resolution.distinctPointCount : 0,
        maxPointCount: isEnemyCornerFront
            ? _enemyEffectiveMaxPatternPoints
            : playerMaxPatternPoints,
        blockingCount: isEnemyCornerFront
            ? enemyDisplayedBlockingPoints
            : playerBlockingPoints,
        maxBlockingCount:
            isEnemyCornerFront ? enemyBlockingPoints : widget.maxBlockingPoints,
        rearPointCount: isEnemyCornerFront ? 0 : resolution.distinctPointCount,
        rearMaxPointCount: isEnemyCornerFront
            ? playerMaxPatternPoints
            : _enemyEffectiveMaxPatternPoints,
        rearBlockingCount: isEnemyCornerFront
            ? playerBlockingPoints
            : enemyDisplayedBlockingPoints,
        rearMaxBlockingCount:
            isEnemyCornerFront ? widget.maxBlockingPoints : enemyBlockingPoints,
        round: widget.combatRound,
        purgeDoctrine: widget.player.purgeDoctrine,
        finishEnabled: !_isAnimatingBlock &&
            !_isSwappingCorners &&
            !_isPlayingEnemyPattern,
        onFinish: _playEnemyPattern,
        dimPatternPoints: false,
        dimBlockPoints: false,
        dimFinishButton:
            _isAnimatingBlock || _isSwappingCorners || _isPlayingEnemyPattern,
        isPatternCornerActive: false,
        isBlockCornerActive: !isEnemyCornerFront && waitingForBlocks,
        isRearPatternCornerActive: false,
        isRearBlockCornerActive: false,
        showBlockingCorners: false,
        blockCornerWallAccent: EndpointPalette.patternAccent,
        blockPlacementMode: _blockPlacementMode,
        blockCornerWallEnabled: _canPlaceWall,
        blockCornerPointEnabled: _canPlacePointBlock,
        animateBlockCornerWall: _canPlaceSelectedBlockMode,
        showRedoButton: _wallSegmentsBeforeAction != null &&
            !_isSwappingCorners &&
            !_isPlayingEnemyPattern,
        onRedo: _handleRedoWallAction,
        onBlockModeToggle: _toggleBlockPlacementMode,
        onBlockDragStart:
            _canPlaceSelectedBlockMode ? _handleWallDragStart : null,
        onBlockDragUpdate:
            _canPlaceSelectedBlockMode ? _handleWallDragUpdate : null,
        onBlockDragEnd: _canPlaceSelectedBlockMode ? _handleWallDragEnd : null,
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart:
                  _canMovePlacedBlock ? _handlePlacedWallDragStart : null,
              onPanUpdate:
                  _canMovePlacedBlock ? _handlePlacedWallDragUpdate : null,
              onPanEnd: _canMovePlacedBlock ? _handlePlacedWallDragEnd : null,
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: FractionallySizedBox(
                    widthFactor: 0.79,
                    heightFactor: 0.79,
                    child: AbsorbPointer(
                      absorbing:
                          isEnemyMatrixInputLocked || _canMovePlacedBlock,
                      child: Transform.rotate(
                        angle: pi / 4,
                        child: OperativePatternBoard(
                          key: _enemyPatternBoardKey,
                          contentsByPointKey:
                              _buildContentsByPointKey(resolution),
                          blockedPointKeys: displayedBlockedPointKeys,
                          reinforcedPointKey:
                              widget.enemy.reinforcedPatternPointKey,
                          displayedPatternPoints: _displayedEnemyPatternPoints,
                          keepLineAfterPointerUp: true,
                          isPatternInputEnabled:
                              !isEnemyMatrixInputLocked && !_canMovePlacedBlock,
                          maxPatternPoints: _enemyEffectiveMaxPatternPoints,
                          wallSegments: _wallSegments,
                          disabledWallSegmentKeys: disabledWallSegmentKeys,
                          previewWallSegment: _previewWallSegment,
                          previewBlockedPointKey: _previewBlockedPoint?.key,
                          animatedWallSegmentKeys: animatedWallSegmentKeys,
                          wallAccent: EndpointPalette.patternAccent,
                          accent: EndpointPalette.dangerAccent,
                          longPressDuration:
                              operativePatternQuickInspectHoldDuration,
                          onPointLongPressed: isEnemyMatrixInputLocked
                              ? null
                              : _handlePointLongPressed,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomAugments: _PatternAugmentStrip(
        augments: widget.player.augments,
        accent: EndpointPalette.patternAccent,
        items: widget.player.equippedItems,
        onItemPressed: widget.onPlayerItemPressed,
        onAugmentPressed: widget.onPlayerAugmentPressed,
      ),
      bottom: _PatternVisualBattlerHeader(
        visualBattlers: widget.visualBattlers,
        fallbackBattler: widget.player,
        side: BattleCombatantSide.player,
        accent: EndpointPalette.patternAccent,
        spriteKey: _playerSpriteKey,
        statusKey: _playerStatusKey,
        spriteOnLeft: false,
      ),
      overlay: null,
      combatAnimationOverlay: widget.combatAnimationOverlay,
      onAnimationTargetsChanged: widget.onAnimationTargetsChanged,
      enemySpriteKey: _enemySpriteKey,
      enemyStatusKey: _enemyStatusKey,
      playerSpriteKey: _playerSpriteKey,
      playerStatusKey: _playerStatusKey,
    );
  }
}

class BattlePatternActionPileOverlay extends StatefulWidget {
  final Battler player;
  final Battler enemy;
  final List<BattlePatternActionPileEntry> playerActionPile;
  final List<BattlePatternActionPileEntry> enemyActionPile;
  final Future<void> Function(
    BattlePatternActionPileStepCallback onStep,
    BattlePatternActionPileUpdateCallback onPileUpdate,
  ) onResolve;
  final int combatRound;
  final ValueListenable<Widget?>? combatAnimationOverlay;
  final ValueListenable<BattlePatternVisualBattlers>? visualBattlers;
  final ValueChanged<BattlePatternAnimationTargets?>? onAnimationTargetsChanged;
  final Future<void> Function(Item item)? onPlayerItemPressed;
  final Future<void> Function(Item item)? onEnemyItemPressed;
  final ValueChanged<Augment>? onPlayerAugmentPressed;
  final ValueChanged<Augment>? onEnemyAugmentPressed;

  const BattlePatternActionPileOverlay({
    super.key,
    required this.player,
    required this.enemy,
    required this.playerActionPile,
    required this.enemyActionPile,
    required this.onResolve,
    required this.combatRound,
    this.combatAnimationOverlay,
    this.visualBattlers,
    this.onAnimationTargetsChanged,
    this.onPlayerItemPressed,
    this.onEnemyItemPressed,
    this.onPlayerAugmentPressed,
    this.onEnemyAugmentPressed,
  });

  @override
  State<BattlePatternActionPileOverlay> createState() =>
      _BattlePatternActionPileOverlayState();
}

class _BattlePatternActionPileOverlayState
    extends State<BattlePatternActionPileOverlay> {
  final GlobalKey _matchStackKey = GlobalKey();
  final GlobalKey _enemySpriteKey = GlobalKey();
  final GlobalKey _enemyStatusKey = GlobalKey();
  final GlobalKey _playerSpriteKey = GlobalKey();
  final GlobalKey _playerStatusKey = GlobalKey();
  late int _playerIndex;
  late int _enemyIndex;
  late List<BattlePatternActionPileEntry> _playerEntries;
  late List<BattlePatternActionPileEntry> _enemyEntries;
  Set<BattlePatternActionPileEntry> _playerEnteringEntries =
      <BattlePatternActionPileEntry>{};
  Set<BattlePatternActionPileEntry> _enemyEnteringEntries =
      <BattlePatternActionPileEntry>{};
  bool _playerActs = false;
  bool _enemyActs = false;
  bool _isResolving = false;

  @override
  void initState() {
    super.initState();
    _playerEntries =
        List<BattlePatternActionPileEntry>.of(widget.playerActionPile);
    _enemyEntries = List<BattlePatternActionPileEntry>.of(
      widget.enemyActionPile,
    );
    _playerIndex = widget.playerActionPile.isEmpty ? -1 : 0;
    _enemyIndex = widget.enemyActionPile.isEmpty ? -1 : 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_resolveAfterReveal());
    });
  }

  @override
  void dispose() {
    widget.onAnimationTargetsChanged?.call(null);
    super.dispose();
  }

  Future<void> _resolveAfterReveal() async {
    if (_isResolving) return;
    _isResolving = true;
    await Future<void>.delayed(const Duration(milliseconds: 620));
    if (!mounted) return;
    await widget.onResolve(_handleActionPileStep, _handleActionPileUpdate);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _handleActionPileStep(BattlePatternActionPileStep step) async {
    if (!mounted) return;
    setState(() {
      _playerIndex = step.playerIndex;
      _enemyIndex = step.enemyIndex;
      _playerActs = step.playerActs;
      _enemyActs = step.enemyActs;
    });
    await Future<void>.delayed(const Duration(milliseconds: 420));
  }

  Future<void> _handleActionPileUpdate({
    required bool isPlayer,
    required List<BattlePatternActionPileEntry> entries,
  }) async {
    if (!mounted) return;
    final currentEntries = isPlayer ? _playerEntries : _enemyEntries;
    final enteringEntries = _newActionPileEntries(
      currentEntries: currentEntries,
      nextEntries: entries,
    );
    setState(() {
      if (isPlayer) {
        _playerEntries = List<BattlePatternActionPileEntry>.of(entries);
        _playerEnteringEntries = enteringEntries;
      } else {
        _enemyEntries = List<BattlePatternActionPileEntry>.of(entries);
        _enemyEnteringEntries = enteringEntries;
      }
    });
    await Future<void>.delayed(_battleActionPileEntryFadeDuration);
    if (!mounted) return;
    setState(() {
      if (isPlayer) {
        _playerEnteringEntries = <BattlePatternActionPileEntry>{};
      } else {
        _enemyEnteringEntries = <BattlePatternActionPileEntry>{};
      }
    });
  }

  Set<BattlePatternActionPileEntry> _newActionPileEntries({
    required List<BattlePatternActionPileEntry> currentEntries,
    required List<BattlePatternActionPileEntry> nextEntries,
  }) {
    return <BattlePatternActionPileEntry>{
      for (final nextEntry in nextEntries)
        if (!currentEntries.any((entry) => identical(entry, nextEntry)))
          nextEntry,
    };
  }

  @override
  Widget build(BuildContext context) {
    return _BattlePatternCombatPage(
      stackKey: _matchStackKey,
      turnAccent: EndpointPalette.warningAccent,
      top: _PatternVisualBattlerHeader(
        visualBattlers: widget.visualBattlers,
        fallbackBattler: widget.enemy,
        side: BattleCombatantSide.enemy,
        accent: EndpointPalette.dangerAccent,
        spriteKey: _enemySpriteKey,
        statusKey: _enemyStatusKey,
        spriteOnLeft: true,
      ),
      topAugments: _PatternAugmentStrip(
        augments: widget.enemy.augments,
        accent: EndpointPalette.dangerAccent,
        alignEnd: true,
        items: widget.enemy.equippedItems,
        onItemPressed: widget.onEnemyItemPressed,
        onAugmentPressed: widget.onEnemyAugmentPressed,
      ),
      matrix: _PatternMatrixCard(
        accent: EndpointPalette.warningAccent,
        entryAccent: EndpointPalette.patternAccent,
        summary: null,
        cornerSwapKey: 'action-piles',
        animateCornerSwap: false,
        pointCount: _playerEntries.length,
        maxPointCount: max(_playerEntries.length, 1),
        blockingCount: _enemyEntries.length,
        maxBlockingCount: max(_enemyEntries.length, 1),
        rearPointCount: 0,
        rearMaxPointCount: 1,
        rearBlockingCount: 0,
        rearMaxBlockingCount: 1,
        round: widget.combatRound,
        purgeDoctrine: widget.player.purgeDoctrine,
        finishEnabled: false,
        finishTooltip: 'Resolviendo pilas de accion.',
        showBlockingCorners: false,
        dimPatternPoints: false,
        dimBlockPoints: false,
        dimFinishButton: true,
        isPatternCornerActive: true,
        isBlockCornerActive: true,
        isRearPatternCornerActive: false,
        isRearBlockCornerActive: false,
        showCornerWidgets: false,
        onFinish: () {},
        child: _BattleActionPileBoard(
          enemyEntries: _enemyEntries,
          playerEntries: _playerEntries,
          enemyEnteringEntries: _enemyEnteringEntries,
          playerEnteringEntries: _playerEnteringEntries,
          enemyIndex: _enemyIndex,
          playerIndex: _playerIndex,
          enemyActs: _enemyActs,
          playerActs: _playerActs,
        ),
      ),
      bottomAugments: _PatternAugmentStrip(
        augments: widget.player.augments,
        accent: EndpointPalette.patternAccent,
        items: widget.player.equippedItems,
        onItemPressed: widget.onPlayerItemPressed,
        onAugmentPressed: widget.onPlayerAugmentPressed,
      ),
      bottom: _PatternVisualBattlerHeader(
        visualBattlers: widget.visualBattlers,
        fallbackBattler: widget.player,
        side: BattleCombatantSide.player,
        accent: EndpointPalette.patternAccent,
        spriteKey: _playerSpriteKey,
        statusKey: _playerStatusKey,
        spriteOnLeft: false,
      ),
      overlay: null,
      combatAnimationOverlay: widget.combatAnimationOverlay,
      onAnimationTargetsChanged: widget.onAnimationTargetsChanged,
      enemySpriteKey: _enemySpriteKey,
      enemyStatusKey: _enemyStatusKey,
      playerSpriteKey: _playerSpriteKey,
      playerStatusKey: _playerStatusKey,
    );
  }
}

class _BattleActionPilePreview extends StatefulWidget {
  final List<BattlePatternActionPileEntry> entries;
  final Color accent;

  const _BattleActionPilePreview({
    required this.entries,
    required this.accent,
  });

  @override
  State<_BattleActionPilePreview> createState() =>
      _BattleActionPilePreviewState();
}

class _BattleActionPilePreviewState extends State<_BattleActionPilePreview> {
  final Set<String> _pendingRemovalKeys = <String>{};
  List<_BattleActionPilePreviewItem> _items =
      const <_BattleActionPilePreviewItem>[];
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _syncItems(shouldSetState: false);
  }

  @override
  void didUpdateWidget(covariant _BattleActionPilePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entries.isNotEmpty && widget.entries.isEmpty) {
      _generation++;
    }
    _syncItems();
  }

  @override
  void dispose() {
    _pendingRemovalKeys.clear();
    super.dispose();
  }

  void _syncItems({bool shouldSetState = true}) {
    final nextItems = <_BattleActionPilePreviewItem>[
      for (var index = 0; index < widget.entries.length; index++)
        _BattleActionPilePreviewItem(
          key: _entryKey(widget.entries[index], index),
          entry: widget.entries[index],
        ),
    ];
    final nextByKey = <String, _BattleActionPilePreviewItem>{
      for (final item in nextItems) item.key: item,
    };
    final handledKeys = <String>{};
    final updatedItems = <_BattleActionPilePreviewItem>[];

    for (final item in _items) {
      final nextItem = nextByKey[item.key];
      if (nextItem != null) {
        updatedItems.add(nextItem);
        handledKeys.add(item.key);
        continue;
      }

      final removingItem = item.copyWith(isRemoving: true);
      updatedItems.add(removingItem);
      _scheduleRemoval(removingItem.key);
    }

    for (final item in nextItems) {
      if (handledKeys.contains(item.key)) continue;
      updatedItems.add(item);
    }

    if (shouldSetState) {
      setState(() {
        _items = List<_BattleActionPilePreviewItem>.unmodifiable(updatedItems);
      });
    } else {
      _items = List<_BattleActionPilePreviewItem>.unmodifiable(updatedItems);
    }
  }

  void _scheduleRemoval(String key) {
    if (!_pendingRemovalKeys.add(key)) return;
    Future<void>.delayed(_battleActionPileEntryFadeDuration, () {
      if (!mounted) return;
      _pendingRemovalKeys.remove(key);
      setState(() {
        _items = List<_BattleActionPilePreviewItem>.unmodifiable(
          _items.where((item) => item.key != key || !item.isRemoving),
        );
      });
    });
  }

  String _entryKey(BattlePatternActionPileEntry entry, int index) {
    final item = entry.item;
    final itemKey = item?.instanceId ?? item?.catalogKey ?? 'matrix';
    final effectKey = entry.action?.customEffectKey ??
        entry.action?.description ??
        entry.bonus?.kind.name ??
        'effect';
    return '$_generation:$index:${entry.kind.name}:${entry.pointKey}:'
        '${entry.chainKey}:$itemKey:${entry.actionType.name}:'
        '${entry.value}:$effectKey';
  }

  @override
  Widget build(BuildContext context) {
    final modifiers = _BattleActionPileValueModifiers();
    final displayValuesByKey = <String, int>{};
    for (final item in _items.where((item) => !item.isRemoving)) {
      displayValuesByKey[item.key] = modifiers.displayValueBeforeApplying(
        item.entry,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: EndpointPalette.panelBackgroundOpaque.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.accent.withValues(alpha: 0.62),
        ),
        boxShadow: [
          BoxShadow(
            color: widget.accent.withValues(alpha: 0.14),
            blurRadius: 16,
          ),
        ],
      ),
      child: SizedBox(
        height: 56,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.playlist_add_rounded,
                size: 18,
                color: widget.accent,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: ClipRect(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: _items.isEmpty
                          ? <Widget>[
                              _BattleActionPilePreviewEmpty(
                                accent: widget.accent,
                              ),
                            ]
                          : <Widget>[
                              for (var index = 0;
                                  index < _items.length;
                                  index++) ...[
                                if (index > 0) const SizedBox(width: 7),
                                _BattleActionPilePreviewItemView(
                                  key: ValueKey<String>(_items[index].key),
                                  item: _items[index],
                                  accent: widget.accent,
                                  displayValue:
                                      displayValuesByKey[_items[index].key] ??
                                          _items[index].entry.value,
                                ),
                              ],
                            ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BattleActionPilePreviewItem {
  final String key;
  final BattlePatternActionPileEntry entry;
  final bool isRemoving;

  const _BattleActionPilePreviewItem({
    required this.key,
    required this.entry,
    this.isRemoving = false,
  });

  _BattleActionPilePreviewItem copyWith({
    BattlePatternActionPileEntry? entry,
    bool? isRemoving,
  }) {
    return _BattleActionPilePreviewItem(
      key: key,
      entry: entry ?? this.entry,
      isRemoving: isRemoving ?? this.isRemoving,
    );
  }
}

class _BattleActionPilePreviewItemView extends StatefulWidget {
  final _BattleActionPilePreviewItem item;
  final Color accent;
  final int displayValue;

  const _BattleActionPilePreviewItemView({
    super.key,
    required this.item,
    required this.accent,
    required this.displayValue,
  });

  @override
  State<_BattleActionPilePreviewItemView> createState() =>
      _BattleActionPilePreviewItemViewState();
}

class _BattleActionPilePreviewItemViewState
    extends State<_BattleActionPilePreviewItemView> {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.item.isRemoving) return;
      setState(() {
        _isVisible = true;
      });
    });
  }

  @override
  void didUpdateWidget(covariant _BattleActionPilePreviewItemView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextVisible = !widget.item.isRemoving;
    if (_isVisible == nextVisible) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _isVisible = nextVisible;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: _battleActionPileEntryFadeDuration,
      curve: Curves.easeOutCubic,
      opacity: _isVisible ? 1 : 0,
      child: AnimatedScale(
        duration: _battleActionPileEntryFadeDuration,
        curve: Curves.easeOutBack,
        scale: _isVisible ? 1 : 0.86,
        child: _BattleActionPilePreviewPip(
          entry: widget.item.entry,
          accent: widget.accent,
          displayValue: widget.displayValue,
        ),
      ),
    );
  }
}

class _BattleActionPilePreviewEmpty extends StatelessWidget {
  final Color accent;

  const _BattleActionPilePreviewEmpty({
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _battleActionPilePipDecoration(accent.withAlpha(96)),
      child: SizedBox.square(
        dimension: 34,
        child: Icon(
          Icons.remove_rounded,
          color: accent.withAlpha(160),
          size: 18,
        ),
      ),
    );
  }
}

class _BattleActionPilePreviewPip extends StatelessWidget {
  final BattlePatternActionPileEntry entry;
  final Color accent;
  final int displayValue;

  const _BattleActionPilePreviewPip({
    required this.entry,
    required this.accent,
    required this.displayValue,
  });

  @override
  Widget build(BuildContext context) {
    final actionAccent = endpointItemActionAccent(entry.actionType);
    return Tooltip(
      message: entry.item?.displayName ?? 'Matrix bonus',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DecoratedBox(
            decoration: _battleActionPilePipDecoration(
              entry.kind == BattlePatternActionPileEntryKind.itemAction
                  ? accent
                  : actionAccent,
            ),
            child: SizedBox.square(
              dimension: 34,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: _BattleActionPilePipIcon(entry: entry),
              ),
            ),
          ),
          Positioned(
            right: -7,
            top: -7,
            child: _BattleActionPilePreviewValueBadge(
              displayValue: displayValue,
              actionType: entry.actionType,
              isBonus:
                  entry.kind == BattlePatternActionPileEntryKind.matrixBonus,
            ),
          ),
        ],
      ),
    );
  }
}

class _BattleActionPilePreviewValueBadge extends StatelessWidget {
  final int displayValue;
  final ItemActionType actionType;
  final bool isBonus;

  const _BattleActionPilePreviewValueBadge({
    required this.displayValue,
    required this.actionType,
    required this.isBonus,
  });

  @override
  Widget build(BuildContext context) {
    final accent = endpointItemActionAccent(actionType);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(232),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withAlpha(220), width: 1),
      ),
      child: SizedBox(
        width: 24,
        height: 18,
        child: Center(
          child: EndpointText(
            displayValue > 0 ? '${isBonus ? '+' : ''}$displayValue' : '*',
            style: textSmallNumericBold.copyWith(
              color: accent,
              fontSize: 10,
              letterSpacing: 0,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _BattleActionPileBoard extends StatelessWidget {
  final List<BattlePatternActionPileEntry> enemyEntries;
  final List<BattlePatternActionPileEntry> playerEntries;
  final Set<BattlePatternActionPileEntry> enemyEnteringEntries;
  final Set<BattlePatternActionPileEntry> playerEnteringEntries;
  final int enemyIndex;
  final int playerIndex;
  final bool enemyActs;
  final bool playerActs;

  const _BattleActionPileBoard({
    required this.enemyEntries,
    required this.playerEntries,
    required this.enemyEnteringEntries,
    required this.playerEnteringEntries,
    required this.enemyIndex,
    required this.playerIndex,
    required this.enemyActs,
    required this.playerActs,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            color: EndpointPalette.softForeground.withAlpha(80),
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _BattleActionPileLine(
              entries: enemyEntries,
              accent: EndpointPalette.dangerAccent,
              activeIndex: enemyIndex,
              activeActs: enemyActs,
              direction: -1,
              enteringEntries: enemyEnteringEntries,
            ),
            const SizedBox(height: 30),
            _BattleActionPileLine(
              entries: playerEntries,
              accent: EndpointPalette.patternAccent,
              activeIndex: playerIndex,
              activeActs: playerActs,
              direction: 1,
              enteringEntries: playerEnteringEntries,
            ),
          ],
        ),
      ],
    );
  }
}

class _BattleActionPileLine extends StatelessWidget {
  static const double _pipSize = 52;
  static const double _stepSize = 82;

  final List<BattlePatternActionPileEntry> entries;
  final Color accent;
  final int activeIndex;
  final bool activeActs;
  final int direction;
  final Set<BattlePatternActionPileEntry> enteringEntries;

  const _BattleActionPileLine({
    required this.entries,
    required this.accent,
    required this.activeIndex,
    required this.activeActs,
    required this.direction,
    required this.enteringEntries,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final centerX = constraints.maxWidth / 2;
          if (entries.isEmpty) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: centerX - _pipSize / 2,
                  top: 12,
                  child: _BattleActionPileEmptyPip(accent: accent),
                ),
              ],
            );
          }

          final modifiers = _BattleActionPileValueModifiers();
          return Stack(
            clipBehavior: Clip.none,
            children: [
              for (var index = 0; index < entries.length; index++)
                AnimatedPositioned(
                  key: ObjectKey(entries[index]),
                  duration: const Duration(milliseconds: 380),
                  curve: Curves.easeInOutCubic,
                  left: centerX -
                      _pipSize / 2 +
                      direction * (index - activeIndex) * _stepSize,
                  top: 10,
                  width: _pipSize,
                  height: _pipSize,
                  child: _BattleActionPilePip(
                    entry: entries[index],
                    accent: accent,
                    pulseDelay: index,
                    isCentered: index == activeIndex,
                    isActing: activeActs && index == activeIndex,
                    fadeIn: enteringEntries.contains(entries[index]),
                    displayValue: modifiers.displayValueBeforeApplying(
                      entries[index],
                    ),
                  ),
                ),
              for (var index = 0; index < entries.length - 1; index++)
                AnimatedPositioned(
                  key: ValueKey(
                    'separator:${identityHashCode(entries[index])}:'
                    '${identityHashCode(entries[index + 1])}',
                  ),
                  duration: const Duration(milliseconds: 380),
                  curve: Curves.easeInOutCubic,
                  left: centerX -
                      16 +
                      direction * (index + 0.5 - activeIndex) * _stepSize,
                  top: 29,
                  width: 32,
                  height: 20,
                  child: _BattleActionPileSeparator(
                    isChained:
                        entries[index].chainKey == entries[index + 1].chainKey,
                    direction: direction,
                    accent: accent,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _BattleActionPileSeparator extends StatelessWidget {
  final bool isChained;
  final int direction;
  final Color accent;

  const _BattleActionPileSeparator({
    required this.isChained,
    required this.direction,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    if (isChained) {
      return Center(
        child: Container(
          width: 24,
          height: 2,
          color: accent.withAlpha(190),
        ),
      );
    }

    return Icon(
      direction > 0 ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
      color: accent.withAlpha(176),
      size: 24,
    );
  }
}

class _BattleActionPileEmptyPip extends StatelessWidget {
  final Color accent;

  const _BattleActionPileEmptyPip({
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _battleActionPilePipDecoration(accent.withAlpha(120)),
      child: SizedBox.square(
        dimension: 48,
        child: Icon(
          Icons.remove_rounded,
          color: accent.withAlpha(180),
          size: 22,
        ),
      ),
    );
  }
}

class _BattleActionPilePip extends StatelessWidget {
  final BattlePatternActionPileEntry entry;
  final Color accent;
  final int pulseDelay;
  final bool isCentered;
  final bool isActing;
  final bool fadeIn;
  final int displayValue;

  const _BattleActionPilePip({
    required this.entry,
    required this.accent,
    required this.pulseDelay,
    required this.isCentered,
    required this.isActing,
    required this.fadeIn,
    required this.displayValue,
  });

  @override
  Widget build(BuildContext context) {
    final actionAccent = endpointItemActionAccent(entry.actionType);
    final pip = TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 260 + pulseDelay * 25),
      curve: Curves.easeOutBack,
      builder: (context, progress, child) {
        return Transform.scale(
          scale: 0.84 + progress.clamp(0.0, 1.0) * 0.16,
          child: child,
        );
      },
      child: Tooltip(
        message: entry.item?.displayName ?? 'Matrix bonus',
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            DecoratedBox(
              decoration: _battleActionPilePipDecoration(
                entry.kind == BattlePatternActionPileEntryKind.itemAction
                    ? accent
                    : actionAccent,
                isCentered: isCentered,
                isActing: isActing,
              ),
              child: SizedBox.square(
                dimension: 48,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: _BattleActionPilePipIcon(entry: entry),
                ),
              ),
            ),
            Positioned(
              right: -7,
              top: -7,
              child: _BattleActionPileValueBadge(
                displayValue: displayValue,
                actionType: entry.actionType,
                isBonus:
                    entry.kind == BattlePatternActionPileEntryKind.matrixBonus,
              ),
            ),
          ],
        ),
      ),
    );
    if (!fadeIn) return pip;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: _battleActionPileEntryFadeDuration,
      curve: Curves.easeOutCubic,
      builder: (context, opacity, child) {
        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: child,
        );
      },
      child: pip,
    );
  }
}

BoxDecoration _battleActionPilePipDecoration(
  Color accent, {
  bool isCentered = false,
  bool isActing = false,
}) {
  return BoxDecoration(
    color: EndpointPalette.panelBackgroundBattleOpaque.withAlpha(
      isCentered ? 250 : 218,
    ),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(
      color: accent.withAlpha(isCentered ? 255 : 180),
      width: isCentered ? 2.4 : 1.3,
    ),
    boxShadow: [
      BoxShadow(
        color: accent.withAlpha(isActing ? 150 : 80),
        blurRadius: isCentered ? 18 : 12,
        spreadRadius: isCentered ? 2 : 1,
      ),
      BoxShadow(
        color: Colors.black.withAlpha(150),
        blurRadius: 9,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

class _BattleActionPilePipIcon extends StatelessWidget {
  final BattlePatternActionPileEntry entry;

  const _BattleActionPilePipIcon({
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    final item = entry.item;
    if (item != null) {
      return Image.asset(
        item.asset,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.inventory_2_rounded,
            color: EndpointPalette.softForeground,
            size: 28,
          );
        },
      );
    }

    final asset = switch (entry.actionType) {
      ItemActionType.attack => 'assets/images/icons/icon_sword.png',
      ItemActionType.block => 'assets/sprites/status/escudo.png',
      ItemActionType.heal => 'assets/sprites/status/vida.png',
      ItemActionType.none => null,
    };
    if (asset != null) {
      return Image.asset(
        asset,
        fit: BoxFit.contain,
        color: endpointItemActionAccent(entry.actionType),
        filterQuality: FilterQuality.none,
      );
    }

    return const Icon(
      Icons.auto_awesome_rounded,
      color: EndpointPalette.warningAccent,
      size: 26,
    );
  }
}

class _BattleActionPileValueBadge extends StatelessWidget {
  final int displayValue;
  final ItemActionType actionType;
  final bool isBonus;

  const _BattleActionPileValueBadge({
    required this.displayValue,
    required this.actionType,
    required this.isBonus,
  });

  @override
  Widget build(BuildContext context) {
    final accent = endpointItemActionAccent(actionType);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(232),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withAlpha(220), width: 1),
      ),
      child: SizedBox(
        width: 26,
        height: 22,
        child: Center(
          child: EndpointText(
            displayValue > 0 ? '${isBonus ? '+' : ''}$displayValue' : '*',
            style: textSmallNumericBold.copyWith(
              color: accent,
              fontSize: 12,
              letterSpacing: 0,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _BattleActionPileValueModifiers {
  int attack = 0;
  int barrier = 0;
  int heal = 0;

  int displayValueBeforeApplying(BattlePatternActionPileEntry entry) {
    final value = switch (entry.actionType) {
      ItemActionType.attack => entry.value + attack,
      ItemActionType.block => entry.value + barrier,
      ItemActionType.heal => entry.value + heal,
      ItemActionType.none => entry.value,
    };
    final bonus = entry.bonus;
    if (bonus != null) {
      switch (bonus.kind) {
        case OperativePatternBonusKind.attack:
          attack += bonus.amount;
          break;
        case OperativePatternBonusKind.barrier:
          barrier += bonus.amount;
          break;
        case OperativePatternBonusKind.health:
          heal += bonus.amount;
          break;
      }
    }
    return value;
  }
}

Set<OperativePatternBonusKind> _availableActionBonusKinds(Battler battler) {
  final kinds = <OperativePatternBonusKind>{};
  for (final item in battler.equippedItems) {
    for (final action in item.actionEffects) {
      switch (action.actionType) {
        case ItemActionType.attack:
          kinds.add(OperativePatternBonusKind.attack);
          break;
        case ItemActionType.block:
          kinds.add(OperativePatternBonusKind.barrier);
          break;
        case ItemActionType.heal:
          kinds.add(OperativePatternBonusKind.health);
          break;
        case ItemActionType.none:
          break;
      }
    }
  }
  return kinds;
}

class _BattlePatternCombatPage extends StatelessWidget {
  final GlobalKey stackKey;
  final Color turnAccent;
  final Widget top;
  final Widget topAugments;
  final Widget matrix;
  final Widget bottomAugments;
  final Widget bottom;
  final Widget? overlay;
  final ValueListenable<Widget?>? combatAnimationOverlay;
  final ValueChanged<BattlePatternAnimationTargets?>? onAnimationTargetsChanged;
  final GlobalKey enemySpriteKey;
  final GlobalKey enemyStatusKey;
  final GlobalKey playerSpriteKey;
  final GlobalKey playerStatusKey;

  const _BattlePatternCombatPage({
    required this.stackKey,
    required this.turnAccent,
    required this.top,
    required this.topAugments,
    required this.matrix,
    required this.bottomAugments,
    required this.bottom,
    this.overlay,
    this.combatAnimationOverlay,
    this.onAnimationTargetsChanged,
    required this.enemySpriteKey,
    required this.enemyStatusKey,
    required this.playerSpriteKey,
    required this.playerStatusKey,
  });

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final targets = _resolveAnimationTargets();
      if (targets != null) {
        onAnimationTargetsChanged?.call(targets);
      }
    });

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: EndpointGradients.battle),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Stack(
                key: stackKey,
                fit: StackFit.expand,
                children: [
                  Column(
                    children: [
                      top,
                      const SizedBox(height: 6),
                      topAugments,
                      const SizedBox(height: 8),
                      Expanded(child: matrix),
                      const SizedBox(height: 8),
                      bottomAugments,
                      const SizedBox(height: 6),
                      bottom,
                    ],
                  ),
                  if (overlay != null) overlay!,
                  if (combatAnimationOverlay != null)
                    ValueListenableBuilder<Widget?>(
                      valueListenable: combatAnimationOverlay!,
                      builder: (context, overlay, _) {
                        return overlay ?? const SizedBox.shrink();
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  BattlePatternAnimationTargets? _resolveAnimationTargets() {
    final stackBox = stackKey.currentContext?.findRenderObject();
    if (stackBox is! RenderBox || !stackBox.hasSize) return null;

    Rect? localRectFor(GlobalKey key) {
      final renderObject = key.currentContext?.findRenderObject();
      if (renderObject is! RenderBox ||
          !renderObject.hasSize ||
          renderObject.size.isEmpty) {
        return null;
      }

      final topLeft = stackBox.globalToLocal(
        renderObject.localToGlobal(Offset.zero),
      );
      return topLeft & renderObject.size;
    }

    final enemySpriteRect = localRectFor(enemySpriteKey);
    final enemyStatusRect = localRectFor(enemyStatusKey);
    final playerSpriteRect = localRectFor(playerSpriteKey);
    final playerStatusRect = localRectFor(playerStatusKey);
    if (enemySpriteRect == null ||
        enemyStatusRect == null ||
        playerSpriteRect == null ||
        playerStatusRect == null) {
      return null;
    }

    return BattlePatternAnimationTargets(
      playerSpriteRect: playerSpriteRect,
      enemySpriteRect: enemySpriteRect,
      playerStatusRect: playerStatusRect,
      enemyStatusRect: enemyStatusRect,
    );
  }
}

class _PatternVisualBattlerHeader extends StatelessWidget {
  final ValueListenable<BattlePatternVisualBattlers>? visualBattlers;
  final Battler fallbackBattler;
  final BattleCombatantSide side;
  final Color accent;
  final bool spriteOnLeft;
  final Key? spriteKey;
  final Key? statusKey;

  const _PatternVisualBattlerHeader({
    required this.visualBattlers,
    required this.fallbackBattler,
    required this.side,
    required this.accent,
    required this.spriteOnLeft,
    this.spriteKey,
    this.statusKey,
  });

  @override
  Widget build(BuildContext context) {
    final listenable = visualBattlers;
    if (listenable == null) {
      return _PatternBattlerHeader(
        battler: fallbackBattler,
        accent: accent,
        spriteOnLeft: spriteOnLeft,
        spriteKey: spriteKey,
        statusKey: statusKey,
      );
    }

    return ValueListenableBuilder<BattlePatternVisualBattlers>(
      valueListenable: listenable,
      builder: (context, visualBattlers, _) {
        final battler = switch (side) {
          BattleCombatantSide.player => visualBattlers.player,
          BattleCombatantSide.enemy => visualBattlers.enemy,
        };
        return _PatternBattlerHeader(
          battler: battler,
          accent: accent,
          spriteOnLeft: spriteOnLeft,
          spriteKey: spriteKey,
          statusKey: statusKey,
        );
      },
    );
  }
}

class _PatternBattlerHeader extends StatelessWidget {
  final Battler battler;
  final Color accent;
  final bool spriteOnLeft;
  final Key? spriteKey;
  final Key? statusKey;

  const _PatternBattlerHeader({
    required this.battler,
    required this.accent,
    required this.spriteOnLeft,
    this.spriteKey,
    this.statusKey,
  });

  @override
  Widget build(BuildContext context) {
    final sprite = _PatternSprite(
      key: spriteKey,
      battler: battler,
      accent: accent,
      mirror: !spriteOnLeft,
    );
    final status = Expanded(
      child: _PatternStatusBars(
        key: statusKey,
        battler: battler,
        accent: accent,
        alignEnd: !spriteOnLeft,
      ),
    );
    final rowChildren = spriteOnLeft
        ? <Widget>[sprite, const SizedBox(width: 8), status]
        : <Widget>[status, const SizedBox(width: 8), sprite];

    return SizedBox(
      height: 78,
      child: Row(children: rowChildren),
    );
  }
}

class _PatternSprite extends StatelessWidget {
  final Battler battler;
  final Color accent;
  final bool mirror;

  const _PatternSprite({
    super.key,
    required this.battler,
    required this.accent,
    required this.mirror,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 62,
      height: 62,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: EndpointPalette.panelBackgroundBattleOpaque,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accent.withAlpha(150)),
        ),
        child: Center(
          child: EndpointEmojiSprite(
            emoji: battler.iconEmoji,
            imageAsset: battler.imageAsset,
            accent: accent,
            size: 52,
            mirror: mirror,
          ),
        ),
      ),
    );
  }
}

class _PatternStatusBars extends StatelessWidget {
  final Battler battler;
  final Color accent;
  final bool alignEnd;

  const _PatternStatusBars({
    super.key,
    required this.battler,
    required this.accent,
    required this.alignEnd,
  });

  @override
  Widget build(BuildContext context) {
    final healthMax = max(1, battler.maxHealth);
    final health = battler.maxHealth <= 0
        ? 0.0
        : (battler.health / healthMax).clamp(0.0, 1.0).toDouble();
    final barrierMax = max(1, max(battler.maxBarrier, battler.currentBarrier));
    final barrier =
        (battler.currentBarrier / barrierMax).clamp(0.0, 1.0).toDouble();

    final hasStatuses = battler.statuses.isNotEmpty;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          top: hasStatuses ? 12 : 0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: EndpointPalette.panelBackgroundBattleOpaque,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accent.withAlpha(132)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Column(
                crossAxisAlignment: alignEnd
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  EndpointText(
                    battler.name.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: alignEnd ? TextAlign.right : TextAlign.left,
                    style: textSmallBold.copyWith(
                      color: EndpointPalette.softForeground,
                      fontSize: 11,
                      letterSpacing: 0.9,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _PatternMeterRow(
                    value: health,
                    color: EndpointPalette.healthAccent,
                    label: '${max(0, battler.health)}/$healthMax',
                  ),
                  const SizedBox(height: 4),
                  _PatternMeterRow(
                    value: barrier,
                    color: BattlerStat.barrier.accent,
                    label: '${max(0, battler.currentBarrier)}',
                  ),
                ],
              ),
            ),
          ),
        ),
        if (hasStatuses)
          Positioned(
            top: 0,
            left: alignEnd ? null : 8,
            right: alignEnd ? 8 : null,
            child: EndpointStatusBadges(
              battler: battler,
              alignment: alignEnd ? WrapAlignment.end : WrapAlignment.start,
              badgeSize: 22,
              spacing: 4,
            ),
          ),
      ],
    );
  }
}

class _PatternMeterRow extends StatelessWidget {
  final double value;
  final Color color;
  final String label;

  const _PatternMeterRow({
    required this.value,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 42,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: EndpointText(
              label,
              key: ValueKey<String>(label),
              maxLines: 1,
              overflow: TextOverflow.clip,
              textAlign: TextAlign.right,
              style: textSmallNumericBold.copyWith(
                color: EndpointPalette.softForeground,
                fontSize: 10,
                height: 1,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _PatternMeter(
            value: value,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _PatternMeter extends StatelessWidget {
  final double value;
  final Color color;

  const _PatternMeter({
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 6,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(
            begin: value,
            end: value,
          ),
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          builder: (context, animatedValue, _) {
            return Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: Colors.black.withAlpha(150)),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: animatedValue.clamp(0.0, 1.0).toDouble(),
                  child: ColoredBox(color: color),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AugmentPatternHintUnderlay extends StatefulWidget {
  final List<_AugmentPatternHint> hints;
  final String hintSignature;

  const _AugmentPatternHintUnderlay({
    required this.hints,
    required this.hintSignature,
  });

  @override
  State<_AugmentPatternHintUnderlay> createState() =>
      _AugmentPatternHintUnderlayState();
}

class _AugmentPatternHintUnderlayState
    extends State<_AugmentPatternHintUnderlay>
    with SingleTickerProviderStateMixin {
  static final _cycleDuration = Duration(
    milliseconds: _augmentPatternHintDrawDuration.inMilliseconds +
        _augmentPatternHintHoldDuration.inMilliseconds +
        _augmentPatternHintFadeDuration.inMilliseconds +
        _augmentPatternHintGapDuration.inMilliseconds,
  );

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _cycleDuration,
  );
  Timer? _startTimer;
  int _hintIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener(_handleAnimationStatus);
    _scheduleInitialStart();
  }

  @override
  void didUpdateWidget(covariant _AugmentPatternHintUnderlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hintSignature == widget.hintSignature) return;

    _hintIndex = 0;
    _controller.stop();
    _controller.value = 0;
    _scheduleInitialStart();
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _controller
      ..removeStatusListener(_handleAnimationStatus)
      ..dispose();
    super.dispose();
  }

  void _scheduleInitialStart() {
    _startTimer?.cancel();
    if (widget.hints.isEmpty) return;
    _startTimer = Timer(_augmentPatternHintInitialDelay, () {
      if (!mounted || widget.hints.isEmpty) return;
      _controller.forward(from: 0);
    });
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || widget.hints.isEmpty) return;
    setState(() {
      _hintIndex = (_hintIndex + 1) % widget.hints.length;
    });
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.hints.isEmpty) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final activeHint = widget.hints[_hintIndex % widget.hints.length];
        final phase = _AugmentPatternHintPhase.fromValue(_controller.value);
        if (phase.opacity <= 0) return const SizedBox.expand();

        return CustomPaint(
          painter: _AugmentPatternHintPainter(
            points: activeHint.points,
            accent: activeHint.tier.accent,
            drawProgress: phase.drawProgress,
            opacity: phase.opacity,
          ),
        );
      },
    );
  }
}

class _AugmentPatternHintPhase {
  final double drawProgress;
  final double opacity;

  const _AugmentPatternHintPhase({
    required this.drawProgress,
    required this.opacity,
  });

  static _AugmentPatternHintPhase fromValue(double value) {
    final total = _AugmentPatternHintUnderlayState._cycleDuration.inMilliseconds
        .toDouble();
    final drawEnd = _augmentPatternHintDrawDuration.inMilliseconds / total;
    final holdEnd =
        (_augmentPatternHintDrawDuration + _augmentPatternHintHoldDuration)
                .inMilliseconds /
            total;
    final fadeEnd = (_augmentPatternHintDrawDuration +
                _augmentPatternHintHoldDuration +
                _augmentPatternHintFadeDuration)
            .inMilliseconds /
        total;
    const maxOpacity = 0.46;

    if (value <= drawEnd) {
      final progress = Curves.easeInOutCubic.transform(
        (value / drawEnd).clamp(0.0, 1.0).toDouble(),
      );
      return _AugmentPatternHintPhase(
        drawProgress: progress,
        opacity: maxOpacity * progress,
      );
    }
    if (value <= holdEnd) {
      return const _AugmentPatternHintPhase(
        drawProgress: 1,
        opacity: maxOpacity,
      );
    }
    if (value <= fadeEnd) {
      final fadeProgress =
          ((value - holdEnd) / (fadeEnd - holdEnd)).clamp(0.0, 1.0).toDouble();
      return _AugmentPatternHintPhase(
        drawProgress: 1,
        opacity: maxOpacity * (1 - Curves.easeOutCubic.transform(fadeProgress)),
      );
    }

    return const _AugmentPatternHintPhase(
      drawProgress: 1,
      opacity: 0,
    );
  }
}

class _AugmentPatternHintPainter extends CustomPainter {
  final List<OperativePatternPoint> points;
  final Color accent;
  final double drawProgress;
  final double opacity;

  const _AugmentPatternHintPainter({
    required this.points,
    required this.accent,
    required this.drawProgress,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty || opacity <= 0) return;

    final centers = points.map((point) => _centerFor(point, size)).toList();
    final partialPath = _partialPath(centers, drawProgress);
    final visiblePointCount = max(
      1,
      min(points.length, (points.length * drawProgress).ceil()),
    );
    final visiblePoints = points.take(visiblePointCount).toList();

    _drawPath(canvas, partialPath);
    _drawPointHighlights(canvas, visiblePoints, size);
  }

  Path _partialPath(List<Offset> centers, double progress) {
    final path = Path();
    if (centers.isEmpty) return path;

    path.moveTo(centers.first.dx, centers.first.dy);
    if (centers.length == 1 || progress <= 0) return path;

    final segmentCount = centers.length - 1;
    final scaledProgress = progress.clamp(0.0, 1.0) * segmentCount;
    final fullSegments = scaledProgress.floor().clamp(0, segmentCount);
    final partialSegmentProgress = scaledProgress - fullSegments;

    for (var index = 1; index <= fullSegments; index++) {
      path.lineTo(centers[index].dx, centers[index].dy);
    }

    if (fullSegments < segmentCount && partialSegmentProgress > 0) {
      final start = centers[fullSegments];
      final end = centers[fullSegments + 1];
      final partial = Offset.lerp(start, end, partialSegmentProgress)!;
      path.lineTo(partial.dx, partial.dy);
    }

    return path;
  }

  void _drawPath(Canvas canvas, Path path) {
    final wideGlowPaint = Paint()
      ..color = accent.withValues(alpha: opacity * 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final softGlowPaint = Paint()
      ..color = accent.withValues(alpha: opacity * 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final corePaint = Paint()
      ..color = EndpointPalette.softForeground.withValues(alpha: opacity * 0.76)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, wideGlowPaint);
    canvas.drawPath(path, softGlowPaint);
    canvas.drawPath(path, corePaint);
  }

  void _drawPointHighlights(
    Canvas canvas,
    List<OperativePatternPoint> visiblePoints,
    Size size,
  ) {
    for (final point in visiblePoints) {
      final center = _centerFor(point, size);
      canvas.drawCircle(
        center,
        13,
        Paint()
          ..color = accent.withValues(alpha: opacity * 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawCircle(
        center,
        5.4,
        Paint()
          ..color = accent.withValues(alpha: opacity * 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  Offset _centerFor(OperativePatternPoint point, Size size) {
    final side = min(size.width * 0.94, size.height * 0.94);
    final topLeft = Offset(
      (size.width - side) / 2,
      (size.height - side) / 2,
    );
    return topLeft +
        operativePatternPointCenter(
          point: point,
          boardSide: side,
        );
  }

  @override
  bool shouldRepaint(covariant _AugmentPatternHintPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.accent != accent ||
        oldDelegate.drawProgress != drawProgress ||
        oldDelegate.opacity != opacity;
  }
}

class _PatternAugmentStrip extends StatelessWidget {
  final List<Augment> augments;
  final Color accent;
  final bool alignEnd;
  final List<Item> items;
  final Future<void> Function(Item item)? onItemPressed;
  final ValueChanged<Augment>? onAugmentPressed;

  const _PatternAugmentStrip({
    this.augments = const <Augment>[],
    required this.accent,
    this.alignEnd = false,
    this.items = const <Item>[],
    this.onItemPressed,
    this.onAugmentPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final augmentRow = SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: alignEnd,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment:
                  alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
              textDirection: alignEnd ? TextDirection.rtl : TextDirection.ltr,
              children: [
                for (var index = 0; index < augments.length; index++) ...[
                  if (index > 0) const SizedBox(width: 8),
                  _PatternAugmentDot(
                    augment: augments[index],
                    accent: accent,
                    onPressed: onAugmentPressed,
                  ),
                ],
              ],
            ),
          );
          final itemButton = _PatternItemsButton(
            items: items,
            accent: accent,
            alignEnd: alignEnd,
            onItemPressed: onItemPressed,
          );

          return Row(
            children: alignEnd
                ? <Widget>[
                    itemButton,
                    const SizedBox(width: 8),
                    Expanded(child: augmentRow),
                  ]
                : <Widget>[
                    Expanded(child: augmentRow),
                    const SizedBox(width: 8),
                    itemButton,
                  ],
          );
        },
      ),
    );
  }
}

class _PatternItemsButton extends StatelessWidget {
  final List<Item> items;
  final Color accent;
  final bool alignEnd;
  final Future<void> Function(Item item)? onItemPressed;

  const _PatternItemsButton({
    required this.items,
    required this.accent,
    required this.alignEnd,
    this.onItemPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Objetos equipados',
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: items.isEmpty ? null : () => _openItemsList(context),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: EndpointPalette.panelBackgroundBattleOpaque,
              border: Border.all(color: accent.withAlpha(150), width: 2),
            ),
            child: SizedBox(
              width: 38,
              height: 38,
              child: Icon(
                Icons.inventory_2_rounded,
                color: items.isEmpty
                    ? EndpointPalette.softForeground.withAlpha(90)
                    : accent,
                size: 19,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openItemsList(BuildContext context) async {
    await showEndpointDialog<void>(
      context: context,
      barrierLabel: 'Objetos equipados',
      barrierColor: EndpointPalette.overlayScrim,
      builder: (dialogContext) {
        return _PatternItemsDialog(
          items: items,
          accent: accent,
          alignEnd: alignEnd,
          onItemPressed: onItemPressed,
        );
      },
    );
  }
}

class _PatternItemsDialog extends StatelessWidget {
  final List<Item> items;
  final Color accent;
  final bool alignEnd;
  final Future<void> Function(Item item)? onItemPressed;

  const _PatternItemsDialog({
    required this.items,
    required this.accent,
    required this.alignEnd,
    this.onItemPressed,
  });

  @override
  Widget build(BuildContext context) {
    final sortedItems = List<Item>.from(items)
      ..sort((a, b) => a.name.compareTo(b.name));

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420, maxHeight: 560),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: EndpointPalette.panelBackgroundBattleOpaque,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accent.withAlpha(170), width: 1.4),
          boxShadow: [
            BoxShadow(
              color: accent.withAlpha(38),
              blurRadius: 24,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              EndpointText(
                'Objetos equipados',
                textAlign: alignEnd ? TextAlign.right : TextAlign.left,
                style: textSmallBold.copyWith(
                  color: accent,
                  fontSize: 16,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: sortedItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = sortedItems[index];
                    return _PatternItemListTile(
                      item: item,
                      accent: accent,
                      onPressed: onItemPressed == null
                          ? null
                          : () async {
                              Navigator.of(context).pop();
                              await onItemPressed!(item);
                            },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PatternItemListTile extends StatelessWidget {
  final Item item;
  final Color accent;
  final Future<void> Function()? onPressed;

  const _PatternItemListTile({
    required this.item,
    required this.accent,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: EndpointPalette.panelBackgroundOpaque.withAlpha(190),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: item.rarity.accent.withAlpha(120)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: item.rarity.accent.withAlpha(36),
                    border:
                        Border.all(color: item.rarity.accent.withAlpha(150)),
                  ),
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: Center(
                      child: Image.asset(
                        item.asset,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EndpointText(
                        item.name,
                        overflow: TextOverflow.ellipsis,
                        style: textSmallBold.copyWith(
                          color: EndpointPalette.softForeground,
                          fontSize: 13,
                          letterSpacing: 0,
                        ),
                      ),
                      EndpointText(
                        item.rarity.label,
                        overflow: TextOverflow.ellipsis,
                        style: textSmall.copyWith(
                          color: item.rarity.accent,
                          fontSize: 10,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: accent.withAlpha(190),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PatternAugmentDot extends StatelessWidget {
  final Augment augment;
  final Color accent;
  final ValueChanged<Augment>? onPressed;

  const _PatternAugmentDot({
    required this.augment,
    required this.accent,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final handlePressed = onPressed;
    return Tooltip(
      message: augment.displayName,
      child: EndpointAugmentOrb(
        augment: augment,
        accent: accent,
        size: 38,
        onPressed: handlePressed == null ? null : () => handlePressed(augment),
      ),
    );
  }
}

class _PatternMatrixCard extends StatelessWidget {
  static const _patternPointColor = Color(0xFFFFEA4D);
  static const _blockingPointColor = Color(0xFFB05CFF);
  static const _rearCornerOpacity = 0.5;

  final Color accent;
  final Color entryAccent;
  final Widget? summary;
  final Widget child;
  final Object cornerSwapKey;
  final bool animateCornerSwap;
  final int pointCount;
  final int maxPointCount;
  final int blockingCount;
  final int maxBlockingCount;
  final int rearPointCount;
  final int rearMaxPointCount;
  final int rearBlockingCount;
  final int rearMaxBlockingCount;
  final int round;
  final PurgeDoctrine? purgeDoctrine;
  final bool finishEnabled;
  final String finishTooltip;
  final bool showBlockingCorners;
  final bool dimPatternPoints;
  final bool dimBlockPoints;
  final bool dimFinishButton;
  final bool isPatternCornerActive;
  final bool isBlockCornerActive;
  final bool isRearPatternCornerActive;
  final bool isRearBlockCornerActive;
  final bool showCornerWidgets;
  final Color? blockCornerWallAccent;
  final _BattlePatternBlockPlacementMode blockPlacementMode;
  final bool blockCornerWallEnabled;
  final bool blockCornerPointEnabled;
  final bool animateBlockCornerWall;
  final bool showRedoButton;
  final VoidCallback? onRedo;
  final VoidCallback? onBlockModeToggle;
  final GestureDragStartCallback? onBlockDragStart;
  final GestureDragUpdateCallback? onBlockDragUpdate;
  final GestureDragEndCallback? onBlockDragEnd;
  final VoidCallback onFinish;

  const _PatternMatrixCard({
    required this.accent,
    required this.entryAccent,
    required this.summary,
    required this.child,
    this.cornerSwapKey = 'default',
    this.animateCornerSwap = false,
    required this.pointCount,
    required this.maxPointCount,
    required this.blockingCount,
    required this.maxBlockingCount,
    required this.rearPointCount,
    required this.rearMaxPointCount,
    required this.rearBlockingCount,
    required this.rearMaxBlockingCount,
    required this.round,
    this.purgeDoctrine,
    required this.finishEnabled,
    this.finishTooltip = 'Finish turn and resolve the pattern.',
    this.showBlockingCorners = true,
    required this.dimPatternPoints,
    required this.dimBlockPoints,
    required this.dimFinishButton,
    required this.isPatternCornerActive,
    required this.isBlockCornerActive,
    required this.isRearPatternCornerActive,
    required this.isRearBlockCornerActive,
    this.showCornerWidgets = true,
    this.blockCornerWallAccent,
    this.blockPlacementMode = _BattlePatternBlockPlacementMode.wall,
    this.blockCornerWallEnabled = true,
    this.blockCornerPointEnabled = true,
    this.animateBlockCornerWall = false,
    this.showRedoButton = false,
    this.onRedo,
    this.onBlockModeToggle,
    this.onBlockDragStart,
    this.onBlockDragUpdate,
    this.onBlockDragEnd,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(begin: entryAccent, end: accent),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (context, animatedAccent, _) {
        final resolvedAccent = animatedAccent ?? accent;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: EndpointPalette.blend(
              EndpointPalette.panelBackgroundBattleOpaque,
              resolvedAccent,
              0.1,
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: resolvedAccent, width: 3),
            boxShadow: [
              BoxShadow(
                color: resolvedAccent.withAlpha(54),
                blurRadius: 22,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Column(
              children: [
                if (summary != null) ...[
                  summary!,
                  const SizedBox(height: 8),
                ],
                Expanded(
                  child: animateCornerSwap
                      ? TweenAnimationBuilder<double>(
                          key: ValueKey<Object>(cornerSwapKey),
                          tween: Tween<double>(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 420),
                          curve: Curves.easeOutCubic,
                          builder: (context, swapProgress, _) {
                            return _buildMatrixStack(swapProgress);
                          },
                        )
                      : _buildMatrixStack(1),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMatrixStack(double swapProgress) {
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Tooltip(
            message: 'Pattern matrix: connect points to form a match.',
            triggerMode: TooltipTriggerMode.manual,
            child: child,
          ),
        ),
        if (showCornerWidgets)
          _PatternFloatingCorner(
            alignment: Alignment.topLeft,
            progress: swapProgress,
            isRear: true,
            child: _PatternCornerTriangle(
              alignment: Alignment.topLeft,
              color: _patternPointColor,
              label: '$rearPointCount/$rearMaxPointCount',
              tooltip: 'Inactive battler pattern points this turn.',
              textColor: Colors.black,
              opacityScale: _rearCornerOpacity,
              hasAura: isRearPatternCornerActive,
            ),
          ),
        if (showCornerWidgets && showBlockingCorners)
          _PatternFloatingCorner(
            alignment: Alignment.topRight,
            progress: swapProgress,
            isRear: true,
            child: _PatternCornerTriangle(
              alignment: Alignment.topRight,
              color: _blockingPointColor,
              label: '$rearBlockingCount/$rearMaxBlockingCount',
              tooltip: 'Inactive battler blocking points this turn.',
              opacityScale: _rearCornerOpacity,
              hasAura: isRearBlockCornerActive,
            ),
          ),
        if (showCornerWidgets)
          _PatternFloatingCorner(
            alignment: Alignment.topLeft,
            progress: swapProgress,
            child: _PatternCornerTriangle(
              alignment: Alignment.topLeft,
              color: _patternPointColor,
              label: '$pointCount/$maxPointCount',
              tooltip: 'Pattern points used and available this turn.',
              textColor: Colors.black,
              isDimmed: dimPatternPoints,
              hasAura: isPatternCornerActive,
            ),
          ),
        if (showCornerWidgets && showBlockingCorners)
          _PatternFloatingCorner(
            alignment: Alignment.topRight,
            progress: swapProgress,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: onBlockModeToggle,
              onPanStart: onBlockDragStart,
              onPanUpdate: onBlockDragUpdate,
              onPanEnd: onBlockDragEnd,
              child: _PatternCornerTriangle(
                alignment: Alignment.topRight,
                color: _blockingPointColor,
                label: '$blockingCount/$maxBlockingCount',
                tooltip: 'Walls available to place in the foe matrix.',
                isDimmed: dimBlockPoints,
                hasAura: isBlockCornerActive,
                wallGlyphAccent: blockCornerWallAccent,
                blockPlacementMode: blockPlacementMode,
                isWallGlyphEnabled: blockCornerWallEnabled,
                isPointGlyphEnabled: blockCornerPointEnabled,
                animateWallGlyph: animateBlockCornerWall,
                showRedoButton: showRedoButton,
                onRedo: onRedo,
              ),
            ),
          ),
        if (showCornerWidgets)
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: _PatternCornerTriangle(
                alignment: Alignment.bottomLeft,
                color: _roundCornerColor,
                label: _roundCornerLabel,
                tooltip: _roundCornerTooltip,
                textColor: _roundCornerTextColor,
              ),
            ),
          ),
        if (showCornerWidgets)
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: _PatternFinishCorner(
                enabled: finishEnabled,
                isDimmed: dimFinishButton,
                tooltip: finishTooltip,
                onPressed: onFinish,
              ),
            ),
          ),
      ],
    );
  }

  static const int _normalPurgeStartRound = 5;
  static const int _purgeRampRoundCount = 5;
  static const int _purgeInitialDamage = 1;
  static const int _purgeInitialDamagePerRound = 1;
  static const int _purgeLateDamagePerRound = 2;

  int get _purgeStartRound {
    return switch (purgeDoctrine) {
      PurgeDoctrine.embrace => 3,
      PurgeDoctrine.wayOut => 7,
      null => _normalPurgeStartRound,
    };
  }

  int get _purgeWarningRound => max(1, _purgeStartRound - 2);

  Color get _roundCornerColor {
    if (round >= _purgeStartRound) return EndpointPalette.dangerAccent;
    if (round >= _purgeWarningRound) return const Color(0xFFFFEA70);
    return const Color(0xFF24242A);
  }

  Color get _roundCornerTextColor {
    if (round >= _purgeWarningRound && round < _purgeStartRound) {
      return Colors.black;
    }
    return Colors.white;
  }

  String get _roundCornerLabel {
    if (round >= _purgeStartRound) {
      return 'Purga ${_purgeDamageForRound(round)}';
    }
    if (round >= _purgeWarningRound) {
      return 'Purga ${_purgeStartRound - round}';
    }
    return 'Round $round';
  }

  String get _roundCornerTooltip {
    if (round >= _purgeStartRound) {
      return 'Current combat round. Purga damage this round.';
    }
    if (round >= _purgeWarningRound) {
      return 'Current combat round. Purga starts after this countdown.';
    }
    return 'Current combat round.';
  }

  int _purgeDamageForRound(int round) {
    if (round < _purgeStartRound) return 0;
    final fixedDamage = switch (purgeDoctrine) {
      PurgeDoctrine.embrace when round < 10 => 6,
      PurgeDoctrine.wayOut when round < 10 => 4,
      _ => null,
    };
    if (fixedDamage != null) return fixedDamage;

    if (round < _normalPurgeStartRound) return 0;
    final purgeCount = round - _normalPurgeStartRound + 1;
    if (purgeCount <= _purgeRampRoundCount) {
      return _purgeInitialDamage +
          ((purgeCount - 1) * _purgeInitialDamagePerRound);
    }
    const rampEndDamage = _purgeInitialDamage +
        ((_purgeRampRoundCount - 1) * _purgeInitialDamagePerRound);
    return rampEndDamage +
        ((purgeCount - _purgeRampRoundCount) * _purgeLateDamagePerRound);
  }
}

class _PatternFloatingCorner extends StatelessWidget {
  final Alignment alignment;
  final double progress;
  final bool isRear;
  final Widget child;

  const _PatternFloatingCorner({
    required this.alignment,
    required this.progress,
    required this.child,
    this.isRear = false,
  });

  @override
  Widget build(BuildContext context) {
    final rearOffset = Offset(18 * -alignment.x, 18);
    final activeScale = 0.74 + (0.26 * progress);
    final rearScale = 1 - (0.22 * progress);
    final offset = isRear ? rearOffset * progress : rearOffset * (1 - progress);
    final scale = isRear ? rearScale : activeScale;

    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Transform.translate(
          offset: offset,
          child: Transform.scale(
            scale: scale,
            alignment: alignment,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _PatternCornerTriangle extends StatelessWidget {
  final Alignment alignment;
  final Color color;
  final String label;
  final String tooltip;
  final Color textColor;
  final bool isDimmed;
  final bool hasAura;
  final double opacityScale;
  final Color? wallGlyphAccent;
  final _BattlePatternBlockPlacementMode blockPlacementMode;
  final bool isWallGlyphEnabled;
  final bool isPointGlyphEnabled;
  final bool animateWallGlyph;
  final bool showRedoButton;
  final VoidCallback? onRedo;

  const _PatternCornerTriangle({
    required this.alignment,
    required this.color,
    required this.label,
    required this.tooltip,
    this.textColor = Colors.white,
    this.isDimmed = false,
    this.hasAura = false,
    this.opacityScale = 1,
    this.wallGlyphAccent,
    this.blockPlacementMode = _BattlePatternBlockPlacementMode.wall,
    this.isWallGlyphEnabled = true,
    this.isPointGlyphEnabled = true,
    this.animateWallGlyph = false,
    this.showRedoButton = false,
    this.onRedo,
  });

  @override
  Widget build(BuildContext context) {
    final selectedBlockModeEnabled =
        blockPlacementMode == _BattlePatternBlockPlacementMode.wall
            ? isWallGlyphEnabled
            : isPointGlyphEnabled;

    return Tooltip(
      message: tooltip,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        opacity: (isDimmed ? 0.38 : 1) * opacityScale.clamp(0.0, 1.0),
        child: SizedBox(
          width: 100,
          height: 100,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasAura)
                _PatternCornerAura(
                  alignment: alignment,
                  color: color,
                ),
              CustomPaint(
                painter: _PatternTrianglePainter(
                  alignment: alignment,
                  color: color.withAlpha(222),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Align(
                      alignment: alignment,
                      child: Padding(
                        padding: _valuePaddingFor(alignment),
                        child: wallGlyphAccent == null
                            ? Transform.rotate(
                                angle: alignment.y < 0
                                    ? (alignment.x < 0 ? -pi / 4 : pi / 4)
                                    : (alignment.x < 0 ? pi / 4 : -pi / 4),
                                child: EndpointText(
                                  label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textSmallNumericBold.copyWith(
                                    color: textColor,
                                    fontSize: 14,
                                    letterSpacing: 0,
                                  ),
                                ),
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _PatternCornerBlockGlyphWithRedo(
                                    accent: wallGlyphAccent!,
                                    mode: blockPlacementMode,
                                    isWallEnabled: isWallGlyphEnabled,
                                    isPointEnabled: isPointGlyphEnabled,
                                    animate: animateWallGlyph,
                                    showRedoButton: showRedoButton,
                                    onRedo: onRedo,
                                  ),
                                  const SizedBox(height: 1),
                                  EndpointText(
                                    label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textSmallNumericBold.copyWith(
                                      color: textColor.withValues(
                                        alpha: selectedBlockModeEnabled
                                            ? 1.0
                                            : 0.48,
                                      ),
                                      fontSize: 12,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  EdgeInsets _valuePaddingFor(Alignment alignment) {
    if (alignment == Alignment.topLeft) {
      return const EdgeInsets.fromLTRB(27, 27, 0, 0);
    }
    if (alignment == Alignment.topRight) {
      return wallGlyphAccent == null
          ? const EdgeInsets.fromLTRB(0, 27, 27, 0)
          : const EdgeInsets.fromLTRB(0, 6, 6, 0);
    }
    if (alignment == Alignment.bottomLeft) {
      return const EdgeInsets.fromLTRB(27, 0, 0, 27);
    }
    return const EdgeInsets.fromLTRB(0, 0, 27, 27);
  }
}

class _PatternCornerBlockGlyphWithRedo extends StatelessWidget {
  final Color accent;
  final _BattlePatternBlockPlacementMode mode;
  final bool isWallEnabled;
  final bool isPointEnabled;
  final bool animate;
  final bool showRedoButton;
  final VoidCallback? onRedo;

  const _PatternCornerBlockGlyphWithRedo({
    required this.accent,
    required this.mode,
    required this.isWallEnabled,
    required this.isPointEnabled,
    required this.animate,
    required this.showRedoButton,
    this.onRedo,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 34,
      child: Stack(
        alignment: Alignment.centerRight,
        clipBehavior: Clip.none,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (mode == _BattlePatternBlockPlacementMode.wall)
                OperativePatternWallGlyph(
                  accent: accent,
                  enabled: isWallEnabled,
                  animate: animate,
                  width: 46,
                  height: 30,
                )
              else
                _PatternCornerBlockPointGlyph(
                  isEnabled: isPointEnabled,
                  animate: animate,
                ),
              const SizedBox(width: 4),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(220),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: EndpointPalette.softForeground.withAlpha(90),
                    width: 1,
                  ),
                ),
                child: const SizedBox(
                  width: 20,
                  height: 20,
                  child: Icon(
                    Icons.sync_rounded,
                    color: EndpointPalette.softForeground,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          if (showRedoButton)
            Tooltip(
              message: 'Undo this wall placement.',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onRedo,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: EndpointPalette.panelBackgroundBattleOpaque
                        .withAlpha(240),
                    border: Border.all(
                      color: EndpointPalette.softForeground.withAlpha(170),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(150),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const SizedBox(
                    width: 30,
                    height: 30,
                    child: Icon(
                      Icons.undo_rounded,
                      color: EndpointPalette.softForeground,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PatternCornerBlockPointGlyph extends StatelessWidget {
  final bool isEnabled;
  final bool animate;

  const _PatternCornerBlockPointGlyph({
    required this.isEnabled,
    required this.animate,
  });

  @override
  Widget build(BuildContext context) {
    final mark = Icon(
      Icons.close_rounded,
      color: EndpointPalette.dangerAccent.withValues(
        alpha: isEnabled ? 1 : 0.28,
      ),
      size: 34,
    );

    if (!animate || !isEnabled) return mark;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.62, end: 1),
      duration: const Duration(milliseconds: 560),
      curve: Curves.easeInOut,
      builder: (context, opacity, child) {
        return Opacity(opacity: opacity, child: child);
      },
      child: mark,
    );
  }
}

class _PatternCornerAura extends StatefulWidget {
  final Alignment alignment;
  final Color color;

  const _PatternCornerAura({
    required this.alignment,
    required this.color,
  });

  @override
  State<_PatternCornerAura> createState() => _PatternCornerAuraState();
}

class _PatternCornerAuraState extends State<_PatternCornerAura>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _PatternCornerAuraPainter(
              alignment: widget.alignment,
              color: widget.color,
              pulse: Curves.easeInOut.transform(_controller.value),
            ),
          );
        },
      ),
    );
  }
}

class _PatternDimmedRegion extends StatelessWidget {
  final bool isDimmed;
  final Widget child;

  const _PatternDimmedRegion({
    required this.isDimmed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      opacity: isDimmed ? 0.38 : 1,
      child: child,
    );
  }
}

class _PatternFinishCorner extends StatefulWidget {
  final bool enabled;
  final bool isDimmed;
  final String tooltip;
  final VoidCallback onPressed;

  const _PatternFinishCorner({
    required this.enabled,
    required this.isDimmed,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  State<_PatternFinishCorner> createState() => _PatternFinishCornerState();
}

class _PatternFinishCornerState extends State<_PatternFinishCorner> {
  bool _isPressed = false;

  void _setPressed(bool isPressed) {
    if (_isPressed == isPressed) return;
    setState(() {
      _isPressed = isPressed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.enabled;
    final fillAlpha = isActive ? (_isPressed ? 242 : 210) : 92;
    final textAlpha = isActive ? (_isPressed ? 255 : 230) : 120;

    return Tooltip(
      message: widget.tooltip,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        opacity: widget.isDimmed ? 0.38 : 1,
        child: SizedBox(
          width: 108,
          height: 108,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 90),
            curve: Curves.easeOutCubic,
            scale: _isPressed ? 0.96 : 1,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isActive ? widget.onPressed : null,
                onTapDown: isActive ? (_) => _setPressed(true) : null,
                onTapUp: isActive ? (_) => _setPressed(false) : null,
                onTapCancel: isActive ? () => _setPressed(false) : null,
                splashColor: Colors.black.withAlpha(35),
                highlightColor: Colors.black.withAlpha(24),
                customBorder: const _PatternCornerTriangleBorder(
                  alignment: Alignment.bottomRight,
                ),
                child: CustomPaint(
                  painter: _PatternTrianglePainter(
                    alignment: Alignment.bottomRight,
                    color: Colors.white.withAlpha(fillAlpha),
                  ),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 14, 18),
                      child: Transform.rotate(
                        angle: -pi / 4,
                        child: IgnorePointer(
                          child: EndpointText(
                            'Finish\nturn',
                            textAlign: TextAlign.center,
                            style: textSmallBold.copyWith(
                              color: Colors.black.withAlpha(textAlpha),
                              fontSize: 13,
                              height: 0.95,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PatternCornerTriangleBorder extends ShapeBorder {
  final Alignment alignment;

  const _PatternCornerTriangleBorder({
    required this.alignment,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return getOuterPath(rect, textDirection: textDirection);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final path = Path();
    if (alignment == Alignment.topLeft) {
      path
        ..moveTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top)
        ..lineTo(rect.left, rect.bottom);
    } else if (alignment == Alignment.topRight) {
      path
        ..moveTo(rect.right, rect.top)
        ..lineTo(rect.right, rect.bottom)
        ..lineTo(rect.left, rect.top);
    } else if (alignment == Alignment.bottomLeft) {
      path
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.bottom);
    } else {
      path
        ..moveTo(rect.right, rect.bottom)
        ..lineTo(rect.left, rect.bottom)
        ..lineTo(rect.right, rect.top);
    }
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) {
    return this;
  }
}

class _PatternCornerAuraPainter extends CustomPainter {
  final Alignment alignment;
  final Color color;
  final double pulse;

  const _PatternCornerAuraPainter({
    required this.alignment,
    required this.color,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = _patternCornerTrianglePath(alignment, size);
    final glowAlpha = (96 + (72 * pulse)).round();
    final strokeAlpha = (150 + (58 * pulse)).round();

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10 + (pulse * 5)
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10 + (pulse * 8))
        ..color = color.withAlpha(glowAlpha),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round
        ..color = color.withAlpha(strokeAlpha),
    );
  }

  @override
  bool shouldRepaint(covariant _PatternCornerAuraPainter oldDelegate) {
    return oldDelegate.alignment != alignment ||
        oldDelegate.color != color ||
        oldDelegate.pulse != pulse;
  }
}

class _PatternTrianglePainter extends CustomPainter {
  final Alignment alignment;
  final Color color;

  const _PatternTrianglePainter({
    required this.alignment,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      _patternCornerTrianglePath(alignment, size),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _PatternTrianglePainter oldDelegate) {
    return oldDelegate.alignment != alignment || oldDelegate.color != color;
  }
}

Path _patternCornerTrianglePath(Alignment alignment, Size size) {
  final path = Path();
  if (alignment == Alignment.topLeft) {
    path
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(0, size.height);
  } else if (alignment == Alignment.topRight) {
    path
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, 0);
  } else if (alignment == Alignment.bottomLeft) {
    path
      ..moveTo(0, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, size.height);
  } else {
    path
      ..moveTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..lineTo(size.width, 0);
  }
  path.close();
  return path;
}
