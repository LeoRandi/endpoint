import '../_imports.dart';
import 'package:flutter/foundation.dart';
import '../../services/battler_effect_pipeline.dart';
import '../../services/battle_controller.dart';
import '../../services/battle_pattern_block_plan_service.dart';
import '../../services/operative_pattern_bonus_service.dart';
import '../../services/operative_pattern_combat_rules.dart';
import '../../services/operative_pattern_resolution_service.dart';

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

const _battlePatternBlockStartDelay = Duration(milliseconds: 500);
const _battlePatternBlockTravelDuration = Duration(milliseconds: 500);
const _battlePatternEnemyBlockPreviewDuration = Duration(seconds: 1);
const _enemyPatternPointStepDuration = Duration(milliseconds: 750);
const _battlePatternBlockMarkSize = 50.0;

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

bool _hasPassCardWallDisableActive(Battler battler) {
  return battler.combatFlags.any(
    (flag) => flag.itemFlag == ItemCombatFlagKind.passCardWallsDisabledThisTurn,
  );
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
  });

  factory BattlePatternMatchResult.fromResolution(
    OperativePatternResolution resolution,
    BattlePatternBlockMode blockMode,
    BattlePatternMatchContext patternContext,
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

  const EnemyBattlePatternMatchResult({
    required this.attackBonus,
    required this.barrierBonus,
    this.healthBonus = 0,
    required this.blockingPointsRemaining,
    required this.wallSegments,
    required this.blockedPointKeys,
    required this.activatedItemPointKeys,
    required this.patternContext,
  });

  factory EnemyBattlePatternMatchResult.fromResolution(
    OperativePatternResolution resolution,
    BattlePatternMatchContext patternContext,
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
  final int Function(int max)? randomNextInt;
  final Future<void> Function(BattlePatternMatchResult result)? onResolve;
  final ValueListenable<Widget?>? combatAnimationOverlay;
  final ValueListenable<BattlePatternVisualBattlers>? visualBattlers;
  final ValueChanged<BattlePatternAnimationTargets?>? onAnimationTargetsChanged;
  final Future<void> Function(Item item)? onPlayerItemPressed;
  final Future<void> Function(Item item)? onEnemyItemPressed;
  final ValueChanged<BattlerAbility>? onPlayerAbilityPressed;
  final ValueChanged<BattlerAbility>? onEnemyAbilityPressed;

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
    this.randomNextInt,
    this.onResolve,
    this.combatAnimationOverlay,
    this.visualBattlers,
    this.onAnimationTargetsChanged,
    this.onPlayerItemPressed,
    this.onEnemyItemPressed,
    this.onPlayerAbilityPressed,
    this.onEnemyAbilityPressed,
  });

  @override
  State<BattlePatternMatchOverlay> createState() =>
      _BattlePatternMatchOverlayState();
}

class _BattlePatternMatchOverlayState extends State<BattlePatternMatchOverlay>
    with TickerProviderStateMixin {
  final GlobalKey _matchStackKey = GlobalKey();
  final GlobalKey _enemySpriteKey = GlobalKey();
  final GlobalKey _enemyStatusKey = GlobalKey();
  final GlobalKey _playerSpriteKey = GlobalKey();
  final GlobalKey _playerStatusKey = GlobalKey();
  final GlobalKey _patternBoardKey = GlobalKey();
  late final AnimationController _blockMotionController;
  late final Map<String, OperativePatternBonus> _bonusesByPointKey;
  late final int _maxPatternPoints;
  late final int _availableBlockingPointsAtTurnStart;
  late final BattlePatternBlockPlan _blockPlan;
  Timer? _blockStartTimer;
  List<Animation<Offset>> _blockMarkMotions = const <Animation<Offset>>[];
  late List<OperativePatternWallSegment> _wallSegments;
  late Set<String> _blockedPointKeys;
  OperativePatternWallSegment? _previewEnemyWallSegment;
  OperativePatternPoint? _previewEnemyBlockedPoint;
  List<OperativePatternPoint> _patternPoints = const <OperativePatternPoint>[];
  bool _blockAnimationStarted = false;
  bool _blockAnimationCompleted = false;
  bool _hasSwappedToPlayerCorners = false;
  bool _hasSubmitted = false;

  @override
  void initState() {
    super.initState();
    _blockMotionController = AnimationController(
      vsync: this,
      duration: _battlePatternBlockTravelDuration,
    )..addStatusListener(_handleBlockMotionStatus);
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
      nextInt: randomNextInt,
    );
    _maxPatternPoints = OperativePatternCombatRules.maxPatternPointsFor(
      widget.player,
    );
    _availableBlockingPointsAtTurnStart =
        max(0, widget.availableBlockingPoints);
    _wallSegments = List<OperativePatternWallSegment>.unmodifiable(
      widget.wallSegments,
    );
    _blockedPointKeys = Set<String>.unmodifiable(widget.blockedPointKeys);
    if (widget.pendingEnemyBlockAction != null &&
        !widget.pendingEnemyBlockAction!.isEmpty) {
      _scheduleEnemyBoardBlockPreview();
    } else if (_blockPlan.points.isEmpty) {
      _blockAnimationStarted = true;
      _scheduleUnblockedEnemyStepCompletion();
    } else {
      _scheduleBlockAnimationConfiguration();
    }
  }

  @override
  void dispose() {
    _blockStartTimer?.cancel();
    _blockMotionController.dispose();
    widget.onAnimationTargetsChanged?.call(null);
    super.dispose();
  }

  void _scheduleEnemyBoardBlockPreview() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _blockAnimationCompleted) return;
      final action = widget.pendingEnemyBlockAction;
      if (action == null || action.isEmpty) {
        _scheduleUnblockedEnemyStepCompletion();
        return;
      }

      setState(() {
        _blockAnimationStarted = true;
        _previewEnemyWallSegment = action.wallSegment;
        _previewEnemyBlockedPoint = action.point;
      });

      _blockStartTimer?.cancel();
      _blockStartTimer = Timer(_battlePatternEnemyBlockPreviewDuration, () {
        if (!mounted || _blockAnimationCompleted) return;
        _commitEnemyBoardBlockAction(action);
      });
    });
  }

  void _commitEnemyBoardBlockAction(BattlePatternEnemyBlockAction action) {
    final wall = action.wallSegment;
    final point = action.point;
    setState(() {
      if (wall != null &&
          !_wallSegments.any((segment) => segment.key == wall.key)) {
        _wallSegments = List<OperativePatternWallSegment>.unmodifiable([
          ..._wallSegments,
          wall,
        ]);
      }
      if (point != null && !_blockedPointKeys.contains(point.key)) {
        _blockedPointKeys = Set<String>.unmodifiable({
          ..._blockedPointKeys,
          point.key,
        });
      }
      _previewEnemyWallSegment = null;
      _previewEnemyBlockedPoint = null;
      _blockAnimationCompleted = true;
      _hasSwappedToPlayerCorners = true;
    });
  }

  void _scheduleBlockAnimationConfiguration() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _configureBlockAnimation();
    });
  }

  void _scheduleUnblockedEnemyStepCompletion() {
    _blockStartTimer?.cancel();
    _blockStartTimer = Timer(_battlePatternBlockStartDelay, () {
      if (!mounted || _blockAnimationCompleted) return;
      _completeEnemyBlockingStep();
    });
  }

  void _configureBlockAnimation() {
    if (!mounted || _blockAnimationStarted) return;

    final start = _localCenterFor(_enemySpriteKey);
    final ends = <Offset>[];
    for (final point in _blockPlan.points) {
      final end = _localBlockedPointCenter(point);
      if (end == null) {
        _scheduleBlockAnimationConfiguration();
        return;
      }
      ends.add(end);
    }

    if (start == null || ends.isEmpty) {
      _scheduleBlockAnimationConfiguration();
      return;
    }

    _blockMarkMotions = List<Animation<Offset>>.unmodifiable(
      ends.map(
        (end) => Tween<Offset>(
          begin: start,
          end: end,
        ).animate(
          CurvedAnimation(
            parent: _blockMotionController,
            curve: Curves.easeInOutCubic,
          ),
        ),
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

  Offset? _localBlockedPointCenter(OperativePatternPoint point) {
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
      point: point,
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

    _completeEnemyBlockingStep();
  }

  void _completeEnemyBlockingStep() {
    setState(() {
      _blockAnimationCompleted = true;
      _hasSwappedToPlayerCorners = true;
    });
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
    return max(
      0,
      widget.player.abilityById(BattlerAbilityId.adaptacion)?.currentValue ?? 0,
    );
  }

  Iterable<String> _adaptationEligiblePointKeys() {
    if (_adaptationBonusCap() <= 0) return const <String>[];

    return widget.equippedItemsByPointKey.entries
        .where((entry) => _isAdaptationEligibleItem(entry.value))
        .map((entry) => entry.key);
  }

  bool _isAdaptationEligibleItem(Item item) {
    return !item.hasPatternBonus && item.patternAdjacencyBonuses.isEmpty;
  }

  BattlePatternMatchResult get _currentResult =>
      BattlePatternMatchResult.fromResolution(
        _currentResolution,
        _blockPlan.mode,
        _currentPatternContext(_currentResolution),
        _availableBlockingPoints,
        _enemyBlockingPointsRemaining,
        _wallSegments,
        _blockedPointKeys,
      );

  int get _enemyBlockingPointsRemaining {
    final spentBlockingPoints = (_wallSegments.length *
            OperativePatternCombatRules.wallBlockingPointCost) +
        (_blockedPointKeys.length *
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
    final usedItemPointKeys = _usedItemPointKeys();
    return BattlePatternMatchContext(
      patternPoints: List<OperativePatternPoint>.unmodifiable(_patternPoints),
      attackBonus: resolution.attackBonus,
      barrierBonus: resolution.barrierBonus,
      otherArchetypeItemCount: _otherArchetypeActivatedItemCount(resolution),
      usedItemPointKeys: List<String>.unmodifiable(usedItemPointKeys),
      repeatedItemPointKeys: Set<String>.unmodifiable(
        _repeatedItemPointKeys(usedItemPointKeys),
      ),
      firstRepeatedItemPointKey: _firstRepeatedItemPointKey(usedItemPointKeys),
      firstUsedItemHasAttackBonus:
          _firstUsedItemHasAttackBonus(usedItemPointKeys),
      activatedItemEffectCount: _activatedItemEffectCount(usedItemPointKeys),
    );
  }

  List<String> _usedItemPointKeys() {
    return [
      for (final point in OperativePatternRequirement.normalizedSequence(
        _patternPoints,
      ))
        if (widget.equippedItemsByPointKey.containsKey(point.key)) point.key,
    ];
  }

  Set<String> _repeatedItemPointKeys(List<String> usedItemPointKeys) {
    final seen = <String>{};
    final repeated = <String>{};
    for (final pointKey in usedItemPointKeys) {
      if (!seen.add(pointKey)) {
        repeated.add(pointKey);
      }
    }
    return repeated;
  }

  String? _firstRepeatedItemPointKey(List<String> usedItemPointKeys) {
    final seen = <String>{};
    for (final pointKey in usedItemPointKeys) {
      if (!seen.add(pointKey)) return pointKey;
    }
    return null;
  }

  bool _firstUsedItemHasAttackBonus(List<String> usedItemPointKeys) {
    if (usedItemPointKeys.isEmpty) return false;

    final item = widget.equippedItemsByPointKey[usedItemPointKeys.first];
    if (item == null) return false;

    return item.modifier(BattlerStat.attack) > 0 ||
        (item.hasPatternBonus &&
            item.patternBonus.kind == OperativePatternBonusKind.attack) ||
        item.patternAdjacencyBonuses.any(
          (bonus) => bonus.bonus.kind == OperativePatternBonusKind.attack,
        );
  }

  int _activatedItemEffectCount(List<String> usedItemPointKeys) {
    var count = 0;
    final seen = <String>{};
    for (final pointKey in usedItemPointKeys) {
      if (!seen.add(pointKey)) continue;
      final effect = widget.equippedItemsByPointKey[pointKey]?.effect;
      if (effect == null) continue;
      if (effect.hooks.contains(ItemEffectHook.patternUsed) ||
          effect.hooks.contains(ItemEffectHook.prePatternAttack)) {
        count++;
      }
    }
    return count;
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
    final specificAffinities = item.archetypeAffinities.where(
      (affinity) => affinity.isSpecific,
    );
    return specificAffinities.any((affinity) => affinity != playerAffinity);
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
    _hasSubmitted = true;
    final result = _currentResult;
    await widget.onResolve?.call(result);
    if (!mounted) return;
    Navigator.of(context).pop(result);
  }

  int _estimatedHitDamageFor(int attackBonus) {
    if (widget.enemy.hasStatus(PuntoCiegoStatus.statusId)) return 0;

    const effectPipeline = BattlerEffectPipeline();
    final baseDamage = (widget.player.calculateDamageAgainst(widget.enemy) +
            max(0, attackBonus))
        .toInt();
    final outgoingStatusModifiedDamage =
        effectPipeline.applyOutgoingDamageModifiers(
      owner: widget.player,
      target: widget.enemy,
      damage: baseDamage,
    );
    final outgoingAbilityModifiedDamage =
        effectPipeline.applyAbilityOutgoingDamageModifiers(
      owner: widget.player,
      target: widget.enemy,
      damage: outgoingStatusModifiedDamage,
    );
    final outgoingItemModifiedDamage =
        effectPipeline.applyEquippedItemOutgoingDamageModifiers(
      owner: widget.player,
      target: widget.enemy,
      damage: outgoingAbilityModifiedDamage,
    );
    final incomingStatusModifiedDamage =
        effectPipeline.applyIncomingDamageModifiers(
      owner: widget.enemy,
      source: widget.player,
      damage: outgoingItemModifiedDamage,
    );
    final incomingAbilityModifiedDamage =
        effectPipeline.applyAbilityIncomingDamageModifiers(
      owner: widget.enemy,
      source: widget.player,
      damage: incomingStatusModifiedDamage,
    );
    return effectPipeline.applyEquippedItemIncomingDamageModifiers(
      owner: widget.enemy,
      source: widget.player,
      damage: incomingAbilityModifiedDamage,
    );
  }

  String _estimatedTotalDamageLabelFor(int attackBonus) {
    final hitDamage = _estimatedHitDamageFor(attackBonus);
    final hitCount = max(1, widget.player.basicAttackCount);
    if (hitCount <= 1) return '$hitDamage';

    return '${max(0, hitDamage)}x$hitCount';
  }

  Map<String, OperativePatternPointContent> _buildContentsByPointKey(
    OperativePatternResolution resolution,
  ) {
    return <String, OperativePatternPointContent>{
      for (final entry in widget.equippedItemsByPointKey.entries)
        entry.key: OperativePatternPointContent(
          item: entry.value,
          bonus: entry.value.hasPatternBonus
              ? entry.value.patternBonus
              : _isAdaptationEligibleItem(entry.value)
                  ? _bonusesByPointKey[entry.key]
                  : null,
          requirement: entry.value.hasPatternBonus
              ? entry.value.patternRequirement
              : null,
          adjacencyBonuses: entry.value.patternAdjacencyBonuses,
          activatedAdjacencyBonuses:
              resolution.activatedAdjacencyBonusesAt(entry.key),
          isBonusEnabled: resolution.isItemBonusEnabledAt(entry.key),
          isPatternBonusActivated: resolution.isItemBonusEnabledAt(entry.key),
          hasAura: entry.value.hasPatternAura,
        ),
      for (final entry in _bonusesByPointKey.entries)
        if (!widget.equippedItemsByPointKey.containsKey(entry.key))
          entry.key: OperativePatternPointContent(bonus: entry.value),
    };
  }

  @override
  Widget build(BuildContext context) {
    final resolution = _currentResolution;
    final result = BattlePatternMatchResult.fromResolution(
      resolution,
      _blockPlan.mode,
      _currentPatternContext(resolution),
      _availableBlockingPoints,
      _enemyBlockingPointsRemaining,
      _wallSegments,
      _blockedPointKeys,
    );
    final baseHitDamage = _estimatedHitDamageFor(0);
    final totalDamageLabel = _estimatedTotalDamageLabelFor(result.attackBonus);
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
        abilities: widget.enemy.abilities
            .where(
              (ability) => ability.appearsInContext(
                BattlerAbilityActivationContext.battle,
              ),
            )
            .toList(growable: false),
        accent: EndpointPalette.dangerAccent,
        alignEnd: true,
        items: widget.enemy.equippedItems,
        onItemPressed: widget.onEnemyItemPressed,
        onAbilityPressed: widget.onEnemyAbilityPressed,
      ),
      matrix: _PatternMatrixCard(
        accent: EndpointPalette.patternAccent,
        entryAccent: EndpointPalette.dangerAccent,
        summary: _BattlePatternLiveSummary(
          baseHitDamage: baseHitDamage,
          totalDamageLabel: totalDamageLabel,
          attackBonus: result.attackBonus,
          barrierBonus: result.barrierBonus,
          healthBonus: result.healthBonus,
          effects: widget.actionEffects,
          pointCount: resolution.distinctPointCount,
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
        finishEnabled: _blockAnimationCompleted &&
            OperativePatternRequirement.isClosedPattern(_patternPoints),
        onFinish: _submit,
        dimPatternPoints: false,
        dimBlockPoints: false,
        dimFinishButton: isBoardDimmed,
        isPatternCornerActive: !isBoardDimmed,
        isBlockCornerActive: false,
        isRearPatternCornerActive: false,
        isRearBlockCornerActive: false,
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
                          key: _patternBoardKey,
                          contentsByPointKey: _buildContentsByPointKey(
                            resolution,
                          ),
                          blockedPointKeys: blockedPointKeys,
                          keepLineAfterPointerUp: true,
                          maxPatternPoints: _effectiveMaxPatternPoints,
                          wallSegments: _wallSegments,
                          disabledWallSegmentKeys: disabledWallSegmentKeys,
                          previewWallSegment: _previewEnemyWallSegment,
                          previewBlockedPointKey:
                              _previewEnemyBlockedPoint?.key,
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
        abilities: widget.player.abilities
            .where(
              (ability) => ability.appearsInContext(
                BattlerAbilityActivationContext.battle,
              ),
            )
            .toList(growable: false),
        accent: EndpointPalette.patternAccent,
        items: widget.player.equippedItems,
        onItemPressed: widget.onPlayerItemPressed,
        onAbilityPressed: widget.onPlayerAbilityPressed,
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
      overlay: !_blockAnimationCompleted
          ? Stack(
              children: [
                for (final animation in _blockMarkMotions)
                  _BattlePatternBlockMotion(animation: animation),
              ],
            )
          : null,
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
  final Future<void> Function(EnemyBattlePatternMatchResult result)? onResolve;
  final ValueListenable<Widget?>? combatAnimationOverlay;
  final ValueListenable<BattlePatternVisualBattlers>? visualBattlers;
  final ValueChanged<BattlePatternAnimationTargets?>? onAnimationTargetsChanged;
  final Future<void> Function(Item item)? onPlayerItemPressed;
  final Future<void> Function(Item item)? onEnemyItemPressed;
  final ValueChanged<BattlerAbility>? onPlayerAbilityPressed;
  final ValueChanged<BattlerAbility>? onEnemyAbilityPressed;

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
    this.onResolve,
    this.combatAnimationOverlay,
    this.visualBattlers,
    this.onAnimationTargetsChanged,
    this.onPlayerItemPressed,
    this.onEnemyItemPressed,
    this.onPlayerAbilityPressed,
    this.onEnemyAbilityPressed,
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
      nextInt: _nextInt,
    );
    _maxPatternPoints = OperativePatternCombatRules.maxPatternPointsFor(
      widget.enemy,
    );
    _wallSegments = List<OperativePatternWallSegment>.unmodifiable(
      widget.wallSegments,
    );
    _blockedPointKeys = Set<String>.unmodifiable(widget.blockedPointKeys);
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
        _blockingPointsRemaining,
        _wallSegments,
        _blockedPointKeys,
      );

  int get _blockingPointsRemaining {
    final spentBlockingPoints = (_wallSegments.length *
            OperativePatternCombatRules.wallBlockingPointCost) +
        (_blockedPointKeys.length *
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
    final usedItemPointKeys = _usedItemPointKeys();
    return BattlePatternMatchContext(
      patternPoints: List<OperativePatternPoint>.unmodifiable(
        _displayedEnemyPatternPoints,
      ),
      attackBonus: resolution.attackBonus,
      barrierBonus: resolution.barrierBonus,
      otherArchetypeItemCount: 0,
      usedItemPointKeys: List<String>.unmodifiable(usedItemPointKeys),
      repeatedItemPointKeys: Set<String>.unmodifiable(
        _repeatedItemPointKeys(usedItemPointKeys),
      ),
      firstRepeatedItemPointKey: _firstRepeatedItemPointKey(usedItemPointKeys),
      firstUsedItemHasAttackBonus:
          _firstUsedItemHasAttackBonus(usedItemPointKeys),
      activatedItemEffectCount: _activatedItemEffectCount(usedItemPointKeys),
    );
  }

  List<String> _usedItemPointKeys() {
    return [
      for (final point in OperativePatternRequirement.normalizedSequence(
        _displayedEnemyPatternPoints,
      ))
        if (widget.equippedItemsByPointKey.containsKey(point.key)) point.key,
    ];
  }

  Set<String> _repeatedItemPointKeys(List<String> usedItemPointKeys) {
    final seen = <String>{};
    final repeated = <String>{};
    for (final pointKey in usedItemPointKeys) {
      if (!seen.add(pointKey)) {
        repeated.add(pointKey);
      }
    }
    return repeated;
  }

  String? _firstRepeatedItemPointKey(List<String> usedItemPointKeys) {
    final seen = <String>{};
    for (final pointKey in usedItemPointKeys) {
      if (!seen.add(pointKey)) return pointKey;
    }
    return null;
  }

  bool _firstUsedItemHasAttackBonus(List<String> usedItemPointKeys) {
    if (usedItemPointKeys.isEmpty) return false;

    final item = widget.equippedItemsByPointKey[usedItemPointKeys.first];
    if (item == null) return false;

    return item.modifier(BattlerStat.attack) > 0 ||
        (item.hasPatternBonus &&
            item.patternBonus.kind == OperativePatternBonusKind.attack) ||
        item.patternAdjacencyBonuses.any(
          (bonus) => bonus.bonus.kind == OperativePatternBonusKind.attack,
        );
  }

  int _activatedItemEffectCount(List<String> usedItemPointKeys) {
    var count = 0;
    final seen = <String>{};
    for (final pointKey in usedItemPointKeys) {
      if (!seen.add(pointKey)) continue;
      final effect = widget.equippedItemsByPointKey[pointKey]?.effect;
      if (effect == null) continue;
      if (effect.hooks.contains(ItemEffectHook.patternUsed) ||
          effect.hooks.contains(ItemEffectHook.prePatternAttack)) {
        count++;
      }
    }
    return count;
  }

  Map<String, OperativePatternPointContent> _buildContentsByPointKey(
    OperativePatternResolution resolution,
  ) {
    return <String, OperativePatternPointContent>{
      for (final entry in widget.equippedItemsByPointKey.entries)
        entry.key: OperativePatternPointContent(
          item: entry.value,
          bonus: entry.value.hasPatternBonus
              ? entry.value.patternBonus
              : _bonusesByPointKey[entry.key],
          requirement: entry.value.hasPatternBonus
              ? entry.value.patternRequirement
              : null,
          adjacencyBonuses: entry.value.patternAdjacencyBonuses,
          activatedAdjacencyBonuses:
              resolution.activatedAdjacencyBonusesAt(entry.key),
          isBonusEnabled: resolution.isItemBonusEnabledAt(entry.key),
          isPatternBonusActivated: resolution.isItemBonusEnabledAt(entry.key),
          hasAura: entry.value.hasPatternAura,
        ),
      for (final entry in _bonusesByPointKey.entries)
        if (!widget.equippedItemsByPointKey.containsKey(entry.key))
          entry.key: OperativePatternPointContent(bonus: entry.value),
    };
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
    for (var attempt = 0; attempt < 3; attempt++) {
      final pattern = _buildEnemyPattern();
      if (OperativePatternRequirement.isClosedPattern(pattern)) {
        return pattern;
      }
    }

    return const <OperativePatternPoint>[];
  }

  List<OperativePatternPoint> _buildEnemyPattern() {
    final maxDistinctPoints = max(3, _enemyEffectiveMaxPatternPoints);
    final candidates = <OperativePatternPoint>[
      for (final point in operativePatternPoints)
        if (!_blockedPointKeys.contains(point.key)) point,
    ];
    if (candidates.length < 3) return const <OperativePatternPoint>[];

    candidates.sort((a, b) {
      final aItem = widget.equippedItemsByPointKey[a.key];
      final bItem = widget.equippedItemsByPointKey[b.key];
      final aScore = _enemyPointPriority(aItem);
      final bScore = _enemyPointPriority(bItem);
      return bScore.compareTo(aScore);
    });

    for (var targetLength = min(maxDistinctPoints, candidates.length);
        targetLength >= 3;
        targetLength--) {
      final selected = _bestClosedEnemyPattern(
        candidates: candidates,
        targetLength: targetLength,
      );
      if (selected != null) {
        return List<OperativePatternPoint>.unmodifiable([
          ...selected,
          selected.first,
        ]);
      }
    }

    return const <OperativePatternPoint>[];
  }

  List<OperativePatternPoint>? _bestClosedEnemyPattern({
    required List<OperativePatternPoint> candidates,
    required int targetLength,
  }) {
    List<OperativePatternPoint>? bestPattern;
    var bestScore = -1;

    void visit(
      List<OperativePatternPoint> path,
      Set<String> usedKeys,
    ) {
      if (path.length == targetLength) {
        if (_isEnemyPatternSegmentBlocked(path.last, path.first)) return;
        final score = path.fold<int>(
          0,
          (sum, point) =>
              sum +
              _enemyPointPriority(
                widget.equippedItemsByPointKey[point.key],
              ),
        );
        if (score > bestScore) {
          bestScore = score;
          bestPattern = List<OperativePatternPoint>.unmodifiable(path);
        }
        return;
      }

      for (final point in candidates) {
        if (usedKeys.contains(point.key)) continue;
        if (path.isNotEmpty &&
            _isEnemyPatternSegmentBlocked(path.last, point)) {
          continue;
        }
        usedKeys.add(point.key);
        path.add(point);
        visit(path, usedKeys);
        path.removeLast();
        usedKeys.remove(point.key);
      }
    }

    for (final point in candidates) {
      visit(<OperativePatternPoint>[point], <String>{point.key});
    }
    return bestPattern;
  }

  bool _isEnemyPatternSegmentBlocked(
    OperativePatternPoint from,
    OperativePatternPoint to,
  ) {
    final activeWalls = _activeWallSegmentsForEnemyPattern;
    final connectedWallKeys = _connectedWallKeysFor(activeWalls);
    return activeWalls.any(
      (wall) => wall.blocks(
        from,
        to,
        isConnected: connectedWallKeys.contains(wall.key),
      ),
    );
  }

  Set<String> _connectedWallKeysFor(
    Iterable<OperativePatternWallSegment> walls,
  ) {
    final endpointUseCounts = <String, int>{};
    for (final wall in walls) {
      endpointUseCounts.update(
        wall.a.key,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      endpointUseCounts.update(
        wall.b.key,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }

    return <String>{
      for (final wall in walls)
        if ((endpointUseCounts[wall.a.key] ?? 0) > 1 ||
            (endpointUseCounts[wall.b.key] ?? 0) > 1)
          wall.key,
    };
  }

  List<OperativePatternWallSegment> get _activeWallSegmentsForEnemyPattern {
    if (!_hasPassCardWallDisableActive(widget.enemy)) return _wallSegments;

    return const <OperativePatternWallSegment>[];
  }

  int get _enemyEffectiveMaxPatternPoints {
    return _maxPatternPoints + (widget.enemyOverchargesPattern ? 1 : 0);
  }

  int _enemyPointPriority(Item? item) {
    if (item == null) return 0;
    var score = item.modifier(BattlerStat.attack) * 3;
    if (item.hasPatternBonus &&
        item.patternBonus.kind == OperativePatternBonusKind.attack) {
      score += item.patternBonus.amount * 4;
    }
    score += item.patternAdjacencyBonuses
        .where((bonus) => bonus.bonus.kind == OperativePatternBonusKind.attack)
        .fold<int>(0, (sum, bonus) => sum + bonus.bonus.amount * 2);
    return score;
  }

  int _estimatedHitDamageFor(int attackBonus) {
    if (widget.player.hasStatus(PuntoCiegoStatus.statusId)) return 0;

    const effectPipeline = BattlerEffectPipeline();
    final baseDamage = (widget.enemy.calculateDamageAgainst(widget.player) +
            max(0, attackBonus))
        .toInt();
    final outgoingStatusModifiedDamage =
        effectPipeline.applyOutgoingDamageModifiers(
      owner: widget.enemy,
      target: widget.player,
      damage: baseDamage,
    );
    final outgoingAbilityModifiedDamage =
        effectPipeline.applyAbilityOutgoingDamageModifiers(
      owner: widget.enemy,
      target: widget.player,
      damage: outgoingStatusModifiedDamage,
    );
    final outgoingItemModifiedDamage =
        effectPipeline.applyEquippedItemOutgoingDamageModifiers(
      owner: widget.enemy,
      target: widget.player,
      damage: outgoingAbilityModifiedDamage,
    );
    final incomingStatusModifiedDamage =
        effectPipeline.applyIncomingDamageModifiers(
      owner: widget.player,
      source: widget.enemy,
      damage: outgoingItemModifiedDamage,
    );
    final incomingAbilityModifiedDamage =
        effectPipeline.applyAbilityIncomingDamageModifiers(
      owner: widget.player,
      source: widget.enemy,
      damage: incomingStatusModifiedDamage,
    );
    return effectPipeline.applyEquippedItemIncomingDamageModifiers(
      owner: widget.player,
      source: widget.enemy,
      damage: incomingAbilityModifiedDamage,
    );
  }

  String _estimatedTotalDamageLabelFor(int attackBonus) {
    final hitDamage = _estimatedHitDamageFor(attackBonus);
    final hitCount = max(1, widget.enemy.basicAttackCount);
    if (hitCount <= 1) return '$hitDamage';

    return '${max(0, hitDamage)}x$hitCount';
  }

  @override
  Widget build(BuildContext context) {
    final resolution = _currentResolution;
    final result = _currentResult;
    final baseHitDamage = _estimatedHitDamageFor(0);
    final totalDamageLabel = _estimatedTotalDamageLabelFor(result.attackBonus);
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
        abilities: widget.enemy.abilities
            .where(
              (ability) => ability.appearsInContext(
                BattlerAbilityActivationContext.battle,
              ),
            )
            .toList(growable: false),
        accent: EndpointPalette.dangerAccent,
        alignEnd: true,
        items: widget.enemy.equippedItems,
        onItemPressed: widget.onEnemyItemPressed,
        onAbilityPressed: widget.onEnemyAbilityPressed,
      ),
      matrix: _PatternMatrixCard(
        accent: EndpointPalette.dangerAccent,
        entryAccent: EndpointPalette.patternAccent,
        summary: _BattlePatternLiveSummary(
          baseHitDamage: baseHitDamage,
          totalDamageLabel: totalDamageLabel,
          attackBonus: result.attackBonus,
          barrierBonus: result.barrierBonus,
          healthBonus: result.healthBonus,
          effects: const <PlayerActionEffectIntent>[],
          pointCount: resolution.distinctPointCount,
        ),
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
                      absorbing: _canMovePlacedBlock,
                      child: Transform.rotate(
                        angle: pi / 4,
                        child: OperativePatternBoard(
                          key: _enemyPatternBoardKey,
                          contentsByPointKey:
                              _buildContentsByPointKey(resolution),
                          blockedPointKeys: displayedBlockedPointKeys,
                          displayedPatternPoints: _displayedEnemyPatternPoints,
                          keepLineAfterPointerUp: true,
                          isPatternInputEnabled: !_canMovePlacedBlock,
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
                          onPointLongPressed: _handlePointLongPressed,
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
        abilities: widget.player.abilities
            .where(
              (ability) => ability.appearsInContext(
                BattlerAbilityActivationContext.battle,
              ),
            )
            .toList(growable: false),
        accent: EndpointPalette.patternAccent,
        items: widget.player.equippedItems,
        onItemPressed: widget.onPlayerItemPressed,
        onAbilityPressed: widget.onPlayerAbilityPressed,
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

class _BattlePatternLiveSummary extends StatelessWidget {
  final int baseHitDamage;
  final String totalDamageLabel;
  final int attackBonus;
  final int barrierBonus;
  final int healthBonus;
  final List<PlayerActionEffectIntent> effects;
  final int pointCount;

  const _BattlePatternLiveSummary({
    required this.baseHitDamage,
    required this.totalDamageLabel,
    required this.attackBonus,
    required this.barrierBonus,
    required this.healthBonus,
    required this.effects,
    required this.pointCount,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: EndpointPalette.panelBackgroundOpaque.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: EndpointPalette.patternAccent.withValues(alpha: 0.62),
        ),
        boxShadow: [
          BoxShadow(
            color: EndpointPalette.patternAccent.withValues(alpha: 0.16),
            blurRadius: 18,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: Row(
          children: [
            Expanded(
              child: _BattlePatternDamageFormula(
                baseHitDamage: baseHitDamage,
                attackBonus: attackBonus,
                totalDamageLabel: totalDamageLabel,
                pointCount: pointCount,
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 48,
              child: _BattlePatternAnimatedMetric(
                label: '+B',
                iconAssetPath: 'assets/images/icons/icon_shield.png',
                value: barrierBonus,
                accent: BattlerStat.barrier.accent,
                pulseKey: pointCount,
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 48,
              child: _BattlePatternAnimatedMetric(
                label: '+H',
                iconAssetPath: 'assets/images/icons/icon_health.png',
                value: healthBonus,
                accent: BattlerStat.health.accent,
                pulseKey: pointCount,
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 42,
              child: _BattlePatternEffectsCard(effects: effects),
            ),
          ],
        ),
      ),
    );
  }
}

class _BattlePatternDamageFormula extends StatelessWidget {
  final int baseHitDamage;
  final int attackBonus;
  final String totalDamageLabel;
  final int pointCount;

  const _BattlePatternDamageFormula({
    required this.baseHitDamage,
    required this.attackBonus,
    required this.totalDamageLabel,
    required this.pointCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _BattlePatternMetricShell(
            label: 'BA',
            iconAssetPath: 'assets/images/icons/icon_sword.png',
            valueLabel: '$baseHitDamage',
            accent: EndpointPalette.dangerAccent,
          ),
        ),
        const _BattlePatternFormulaOperator('+'),
        Expanded(
          child: _BattlePatternAnimatedMetric(
            label: '+A',
            iconAssetPath: 'assets/images/icons/icon_sword.png',
            value: attackBonus,
            accent: EndpointPalette.warningAccent,
            pulseKey: pointCount,
          ),
        ),
        const _BattlePatternFormulaOperator('='),
        Expanded(
          child: _BattlePatternLabelMetric(
            label: 'DMG',
            iconAssetPath: 'assets/images/icons/icon_sword.png',
            valueLabel: totalDamageLabel,
            accent: EndpointPalette.dangerAccent,
          ),
        ),
      ],
    );
  }
}

class _BattlePatternFormulaOperator extends StatelessWidget {
  final String label;

  const _BattlePatternFormulaOperator(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: EndpointText(
        label,
        style: textMediumBold.copyWith(
          color: EndpointPalette.dangerAccent,
          fontSize: 17,
          height: 1,
        ),
      ),
    );
  }
}

class _BattlePatternEffectsCard extends StatelessWidget {
  final List<PlayerActionEffectIntent> effects;

  const _BattlePatternEffectsCard({
    required this.effects,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: EndpointPalette.controlBackground,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: EndpointPalette.neutralAccent.withValues(alpha: 0.46),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(5, 4, 5, 4),
        child: Center(
          child: effects.isEmpty
              ? Icon(
                  Icons.remove_rounded,
                  size: 15,
                  color: EndpointPalette.softForeground.withAlpha(150),
                )
              : Wrap(
                  spacing: 3,
                  runSpacing: 3,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final effect in effects)
                      _BattlePatternEffectChip(effect: effect),
                  ],
                ),
        ),
      ),
    );
  }
}

class _BattlePatternEffectChip extends StatelessWidget {
  final PlayerActionEffectIntent effect;

  const _BattlePatternEffectChip({
    required this.effect,
  });

  @override
  Widget build(BuildContext context) {
    final icon = switch (effect.kind) {
      PlayerActionEffectIntentKind.heal => Icons.favorite_rounded,
      PlayerActionEffectIntentKind.buff ||
      PlayerActionEffectIntentKind.debuff =>
        effect.status?.icon ?? Icons.auto_awesome_rounded,
      PlayerActionEffectIntentKind.ability =>
        effect.ability?.icon ?? Icons.auto_awesome_rounded,
    };
    final accent = switch (effect.kind) {
      PlayerActionEffectIntentKind.heal => BattlerStatusType.buff.accent,
      PlayerActionEffectIntentKind.buff ||
      PlayerActionEffectIntentKind.debuff =>
        effect.status?.type.accent ?? EndpointPalette.neutralAccent,
      PlayerActionEffectIntentKind.ability =>
        effect.ability?.accent ?? EndpointPalette.neutralAccent,
    };
    final valueLabel = switch (effect.kind) {
      PlayerActionEffectIntentKind.heal => '${max(0, effect.amount)}',
      PlayerActionEffectIntentKind.buff ||
      PlayerActionEffectIntentKind.debuff =>
        effect.amount > 0 ? '${max(0, effect.amount)}' : null,
      PlayerActionEffectIntentKind.ability => null,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: EndpointPalette.panelBackgroundBattleOpaque,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withAlpha(145)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: accent,
            ),
            if (valueLabel != null) ...[
              const SizedBox(width: 2),
              EndpointText(
                valueLabel,
                style: textSmallNumericBold.copyWith(
                  color: accent,
                  fontSize: 10,
                  letterSpacing: 0.2,
                  height: 1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BattlePatternAnimatedMetric extends StatelessWidget {
  final String label;
  final String iconAssetPath;
  final int value;
  final Color accent;
  final int pulseKey;

  const _BattlePatternAnimatedMetric({
    required this.label,
    required this.iconAssetPath,
    required this.value,
    required this.accent,
    required this.pulseKey,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue = max(0, value);

    return TweenAnimationBuilder<double>(
      key: ValueKey('$label:$safeValue:$pulseKey'),
      tween: Tween<double>(
        begin: 0,
        end: safeValue.toDouble(),
      ),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        final progress = safeValue <= 0 ? 1.0 : animatedValue / safeValue;
        return Transform.scale(
          scale: 1 + ((1 - progress.clamp(0.0, 1.0)) * 0.08),
          child: _BattlePatternMetricShell(
            label: label,
            iconAssetPath: iconAssetPath,
            valueLabel: '+${animatedValue.round()}',
            accent: accent,
          ),
        );
      },
    );
  }
}

class _BattlePatternLabelMetric extends StatelessWidget {
  final String label;
  final String iconAssetPath;
  final String valueLabel;
  final Color accent;

  const _BattlePatternLabelMetric({
    required this.label,
    required this.iconAssetPath,
    required this.valueLabel,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return _BattlePatternMetricShell(
      label: label,
      iconAssetPath: iconAssetPath,
      valueLabel: valueLabel,
      accent: accent,
    );
  }
}

class _BattlePatternMetricShell extends StatelessWidget {
  final String label;
  final String? iconAssetPath;
  final IconData? icon;
  final String valueLabel;
  final Color accent;

  const _BattlePatternMetricShell({
    required this.label,
    this.iconAssetPath,
    this.icon,
    required this.valueLabel,
    required this.accent,
  }) : assert(iconAssetPath != null || icon != null);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: EndpointPalette.controlBackground,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: accent.withValues(alpha: 0.46)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(5, 4, 5, 4),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            if (iconAssetPath != null)
              Image.asset(
                iconAssetPath!,
                width: 13,
                height: 13,
                filterQuality: FilterQuality.none,
                color: accent,
              )
            else
              Icon(
                icon,
                size: 13,
                color: accent,
              ),
            const SizedBox(width: 3),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EndpointText(
                    label,
                    overflow: TextOverflow.clip,
                    softWrap: false,
                    style: textSmallBold.copyWith(
                      color: accent.withValues(alpha: 0.82),
                      fontSize: 7,
                      letterSpacing: 0.2,
                      height: 1,
                    ),
                  ),
                  EndpointText(
                    valueLabel,
                    overflow: TextOverflow.clip,
                    softWrap: false,
                    style: textSmallNumericBold.copyWith(
                      color: accent,
                      fontSize: 12,
                      letterSpacing: 0,
                      height: 1.05,
                    ),
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
                    color: EndpointPalette.dangerAccent,
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

class _PatternAugmentStrip extends StatelessWidget {
  final List<BattlerAbility> abilities;
  final Color accent;
  final bool alignEnd;
  final List<Item> items;
  final Future<void> Function(Item item)? onItemPressed;
  final ValueChanged<BattlerAbility>? onAbilityPressed;

  const _PatternAugmentStrip({
    required this.abilities,
    required this.accent,
    this.alignEnd = false,
    this.items = const <Item>[],
    this.onItemPressed,
    this.onAbilityPressed,
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
                for (var index = 0; index < abilities.length; index++) ...[
                  if (index > 0) const SizedBox(width: 8),
                  _PatternAugmentDot(
                    ability: abilities[index],
                    accent: accent,
                    onPressed: onAbilityPressed,
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
                      child: EndpointText(
                        item.iconEmoji,
                        textAlign: TextAlign.center,
                        style: textSmall.copyWith(fontSize: 15),
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
  final BattlerAbility ability;
  final Color accent;
  final ValueChanged<BattlerAbility>? onPressed;

  const _PatternAugmentDot({
    required this.ability,
    required this.accent,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final handlePressed = onPressed;
    return Tooltip(
      message: ability.name,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: handlePressed == null ? null : () => handlePressed(ability),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: EndpointPalette.panelBackgroundBattleOpaque,
              border: Border.all(color: accent.withAlpha(150), width: 2),
            ),
            child: SizedBox(
              width: 38,
              height: 38,
              child: Icon(ability.icon, color: ability.accent, size: 20),
            ),
          ),
        ),
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
  final Widget summary;
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
  final bool finishEnabled;
  final bool dimPatternPoints;
  final bool dimBlockPoints;
  final bool dimFinishButton;
  final bool isPatternCornerActive;
  final bool isBlockCornerActive;
  final bool isRearPatternCornerActive;
  final bool isRearBlockCornerActive;
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
    required this.finishEnabled,
    required this.dimPatternPoints,
    required this.dimBlockPoints,
    required this.dimFinishButton,
    required this.isPatternCornerActive,
    required this.isBlockCornerActive,
    required this.isRearPatternCornerActive,
    required this.isRearBlockCornerActive,
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
                summary,
                const SizedBox(height: 8),
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
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: _PatternFinishCorner(
              enabled: finishEnabled,
              isDimmed: dimFinishButton,
              tooltip: 'Finish turn and resolve the pattern.',
              onPressed: onFinish,
            ),
          ),
        ),
      ],
    );
  }

  Color get _roundCornerColor {
    if (round >= 10) return EndpointPalette.dangerAccent;
    if (round >= 8) return const Color(0xFFFFEA70);
    return const Color(0xFF24242A);
  }

  Color get _roundCornerTextColor {
    if (round >= 8 && round < 10) return Colors.black;
    return Colors.white;
  }

  String get _roundCornerLabel {
    if (round >= 10) return 'Purga ${_purgeDamageForRound(round)}';
    if (round >= 8) return 'Purga ${10 - round}';
    return 'Round $round';
  }

  String get _roundCornerTooltip {
    if (round >= 10) {
      return 'Current combat round. Purga damage this round.';
    }
    if (round >= 8) {
      return 'Current combat round. Purga starts after this countdown.';
    }
    return 'Current combat round.';
  }

  int _purgeDamageForRound(int round) {
    if (round < 10) return 0;
    final purgeCount = round - 9;
    if (purgeCount <= 5) return purgeCount * 2;
    return 10 + ((purgeCount - 5) * 4);
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
