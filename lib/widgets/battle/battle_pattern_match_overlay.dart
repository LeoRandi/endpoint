import '../_imports.dart';
import '../../services/battler_effect_pipeline.dart';
import '../../services/battle_controller.dart';
import '../../services/operative_pattern_bonus_service.dart';
import '../../services/operative_pattern_combat_rules.dart';
import '../../services/operative_pattern_resolution_service.dart';

const _battlePatternEnemyTravel = 42.0;
const _battlePatternEnemySize = 112.0;
const _battlePatternBlockStartDelay = Duration(milliseconds: 500);
const _battlePatternBlockTravelDuration = Duration(milliseconds: 1100);
const _battlePatternBlockMarkSize = 50.0;
const _battlePatternBoardScale = 0.66;

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
    _enemyMotionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
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

  void _submit() {
    if (_hasSubmitted || !_blockAnimationCompleted) return;
    _hasSubmitted = true;
    Navigator.of(context).pop(_currentResult);
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
    final isClosed = resolution.isClosed;
    final blockedPointKeys =
        _blockAnimationCompleted ? _blockPlan.pointKeys : const <String>{};
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
                      SizedBox(
                        height: 118,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _BattlePatternEnemyStage(
                              enemy: widget.enemy,
                              animation: _enemyMotionController,
                              enemySpriteKey: _enemySpriteKey,
                            ),
                            _BattlePatternFocusDimmer(
                              isVisible: isEnemyDimmed,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _BattlePatternLiveSummary(
                        baseHitDamage: baseHitDamage,
                        totalDamageLabel: totalDamageLabel,
                        attackBonus: result.attackBonus,
                        barrierBonus: result.barrierBonus,
                        effects: widget.actionEffects,
                        pointCount: resolution.distinctPointCount,
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
                                  widthFactor: _battlePatternBoardScale,
                                  heightFactor: _battlePatternBoardScale,
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
                        pointCount: resolution.distinctPointCount,
                        maxPointCount: _maxPatternPoints,
                        onPressed: _blockAnimationCompleted ? _submit : null,
                      ),
                    ],
                  ),
                  if (!_blockAnimationCompleted)
                    for (final animation in _blockMarkMotions)
                      _BattlePatternBlockMotion(
                        animation: animation,
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

  const _BattlePatternEnemyStage({
    required this.enemy,
    required this.animation,
    required this.enemySpriteKey,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
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
  final int pointCount;
  final int maxPointCount;
  final VoidCallback? onPressed;

  const _BattlePatternMatchFooter({
    required this.isClosed,
    required this.pointCount,
    required this.maxPointCount,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _BattlePatternPointLimitPill(
          pointCount: pointCount,
          maxPointCount: maxPointCount,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: EndpointActionButton(
            label: isClosed ? 'MATCHED' : 'MATCH',
            icon: Icons.join_inner_rounded,
            onPressed: onPressed,
            tooltip: isClosed ? 'Resolver patron' : 'Cerrar sin patron cerrado',
            height: 46,
            useMarquee: false,
            backgroundColor: EndpointPalette.controlBackground,
            foregroundColor: EndpointPalette.softForeground,
            accent: isClosed
                ? EndpointPalette.patternAccent
                : EndpointPalette.neutralAccent,
            textStyle: textSmallBold.copyWith(letterSpacing: 1),
          ),
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
