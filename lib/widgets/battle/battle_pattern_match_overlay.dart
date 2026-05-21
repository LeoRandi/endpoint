import '../_imports.dart';
import 'package:flutter/foundation.dart';
import '../../services/battler_effect_pipeline.dart';
import '../../services/battle_controller.dart';
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
const _battlePatternBlockTravelDuration = Duration(milliseconds: 1100);
const _enemyPatternBlockTravelDuration = Duration(milliseconds: 520);
const _enemyPatternPointStepDuration = Duration(milliseconds: 750);
const _battlePatternBlockMarkSize = 50.0;
const _enemyPatternBlockCount = 2;

enum BattlePatternBlockMode {
  randomOne,
  itemOne,
  randomTwo,
  randomAndItem,
  mostUsedItem,
  randomThree,
  itemTwo,
  randomAndMostUsed,
}

class BattlePatternMatchResult {
  final int attackBonus;
  final int barrierBonus;
  final Set<String> activatedItemPointKeys;
  final BattlePatternBlockMode blockMode;
  final BattlePatternMatchContext patternContext;

  const BattlePatternMatchResult({
    required this.attackBonus,
    required this.barrierBonus,
    required this.activatedItemPointKeys,
    required this.blockMode,
    required this.patternContext,
  });

  factory BattlePatternMatchResult.fromResolution(
    OperativePatternResolution resolution,
    BattlePatternBlockMode blockMode,
    BattlePatternMatchContext patternContext,
  ) {
    final activatedItemPointKeys = <String>{
      for (final entry in resolution.itemActivationByPointKey.entries)
        if (entry.value) entry.key,
      ...resolution.activatedAdjacencyBonusesByPointKey.keys,
    };

    return BattlePatternMatchResult(
      attackBonus: resolution.attackBonus,
      barrierBonus: resolution.barrierBonus,
      activatedItemPointKeys: Set<String>.unmodifiable(
        activatedItemPointKeys,
      ),
      blockMode: blockMode,
      patternContext: patternContext,
    );
  }

  bool get hasBonus => attackBonus > 0 || barrierBonus > 0;
}

class EnemyBattlePatternMatchResult {
  final int attackBonus;
  final int barrierBonus;
  final Set<String> activatedItemPointKeys;
  final BattlePatternMatchContext patternContext;

  const EnemyBattlePatternMatchResult({
    required this.attackBonus,
    required this.barrierBonus,
    required this.activatedItemPointKeys,
    required this.patternContext,
  });

  factory EnemyBattlePatternMatchResult.fromResolution(
    OperativePatternResolution resolution,
    BattlePatternMatchContext patternContext,
  ) {
    final activatedItemPointKeys = <String>{
      for (final entry in resolution.itemActivationByPointKey.entries)
        if (entry.value) entry.key,
      ...resolution.activatedAdjacencyBonusesByPointKey.keys,
    };

    return EnemyBattlePatternMatchResult(
      attackBonus: resolution.attackBonus,
      barrierBonus: resolution.barrierBonus,
      activatedItemPointKeys: Set<String>.unmodifiable(
        activatedItemPointKeys,
      ),
      patternContext: patternContext,
    );
  }
}

final Map<String, OperativePatternPoint> _battlePatternPointsByKey =
    Map<String, OperativePatternPoint>.unmodifiable({
  for (final point in operativePatternPoints) point.key: point,
});

class _BattlePatternBlockPlan {
  final BattlePatternBlockMode mode;
  final List<OperativePatternPoint> points;

  const _BattlePatternBlockPlan({
    required this.mode,
    required this.points,
  });

  Set<String> get pointKeys => Set<String>.unmodifiable(
        points.map((point) => point.key),
      );

  static _BattlePatternBlockPlan resolve({
    required int enemyTier,
    required int combatRound,
    required Map<String, Item> equippedItemsByPointKey,
    required Map<String, int> itemPointUseCounts,
    required BattlePatternBlockMode? previousYellowBlockMode,
    required int Function(int max) nextInt,
  }) {
    final mode = _modeFor(
      enemyTier: enemyTier,
      combatRound: combatRound,
      previousYellowBlockMode: previousYellowBlockMode,
      nextInt: nextInt,
    );
    final points = _pointsForMode(
      mode: mode,
      equippedItemsByPointKey: equippedItemsByPointKey,
      itemPointUseCounts: itemPointUseCounts,
      nextInt: nextInt,
    );

    return _BattlePatternBlockPlan(
      mode: mode,
      points: points.isEmpty
          ? _randomPoints(
              count: 1,
              excludedPointKeys: const <String>{},
              nextInt: nextInt,
            )
          : points,
    );
  }

  static BattlePatternBlockMode _modeFor({
    required int enemyTier,
    required int combatRound,
    required BattlePatternBlockMode? previousYellowBlockMode,
    required int Function(int max) nextInt,
  }) {
    final safeTier = max(1, enemyTier);
    final isOddRound = combatRound.isOdd;

    if (safeTier >= RarityTier.yellow.factor) {
      const yellowModes = <BattlePatternBlockMode>[
        BattlePatternBlockMode.randomThree,
        BattlePatternBlockMode.itemTwo,
        BattlePatternBlockMode.randomAndMostUsed,
      ];
      final availableModes = yellowModes
          .where((mode) => mode != previousYellowBlockMode)
          .toList(growable: false);
      final choices = availableModes.isEmpty ? yellowModes : availableModes;
      return choices[nextInt(choices.length)];
    }
    if (safeTier >= RarityTier.purple.factor) {
      return isOddRound
          ? BattlePatternBlockMode.randomAndItem
          : BattlePatternBlockMode.mostUsedItem;
    }
    if (safeTier >= RarityTier.blue.factor) {
      return isOddRound
          ? BattlePatternBlockMode.randomTwo
          : BattlePatternBlockMode.itemOne;
    }
    if (safeTier >= RarityTier.green.factor) {
      return isOddRound
          ? BattlePatternBlockMode.randomOne
          : BattlePatternBlockMode.itemOne;
    }

    return BattlePatternBlockMode.randomOne;
  }

  static List<OperativePatternPoint> _pointsForMode({
    required BattlePatternBlockMode mode,
    required Map<String, Item> equippedItemsByPointKey,
    required Map<String, int> itemPointUseCounts,
    required int Function(int max) nextInt,
  }) {
    final selected = <OperativePatternPoint>[];
    final selectedPointKeys = <String>{};

    void addPoint(OperativePatternPoint? point) {
      if (point == null || !selectedPointKeys.add(point.key)) return;
      selected.add(point);
    }

    void addRandomPoints(int count) {
      for (final point in _randomPoints(
        count: count,
        excludedPointKeys: selectedPointKeys,
        nextInt: nextInt,
      )) {
        addPoint(point);
      }
    }

    void addRandomItemPoints(int count) {
      final before = selected.length;
      for (final point in _randomItemPoints(
        count: count,
        equippedItemsByPointKey: equippedItemsByPointKey,
        excludedPointKeys: selectedPointKeys,
        nextInt: nextInt,
      )) {
        addPoint(point);
      }
      final added = selected.length - before;
      if (added < count) {
        addRandomPoints(count - added);
      }
    }

    switch (mode) {
      case BattlePatternBlockMode.randomOne:
        addRandomPoints(1);
        break;
      case BattlePatternBlockMode.itemOne:
        addRandomItemPoints(1);
        break;
      case BattlePatternBlockMode.randomTwo:
        addRandomPoints(2);
        break;
      case BattlePatternBlockMode.randomAndItem:
        addRandomItemPoints(1);
        addRandomPoints(1);
        break;
      case BattlePatternBlockMode.mostUsedItem:
        addPoint(
          _mostUsedItemPoint(
            equippedItemsByPointKey: equippedItemsByPointKey,
            itemPointUseCounts: itemPointUseCounts,
            nextInt: nextInt,
          ),
        );
        if (selected.isEmpty) addRandomPoints(1);
        break;
      case BattlePatternBlockMode.randomThree:
        addRandomPoints(3);
        break;
      case BattlePatternBlockMode.itemTwo:
        addRandomItemPoints(2);
        break;
      case BattlePatternBlockMode.randomAndMostUsed:
        final mostUsedPoint = _mostUsedItemPoint(
          equippedItemsByPointKey: equippedItemsByPointKey,
          itemPointUseCounts: itemPointUseCounts,
          nextInt: nextInt,
        );
        if (mostUsedPoint == null) {
          addRandomPoints(2);
        } else {
          addPoint(mostUsedPoint);
          addRandomPoints(1);
        }
        break;
    }

    return List<OperativePatternPoint>.unmodifiable(selected);
  }

  static OperativePatternPoint? _mostUsedItemPoint({
    required Map<String, Item> equippedItemsByPointKey,
    required Map<String, int> itemPointUseCounts,
    required int Function(int max) nextInt,
  }) {
    final candidates = equippedItemsByPointKey.entries
        .where((entry) => _battlePatternPointsByKey.containsKey(entry.key))
        .toList(growable: false);
    if (candidates.isEmpty) return null;

    final highestUseCount = candidates
        .map((entry) => max(0, itemPointUseCounts[entry.key] ?? 0))
        .reduce(max);
    final mostUsedCandidates = candidates
        .where(
          (entry) =>
              max(0, itemPointUseCounts[entry.key] ?? 0) == highestUseCount,
        )
        .toList(growable: false);
    final highestTier = mostUsedCandidates
        .map((entry) => entry.value.rarity.factor)
        .reduce(max);
    final highestTierCandidates = mostUsedCandidates
        .where((entry) => entry.value.rarity.factor == highestTier)
        .toList(growable: false);
    final selectedEntry =
        highestTierCandidates[nextInt(highestTierCandidates.length)];

    return _battlePatternPointsByKey[selectedEntry.key];
  }

  static List<OperativePatternPoint> _randomItemPoints({
    required int count,
    required Map<String, Item> equippedItemsByPointKey,
    required Set<String> excludedPointKeys,
    required int Function(int max) nextInt,
  }) {
    final candidates = <OperativePatternPoint>[
      for (final pointKey in equippedItemsByPointKey.keys)
        if (!excludedPointKeys.contains(pointKey) &&
            _battlePatternPointsByKey[pointKey] != null)
          _battlePatternPointsByKey[pointKey]!,
    ];

    return _takeRandom(
      candidates: candidates,
      count: count,
      nextInt: nextInt,
    );
  }

  static List<OperativePatternPoint> _randomPoints({
    required int count,
    required Set<String> excludedPointKeys,
    required int Function(int max) nextInt,
  }) {
    final candidates = <OperativePatternPoint>[
      for (final point in operativePatternPoints)
        if (!excludedPointKeys.contains(point.key)) point,
    ];

    return _takeRandom(
      candidates: candidates,
      count: count,
      nextInt: nextInt,
    );
  }

  static List<OperativePatternPoint> _takeRandom({
    required List<OperativePatternPoint> candidates,
    required int count,
    required int Function(int max) nextInt,
  }) {
    if (count <= 0 || candidates.isEmpty) {
      return const <OperativePatternPoint>[];
    }

    final pool = List<OperativePatternPoint>.from(candidates);
    final selected = <OperativePatternPoint>[];
    while (selected.length < count && pool.isNotEmpty) {
      selected.add(pool.removeAt(nextInt(pool.length)));
    }

    return List<OperativePatternPoint>.unmodifiable(selected);
  }
}

class BattlePatternMatchOverlay extends StatefulWidget {
  final Battler player;
  final Battler enemy;
  final Map<String, Item> equippedItemsByPointKey;
  final int enemyTier;
  final int combatRound;
  final List<PlayerActionEffectIntent> actionEffects;
  final Map<String, int> itemPointUseCounts;
  final BattlePatternBlockMode? previousYellowBlockMode;
  final int Function(int max)? randomNextInt;
  final Future<void> Function(BattlePatternMatchResult result)? onResolve;
  final ValueListenable<Widget?>? combatAnimationOverlay;
  final ValueListenable<BattlePatternVisualBattlers>? visualBattlers;
  final ValueChanged<BattlePatternAnimationTargets?>? onAnimationTargetsChanged;
  final ValueChanged<BattlerAbility>? onPlayerAbilityPressed;
  final ValueChanged<BattlerAbility>? onEnemyAbilityPressed;

  const BattlePatternMatchOverlay({
    super.key,
    required this.player,
    required this.enemy,
    required this.equippedItemsByPointKey,
    this.enemyTier = 1,
    this.combatRound = 1,
    this.actionEffects = const <PlayerActionEffectIntent>[],
    this.itemPointUseCounts = const <String, int>{},
    this.previousYellowBlockMode,
    this.randomNextInt,
    this.onResolve,
    this.combatAnimationOverlay,
    this.visualBattlers,
    this.onAnimationTargetsChanged,
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
  late final _BattlePatternBlockPlan _blockPlan;
  Timer? _blockStartTimer;
  List<Animation<Offset>> _blockMarkMotions = const <Animation<Offset>>[];
  List<OperativePatternPoint> _patternPoints = const <OperativePatternPoint>[];
  bool _blockAnimationStarted = false;
  bool _blockAnimationCompleted = false;
  bool _hasSubmitted = false;

  @override
  void initState() {
    super.initState();
    _blockMotionController = AnimationController(
      vsync: this,
      duration: _battlePatternBlockTravelDuration,
    )..addStatusListener(_handleBlockMotionStatus);
    final randomNextInt = widget.randomNextInt ?? Random().nextInt;
    _blockPlan = _BattlePatternBlockPlan.resolve(
      enemyTier: widget.enemyTier,
      combatRound: widget.combatRound,
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
    _scheduleBlockAnimationConfiguration();
  }

  @override
  void dispose() {
    _blockStartTimer?.cancel();
    _blockMotionController.dispose();
    widget.onAnimationTargetsChanged?.call(null);
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

    setState(() {
      _blockAnimationCompleted = true;
    });
  }

  OperativePatternResolution get _currentResolution {
    return OperativePatternResolutionService.resolve(
      patternPoints: _patternPoints,
      equippedItemsByPointKey: widget.equippedItemsByPointKey,
      bonusesByPointKey: _bonusesByPointKey,
      adaptationMaxEmptyItemBonus: _adaptationBonusCap(),
      shouldDilutePositiveBonuses: widget.player.hasBonusDilution,
      blockedPointKeys:
          _blockAnimationCompleted ? _blockPlan.pointKeys : const <String>{},
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
      );

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
    unawaited(_openPointItemDetails(item));
  }

  Future<void> _openPointItemDetails(Item item) async {
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
  }

  Future<void> _submit() async {
    if (_hasSubmitted || !_blockAnimationCompleted) return;
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
    );
    final baseHitDamage = _estimatedHitDamageFor(0);
    final totalDamageLabel = _estimatedTotalDamageLabelFor(result.attackBonus);
    final blockedPointKeys =
        _blockAnimationCompleted ? _blockPlan.pointKeys : const <String>{};
    final isBoardDimmed = !_blockAnimationCompleted;

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
          effects: widget.actionEffects,
          pointCount: resolution.distinctPointCount,
        ),
        pointCount: resolution.distinctPointCount,
        maxPointCount: _maxPatternPoints,
        blockingCount: 3,
        maxBlockingCount: 3,
        round: widget.combatRound,
        finishEnabled: _blockAnimationCompleted,
        onFinish: _submit,
        dimPatternPoints: isBoardDimmed,
        dimBlockPoints: isBoardDimmed,
        dimFinishButton: isBoardDimmed,
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
                          maxPatternPoints: _maxPatternPoints,
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
  final int combatRound;
  final int Function(int max)? randomNextInt;
  final Future<void> Function(EnemyBattlePatternMatchResult result)? onResolve;
  final ValueListenable<Widget?>? combatAnimationOverlay;
  final ValueListenable<BattlePatternVisualBattlers>? visualBattlers;
  final ValueChanged<BattlePatternAnimationTargets?>? onAnimationTargetsChanged;
  final ValueChanged<BattlerAbility>? onPlayerAbilityPressed;
  final ValueChanged<BattlerAbility>? onEnemyAbilityPressed;

  const EnemyBattlePatternMatchOverlay({
    super.key,
    required this.player,
    required this.enemy,
    required this.equippedItemsByPointKey,
    this.combatRound = 1,
    this.randomNextInt,
    this.onResolve,
    this.combatAnimationOverlay,
    this.visualBattlers,
    this.onAnimationTargetsChanged,
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
  late final AnimationController _blockMotionController;
  late final Map<String, OperativePatternBonus> _bonusesByPointKey;
  late final int _maxPatternPoints;
  late final int Function(int max) _nextInt;
  Animation<Offset>? _activeBlockMotion;
  List<OperativePatternPoint> _blockedPoints = const <OperativePatternPoint>[];
  List<OperativePatternPoint> _displayedEnemyPatternPoints =
      const <OperativePatternPoint>[];
  bool _isAnimatingBlock = false;
  bool _isPlayingEnemyPattern = false;
  bool _hasSubmitted = false;

  @override
  void initState() {
    super.initState();
    _nextInt = widget.randomNextInt ?? Random().nextInt;
    _blockMotionController = AnimationController(
      vsync: this,
      duration: _enemyPatternBlockTravelDuration,
    );
    _bonusesByPointKey = buildOperativePatternBonusesByPointKey(
      playerLevel: widget.enemy.level,
      occupiedPointKeys: widget.equippedItemsByPointKey.keys,
      nextInt: _nextInt,
    );
    _maxPatternPoints = OperativePatternCombatRules.maxPatternPointsFor(
      widget.enemy,
    );
  }

  @override
  void dispose() {
    _blockMotionController.dispose();
    widget.onAnimationTargetsChanged?.call(null);
    super.dispose();
  }

  Set<String> get _blockedPointKeys => Set<String>.unmodifiable(
        _blockedPoints.map((point) => point.key),
      );

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
      );

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

  Future<void> _handleEnemyPointTapped(OperativePatternPoint point) async {
    if (_isAnimatingBlock ||
        _isPlayingEnemyPattern ||
        _blockedPointKeys.contains(point.key) ||
        _blockedPoints.length >= _enemyPatternBlockCount) {
      return;
    }

    final start = _localCenterFor(_playerSpriteKey);
    final end = _localEnemyPatternPointCenter(point);
    if (start == null || end == null) return;

    _blockMotionController.stop();
    _blockMotionController.reset();
    setState(() {
      _isAnimatingBlock = true;
      _activeBlockMotion = Tween<Offset>(
        begin: start,
        end: end,
      ).animate(
        CurvedAnimation(
          parent: _blockMotionController,
          curve: Curves.easeInOutCubic,
        ),
      );
    });

    try {
      await _blockMotionController.forward(from: 0).orCancel;
    } on TickerCanceled {
      return;
    }
    if (!mounted) return;

    setState(() {
      _blockedPoints = List<OperativePatternPoint>.unmodifiable([
        ..._blockedPoints,
        point,
      ]);
      _isAnimatingBlock = false;
      _activeBlockMotion = null;
    });

    if (_blockedPoints.length >= _enemyPatternBlockCount && mounted) {
      setState(() {});
    }
  }

  Future<void> _playEnemyPattern() async {
    if (_isPlayingEnemyPattern || _hasSubmitted) return;

    final pattern = _buildEnemyPattern();
    setState(() {
      _isPlayingEnemyPattern = true;
      _displayedEnemyPatternPoints = const <OperativePatternPoint>[];
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

  List<OperativePatternPoint> _buildEnemyPattern() {
    final blockedKeys = _blockedPointKeys;
    final maxDistinctPoints = max(3, _maxPatternPoints);
    final selected = <OperativePatternPoint>[];
    final selectedKeys = <String>{};

    void addPoint(OperativePatternPoint? point) {
      if (point == null) return;
      if (blockedKeys.contains(point.key) || !selectedKeys.add(point.key)) {
        return;
      }
      selected.add(point);
    }

    final itemPoints = <OperativePatternPoint>[
      for (final point in operativePatternPoints)
        if (widget.equippedItemsByPointKey.containsKey(point.key) &&
            !blockedKeys.contains(point.key))
          point,
    ];
    itemPoints.sort((a, b) {
      final aItem = widget.equippedItemsByPointKey[a.key];
      final bItem = widget.equippedItemsByPointKey[b.key];
      final aScore = _enemyPointPriority(aItem);
      final bScore = _enemyPointPriority(bItem);
      return bScore.compareTo(aScore);
    });

    for (final point in itemPoints) {
      if (selected.length >= maxDistinctPoints) break;
      addPoint(point);
    }

    final filler = <OperativePatternPoint>[
      for (final point in operativePatternPoints)
        if (!blockedKeys.contains(point.key) &&
            !selectedKeys.contains(point.key))
          point,
    ];
    while (selected.length < min(3, maxDistinctPoints) && filler.isNotEmpty) {
      final index = _nextInt(filler.length);
      addPoint(filler.removeAt(index));
    }

    if (selected.length < 3) {
      return List<OperativePatternPoint>.unmodifiable(selected);
    }

    return List<OperativePatternPoint>.unmodifiable([
      ...selected,
      selected.first,
    ]);
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

  Offset? _localEnemyPatternPointCenter(OperativePatternPoint point) {
    final stackRenderObject = _matchStackKey.currentContext?.findRenderObject();
    final boardRenderObject =
        _enemyPatternBoardKey.currentContext?.findRenderObject();
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
    final activeBlockMotion = _activeBlockMotion;
    final baseHitDamage = _estimatedHitDamageFor(0);
    final totalDamageLabel = _estimatedTotalDamageLabelFor(result.attackBonus);
    final waitingForBlocks = _blockedPoints.length < _enemyPatternBlockCount &&
        !_isPlayingEnemyPattern;

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
          effects: const <PlayerActionEffectIntent>[],
          pointCount: resolution.distinctPointCount,
        ),
        pointCount: resolution.distinctPointCount,
        maxPointCount: _maxPatternPoints,
        blockingCount: max(0, _enemyPatternBlockCount - _blockedPoints.length),
        maxBlockingCount: _enemyPatternBlockCount,
        round: widget.combatRound,
        finishEnabled: !waitingForBlocks && !_isPlayingEnemyPattern,
        onFinish: _playEnemyPattern,
        dimPatternPoints: true,
        dimBlockPoints: false,
        dimFinishButton: waitingForBlocks || _isPlayingEnemyPattern,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: FractionallySizedBox(
                  widthFactor: 0.79,
                  heightFactor: 0.79,
                  child: Transform.rotate(
                    angle: pi / 4,
                    child: OperativePatternBoard(
                      key: _enemyPatternBoardKey,
                      contentsByPointKey: _buildContentsByPointKey(resolution),
                      blockedPointKeys: _blockedPointKeys,
                      displayedPatternPoints: _displayedEnemyPatternPoints,
                      keepLineAfterPointerUp: true,
                      maxPatternPoints: _maxPatternPoints,
                      accent: EndpointPalette.dangerAccent,
                      onPointTapped:
                          waitingForBlocks ? _handleEnemyPointTapped : null,
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
      overlay: activeBlockMotion == null
          ? null
          : _BattlePatternBlockMotion(animation: activeBlockMotion),
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
  final List<PlayerActionEffectIntent> effects;
  final int pointCount;

  const _BattlePatternLiveSummary({
    required this.baseHitDamage,
    required this.totalDamageLabel,
    required this.attackBonus,
    required this.barrierBonus,
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
      height: 70,
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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: EndpointPalette.panelBackgroundBattleOpaque,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withAlpha(132)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        child: Column(
          crossAxisAlignment:
              alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
  final ValueChanged<BattlerAbility>? onAbilityPressed;

  const _PatternAugmentStrip({
    required this.abilities,
    required this.accent,
    this.alignEnd = false,
    this.onAbilityPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final row = Row(
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
          );

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: alignEnd,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Align(
                alignment:
                    alignEnd ? Alignment.centerRight : Alignment.centerLeft,
                child: row,
              ),
            ),
          );
        },
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
  final Color accent;
  final Color entryAccent;
  final Widget summary;
  final Widget child;
  final int pointCount;
  final int maxPointCount;
  final int blockingCount;
  final int maxBlockingCount;
  final int round;
  final bool finishEnabled;
  final bool dimPatternPoints;
  final bool dimBlockPoints;
  final bool dimFinishButton;
  final VoidCallback onFinish;

  const _PatternMatrixCard({
    required this.accent,
    required this.entryAccent,
    required this.summary,
    required this.child,
    required this.pointCount,
    required this.maxPointCount,
    required this.blockingCount,
    required this.maxBlockingCount,
    required this.round,
    required this.finishEnabled,
    required this.dimPatternPoints,
    required this.dimBlockPoints,
    required this.dimFinishButton,
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
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Tooltip(
                          message: 'Pattern matrix: connect points to form a match.',
                          child: child,
                        ),
                      ),
                      Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: _PatternCornerTriangle(
                            alignment: Alignment.topLeft,
                            color: const Color(0xFFFFEA4D),
                            label: '$pointCount/$maxPointCount',
                            tooltip:
                                'Pattern points used and available this turn.',
                            textColor: Colors.black,
                            isDimmed: dimPatternPoints,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: _PatternCornerTriangle(
                            alignment: Alignment.topRight,
                            color: const Color(0xFFB05CFF),
                            label: '$blockingCount/$maxBlockingCount',
                            tooltip:
                                'Blocking points available to stop enemy pattern points.',
                            isDimmed: dimBlockPoints,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: _PatternCornerTriangle(
                            alignment: Alignment.bottomLeft,
                            color: const Color(0xFF24242A),
                            label: 'Round $round',
                            tooltip: 'Current combat round.',
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
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

  const _PatternCornerTriangle({
    required this.alignment,
    required this.color,
    required this.label,
    required this.tooltip,
    this.textColor = Colors.white,
    this.isDimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        opacity: isDimmed ? 0.38 : 1,
        child: SizedBox(
          width: 100,
          height: 100,
          child: CustomPaint(
            painter: _PatternTrianglePainter(
              alignment: alignment,
              color: color.withAlpha(222),
            ),
            child: Align(
              alignment: alignment,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Transform.rotate(
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
                ),
              ),
            ),
          ),
        ),
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

class _PatternTrianglePainter extends CustomPainter {
  final Alignment alignment;
  final Color color;

  const _PatternTrianglePainter({
    required this.alignment,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
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
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _PatternTrianglePainter oldDelegate) {
    return oldDelegate.alignment != alignment || oldDelegate.color != color;
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
