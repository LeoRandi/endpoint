import '_imports.dart';

class PathNodeService {
  static const startStageIndex = 0;
  static const firstPlayableStageIndex = 1;
  static const stagesPerDay = 12;
  static const maxDayNumber = 5;
  static const dayStageCount = 5;
  static const duskStageOffset = 5;
  static const nightFirstStageOffset = 6;
  static const dailyBossStageOffset = stagesPerDay - 1;
  static const duskStageIndex = firstPlayableStageIndex + duskStageOffset;
  static const firstDayBossStageIndex =
      firstPlayableStageIndex + dailyBossStageOffset;
  static const sunriseStageIndex = firstPlayableStageIndex +
      ((maxDayNumber - 1) * stagesPerDay) +
      dailyBossStageOffset;
  static const _openingArchetypeCount = 3;
  static const _centerShopPremiumChance = 0.78;
  static const _centerShopPremiumMultiplier = 1.2;
  static const _dayEventRelativeWeight = 0.82;
  static const _nightEventRelativeWeight = 0.5;
  static const _dayCombatRelativeWeight = 0.72;
  static const _nightCombatRelativeWeight = 1.45;

  final RunRandomizer _randomizer;
  final PathEventService _pathEventService;
  final WeaponShopStockService _shopStockService;
  late final List<ShopPathNode> _allShopNodes = _deduplicateShopNodes([
    ...dayShopNodes,
    ...nightShopNodes,
  ]);
  late final Set<String> _dayShopNodeIds =
      dayShopNodes.map((node) => node.nodeId).toSet();
  late final Set<String> _nightShopNodeIds =
      nightShopNodes.map((node) => node.nodeId).toSet();
  late final _WeightedPathNode _restZoneCandidate = _WeightedPathNode(
    node: restZoneCampNode,
    weight: restZoneCampNode.rollWeight,
  );
  late final _WeightedPathNode _severeMedicationCandidate = _WeightedPathNode(
    node: severeMedicationCampNode,
    weight: severeMedicationCampNode.rollWeight,
  );

  PathNodeService({
    required RunRandomizer randomizer,
    PathEventService pathEventService = const PathEventService(),
    WeaponShopStockService shopStockService = const WeaponShopStockService(),
  })  : _randomizer = randomizer,
        _pathEventService = pathEventService,
        _shopStockService = shopStockService;

  RunRandomizer get randomizer => _randomizer;

  static int dayNumberForStageIndex(int stageIndex) {
    if (stageIndex <= startStageIndex) return 1;

    return (((stageIndex - firstPlayableStageIndex) ~/ stagesPerDay) + 1)
        .clamp(1, maxDayNumber)
        .toInt();
  }

  static int stageOffsetInDayForStageIndex(int stageIndex) {
    if (stageIndex <= startStageIndex) return -1;

    return (stageIndex - firstPlayableStageIndex) % stagesPerDay;
  }

  static int firstStageIndexForDay(int dayNumber) {
    final clampedDay = dayNumber.clamp(1, maxDayNumber).toInt();
    return firstPlayableStageIndex + ((clampedDay - 1) * stagesPerDay);
  }

  static int bossStageIndexForDay(int dayNumber) {
    return firstStageIndexForDay(dayNumber) + dailyBossStageOffset;
  }

  static bool isDuskStage(int stageIndex) {
    return stageOffsetInDayForStageIndex(stageIndex) == duskStageOffset;
  }

  static bool isDailyBossStage(int stageIndex) {
    return stageOffsetInDayForStageIndex(stageIndex) == dailyBossStageOffset;
  }

  static bool isFinalBossStage(int stageIndex) {
    return stageIndex == sunriseStageIndex;
  }

  static bool isFinalRunStage(int stageIndex) {
    return isFinalBossStage(stageIndex);
  }

  static double progressWithinDayForStageIndex(int stageIndex) {
    if (stageIndex <= startStageIndex) return 0;

    return (stageOffsetInDayForStageIndex(stageIndex) / dailyBossStageOffset)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  RunHourSnapshot buildHourSnapshot({
    required int stageIndex,
    Battler? player,
    List<PathNode>? availableNodes,
    Iterable<String> shownShopNodeIds = const <String>[],
    int nodeCount = 3,
  }) {
    final clampedStageIndex = stageIndex
        .clamp(
          startStageIndex,
          sunriseStageIndex,
        )
        .toInt();
    final resolvedNodeCount = max(1, nodeCount);
    final definition = _definitionFor(
      clampedStageIndex,
      player,
      shownShopNodeIds: shownShopNodeIds,
    );

    final resolvedNodes = _resolveNodes(
      fallbackNodes: definition.nodes,
      availableNodes: availableNodes,
      nodeCount: resolvedNodeCount,
      player: player,
      phase: definition.phase,
      dayNumber: dayNumberForStageIndex(clampedStageIndex),
    );

    return RunHourSnapshot(
      stageIndex: clampedStageIndex,
      phase: definition.phase,
      title: definition.title,
      subtitle: definition.subtitle,
      nodes: List<PathNode>.unmodifiable(
        clampedStageIndex == startStageIndex
            ? _materializeOpeningArchetypeNodes(resolvedNodes)
            : resolvedNodes,
      ),
    );
  }

  RunHourSnapshot buildSuddenConventionSnapshot({
    required int stageIndex,
    Battler? player,
    int nodeCount = 3,
  }) {
    final clampedStageIndex = stageIndex
        .clamp(
          startStageIndex,
          sunriseStageIndex,
        )
        .toInt();
    final definition = _definitionFor(clampedStageIndex, player);
    final nodes = _buildSuddenConventionShopNodes(
      player,
      phase: definition.phase,
      dayNumber: dayNumberForStageIndex(clampedStageIndex),
    ).take(max(1, nodeCount)).toList(growable: false);

    return RunHourSnapshot(
      stageIndex: clampedStageIndex,
      phase: definition.phase,
      title: definition.title,
      subtitle: definition.subtitle,
      nodes: List<PathNode>.unmodifiable(nodes),
    );
  }

  _RunStageDefinition _definitionFor(
    int stageIndex,
    Battler? player, {
    Iterable<String> shownShopNodeIds = const <String>[],
  }) {
    if (stageIndex == startStageIndex) {
      return _RunStageDefinition(
        phase: RunHourPhase.day,
        title: 'DIA 1 - ARQUETIPO',
        subtitle: 'Elige el arquetipo con el que abrira la run.',
        nodes: _buildOpeningArchetypeNodes(),
      );
    }

    final dayNumber = dayNumberForStageIndex(stageIndex);
    final stageOffset = stageOffsetInDayForStageIndex(stageIndex);
    if (stageOffset < duskStageOffset) {
      return _RunStageDefinition(
        phase: RunHourPhase.day,
        title: 'DIA $dayNumber - HORA ${stageOffset + 1}',
        subtitle: 'Mercados, eventos y amenazas antes del anochecer.',
        nodes: _buildDayNodes(
          dayNumber,
          player,
          shownShopNodeIds: shownShopNodeIds,
        ),
      );
    }

    if (stageOffset == duskStageOffset) {
      return _RunStageDefinition(
        phase: RunHourPhase.dusk,
        title: 'DIA $dayNumber - ANOCHECER',
        subtitle:
            'La ciudad se cierra. Tres enfrentamientos marcan la entrada en la noche.',
        nodes: _buildDuskCombatNodes(dayNumber),
      );
    }

    if (stageOffset < dailyBossStageOffset) {
      return _RunStageDefinition(
        phase: RunHourPhase.night,
        title: 'DIA $dayNumber - NOCHE ${stageOffset - duskStageOffset}',
        subtitle: 'Mas violencia, peores tratos y menos margen de error.',
        nodes: _buildNightNodes(
          dayNumber,
          player,
          shownShopNodeIds: shownShopNodeIds,
        ),
      );
    }

    return _RunStageDefinition(
      phase: RunHourPhase.sunrise,
      title: dayNumber == maxDayNumber
          ? 'DIA $dayNumber - BOSS FINAL'
          : 'DIA $dayNumber - BOSS',
      subtitle: dayNumber == maxDayNumber
          ? 'El combate amarillo decide si la run termina en victoria.'
          : 'Derrota al boss del dia para llegar al siguiente amanecer.',
      nodes: _buildDailyBossNodes(dayNumber),
    );
  }

  List<PathNode> _buildOpeningArchetypeNodes() {
    return _randomizer.pickDistinct(
      openingArchetypeNodes,
      _openingArchetypeCount,
    );
  }

  List<PathNode> _materializeOpeningArchetypeNodes(List<PathNode> nodes) {
    return nodes
        .map(
          (node) => node is ArchetypePathNode
              ? node.materializeRunStartingItems(_randomizer)
              : node,
        )
        .toList(growable: false);
  }

  List<PathNode> _buildDayNodes(
    int dayNumber,
    Battler? player, {
    Iterable<String> shownShopNodeIds = const <String>[],
  }) {
    final shopCandidates = _weightedShopCandidatesFor(
      dayNumber: dayNumber,
      phase: RunHourPhase.day,
      player: player,
      shownShopNodeIds: shownShopNodeIds,
    );

    return _buildUniqueHourNodes(
      sideCandidates: _buildSideCandidates(
        dayNumber: dayNumber,
        phase: RunHourPhase.day,
        player: player,
        shopCandidates: shopCandidates,
      ),
      shopCandidates: shopCandidates,
    );
  }

  List<PathNode> _buildNightNodes(
    int dayNumber,
    Battler? player, {
    Iterable<String> shownShopNodeIds = const <String>[],
  }) {
    final shopCandidates = _weightedShopCandidatesFor(
      dayNumber: dayNumber,
      phase: RunHourPhase.night,
      player: player,
      shownShopNodeIds: shownShopNodeIds,
    );

    return _buildUniqueHourNodes(
      sideCandidates: _buildSideCandidates(
        dayNumber: dayNumber,
        phase: RunHourPhase.night,
        player: player,
        shopCandidates: shopCandidates,
      ),
      shopCandidates: shopCandidates,
    );
  }

  List<PathNode> _buildDuskCombatNodes(int dayNumber) {
    final tiers = switch (dayNumber) {
      1 => const [
          CombatNodeTier.gray,
          CombatNodeTier.gray,
          CombatNodeTier.green,
        ],
      2 => const [
          CombatNodeTier.gray,
          CombatNodeTier.green,
          CombatNodeTier.blue,
        ],
      3 => const [
          CombatNodeTier.green,
          CombatNodeTier.blue,
          CombatNodeTier.purple,
        ],
      4 => const [
          CombatNodeTier.blue,
          CombatNodeTier.blue,
          CombatNodeTier.purple,
        ],
      _ => const [
          CombatNodeTier.purple,
          CombatNodeTier.purple,
          CombatNodeTier.purple,
        ],
    };

    return _pickCombatNodesForTiers(tiers);
  }

  List<PathNode> _buildDailyBossNodes(int dayNumber) {
    final tier = switch (dayNumber) {
      1 || 2 => CombatNodeTier.blue,
      3 || 4 => CombatNodeTier.purple,
      _ => CombatNodeTier.yellow,
    };

    return [
      _pickCombatNodeFromTier(tier),
    ];
  }

  List<PathNode> _resolveNodes({
    required List<PathNode> fallbackNodes,
    required int nodeCount,
    required RunHourPhase phase,
    required int dayNumber,
    Battler? player,
    List<PathNode>? availableNodes,
  }) {
    final sourceNodes = availableNodes == null || availableNodes.isEmpty
        ? fallbackNodes
        : availableNodes;
    final resolvedNodes = sourceNodes
        .where(
          (node) => _canAppearForPlayer(
            node,
            player,
            phase: phase,
            dayNumber: dayNumber,
          ),
        )
        .toList(growable: false);

    final limitedNodes = _limitShopNodes(
      resolvedNodes,
      nodeCount: min(nodeCount, resolvedNodes.length),
    );
    return _scaleCombatNodesForDay(limitedNodes, dayNumber: dayNumber);
  }

  Set<String> eligibleShopNodeIdsFor({
    required int stageIndex,
    required Battler? player,
  }) {
    final dayNumber = dayNumberForStageIndex(stageIndex);
    final stageOffset = stageOffsetInDayForStageIndex(stageIndex);
    final phase = stageOffset < duskStageOffset
        ? RunHourPhase.day
        : stageOffset == duskStageOffset
            ? RunHourPhase.dusk
            : stageOffset < dailyBossStageOffset
                ? RunHourPhase.night
                : RunHourPhase.sunrise;
    if (phase == RunHourPhase.sunrise || phase == RunHourPhase.dusk) {
      return const <String>{};
    }

    return _baseWeightedShopCandidatesFor(
      dayNumber: dayNumber,
      phase: phase,
      player: player,
    ).map((candidate) => candidate.node.nodeId).toSet();
  }

  List<_WeightedPathNode> _buildSideCandidates({
    required int dayNumber,
    required RunHourPhase phase,
    required Battler? player,
    required List<_WeightedPathNode> shopCandidates,
  }) {
    final shopTotalWeight = _totalWeight(shopCandidates);
    final eventRelativeWeight = phase == RunHourPhase.day
        ? _dayEventRelativeWeight
        : _nightEventRelativeWeight;
    final combatRelativeWeight = phase == RunHourPhase.day
        ? _dayCombatRelativeWeight
        : _nightCombatRelativeWeight;
    final eventPool =
        phase == RunHourPhase.day ? dayEventNodes : nightEventNodes;
    final eventCandidates = _scaleWeightedNodes(
      _weightedEventCandidatesFor(
        dayNumber: dayNumber,
        nodes: _filterEventNodes(eventPool, player),
      ),
      targetTotalWeight: shopTotalWeight * eventRelativeWeight,
    );
    final combatCandidates = _scaleWeightedNodes(
      _buildCombatCandidates(
        phase == RunHourPhase.day
            ? _dayCombatTierWeights(dayNumber)
            : _nightCombatTierWeights(dayNumber),
      ),
      targetTotalWeight: shopTotalWeight * combatRelativeWeight,
    );

    return [
      ...combatCandidates,
      ...shopCandidates,
      ...eventCandidates,
      ..._campCandidatesForDay(dayNumber),
    ];
  }

  Iterable<EventPathNode> _filterEventNodes(
    Iterable<EventPathNode> nodes,
    Battler? player,
  ) {
    return nodes.where(
      (node) => _pathEventService.canAppear(
        node: node,
        player: player,
      ),
    );
  }

  bool _canAppearForPlayer(
    PathNode node,
    Battler? player, {
    required RunHourPhase phase,
    required int dayNumber,
  }) {
    if (node is ShopPathNode) {
      return _canShopAppearForPlayer(
        node,
        player,
        phase: phase,
        dayNumber: dayNumber,
      );
    }
    if (node is! EventPathNode) return true;

    return _pathEventService.canAppear(
      node: node,
      player: player,
    );
  }

  List<ShopPathNode> _buildSuddenConventionShopNodes(
    Battler? player, {
    required RunHourPhase phase,
    required int dayNumber,
  }) {
    const tiers = [
      RarityTier.blue,
      RarityTier.purple,
      RarityTier.yellow,
    ];
    final selectedNodes = <ShopPathNode>[];
    final selectedNodeIds = <String>{};

    for (final tier in tiers) {
      var candidates = _shopCandidatesForTier(
        tier,
        player: player,
        phase: phase,
        dayNumber: dayNumber,
        excludedNodeIds: selectedNodeIds,
      );
      if (candidates.isEmpty) {
        candidates = _shopCandidatesForTier(
          tier,
          player: null,
          phase: phase,
          dayNumber: dayNumber,
          excludedNodeIds: selectedNodeIds,
        );
      }
      if (candidates.isEmpty) continue;

      final selected = candidates[_randomizer.nextInt(candidates.length)];
      selectedNodes.add(selected);
      selectedNodeIds.add(selected.nodeId);
    }

    return List<ShopPathNode>.unmodifiable(selectedNodes);
  }

  List<ShopPathNode> _shopCandidatesForTier(
    RarityTier tier, {
    required Battler? player,
    required RunHourPhase phase,
    required int dayNumber,
    required Set<String> excludedNodeIds,
  }) {
    return _allShopNodes
        .where(
          (node) =>
              node.rarity == tier &&
              !excludedNodeIds.contains(node.nodeId) &&
              _canShopAppearForPlayer(
                node,
                player,
                phase: phase,
                dayNumber: dayNumber,
              ),
        )
        .toList(growable: false);
  }

  List<PathNode> _buildUniqueHourNodes({
    required List<_WeightedPathNode> sideCandidates,
    required List<_WeightedPathNode> shopCandidates,
  }) {
    final nonShopSideCandidates = sideCandidates
        .where((candidate) => candidate.node is! ShopPathNode)
        .toList(growable: false);
    if (shopCandidates.isEmpty) {
      return _pickDistinctWeightedNodes(
        nonShopSideCandidates,
        count: 3,
      );
    }

    final centerNode = _buildCenterShopNode(shopCandidates);
    final sideNodes = _pickDistinctWeightedNodes(
      nonShopSideCandidates,
      count: 2,
      excludedKeys: {_nodeKey(centerNode)},
    );

    if (sideNodes.length < 2) {
      return [
        ...sideNodes,
        centerNode,
      ];
    }

    return [
      sideNodes.first,
      centerNode,
      sideNodes.last,
    ];
  }

  ShopPathNode _buildCenterShopNode(List<_WeightedPathNode> shopCandidates) {
    final baseNode = _pickWeightedNode(
      shopCandidates,
    ) as ShopPathNode;

    final shouldApplyPremium = _randomizer.chance(_centerShopPremiumChance);
    if (!shouldApplyPremium) return baseNode;

    return baseNode.withPriceMultiplier(_centerShopPremiumMultiplier);
  }

  List<_WeightedPathNode> _weightedShopCandidatesFor({
    required int dayNumber,
    required RunHourPhase phase,
    Battler? player,
    Iterable<String> shownShopNodeIds = const <String>[],
  }) {
    final candidates = _baseWeightedShopCandidatesFor(
      dayNumber: dayNumber,
      phase: phase,
      player: player,
    );
    final shownIds = shownShopNodeIds.toSet();
    if (shownIds.isEmpty) return candidates;

    final unshownCandidates = candidates
        .where((candidate) => !shownIds.contains(candidate.node.nodeId))
        .toList(growable: false);
    return unshownCandidates.isEmpty ? candidates : unshownCandidates;
  }

  List<_WeightedPathNode> _baseWeightedShopCandidatesFor({
    required int dayNumber,
    required RunHourPhase phase,
    Battler? player,
  }) {
    return _allShopNodes
        .where(
          (node) => _canShopAppearForPlayer(
            node,
            player,
            phase: phase,
            dayNumber: dayNumber,
          ),
        )
        .map(
          (node) => _WeightedPathNode(
            node: node,
            weight: node.rollWeight *
                _rarityProgressionWeight(dayNumber, node.rarity) *
                _shopPhaseAffinity(node, phase),
          ),
        )
        .toList(growable: false);
  }

  bool _canShopAppearForPlayer(
    ShopPathNode node,
    Battler? player, {
    required RunHourPhase phase,
    required int dayNumber,
  }) {
    return node.canAppearForArchetype(player?.archetypeId) &&
        _shopStockService.hasAvailableStock(
          criterion: node.stockCriterion,
          phase: phase,
          player: player,
          dayNumber: dayNumber,
        );
  }

  double _shopPhaseAffinity(ShopPathNode node, RunHourPhase phase) {
    final isDayShop = _dayShopNodeIds.contains(node.nodeId);
    final isNightShop = _nightShopNodeIds.contains(node.nodeId);
    if (phase == RunHourPhase.day) {
      return isDayShop ? 1.2 : 0.52;
    }

    return isNightShop ? 1.2 : 0.52;
  }

  List<_WeightedPathNode> _weightedEventCandidatesFor({
    required int dayNumber,
    required Iterable<EventPathNode> nodes,
  }) {
    return nodes
        .map(
          (node) => _WeightedPathNode(
            node: node,
            weight: node.rollWeight *
                _rarityProgressionWeight(dayNumber, node.rarity),
          ),
        )
        .toList(growable: false);
  }

  List<_WeightedPathNode> _buildCombatCandidates(
    Map<CombatNodeTier, double> tierWeights,
  ) {
    final candidates = <_WeightedPathNode>[];
    for (final entry in tierWeights.entries) {
      if (entry.value <= 0) continue;

      final pool = _combatPoolForTier(entry.key);
      if (pool.isEmpty) continue;

      final nodeWeight = entry.value / pool.length;
      candidates.addAll(
        pool.map(
          (node) => _WeightedPathNode(
            node: node,
            weight: nodeWeight,
          ),
        ),
      );
    }

    return candidates;
  }

  List<_WeightedPathNode> _campCandidatesForDay(int dayNumber) {
    final recoveryPressure = 1 + ((dayNumber - 1) * 0.08);
    final severePressure = 0.66 + ((dayNumber - 1) * 0.16);

    return [
      _WeightedPathNode(
        node: _restZoneCandidate.node,
        weight: _restZoneCandidate.weight * recoveryPressure,
      ),
      _WeightedPathNode(
        node: _severeMedicationCandidate.node,
        weight: _severeMedicationCandidate.weight * severePressure,
      ),
    ];
  }

  Map<CombatNodeTier, double> _dayCombatTierWeights(int dayNumber) {
    return switch (dayNumber) {
      1 => const {
          CombatNodeTier.gray: 1,
        },
      2 => const {
          CombatNodeTier.gray: 0.67,
          CombatNodeTier.green: 0.33,
        },
      3 => const {
          CombatNodeTier.gray: 0.10,
          CombatNodeTier.green: 0.60,
          CombatNodeTier.blue: 0.30,
        },
      4 => const {
          CombatNodeTier.green: 0.20,
          CombatNodeTier.blue: 0.80,
        },
      _ => const {
          CombatNodeTier.blue: 0.67,
          CombatNodeTier.purple: 0.33,
        },
    };
  }

  Map<CombatNodeTier, double> _nightCombatTierWeights(int dayNumber) {
    return switch (dayNumber) {
      1 => const {
          CombatNodeTier.gray: 0.80,
          CombatNodeTier.green: 0.20,
        },
      2 => const {
          CombatNodeTier.gray: 0.25,
          CombatNodeTier.green: 0.50,
          CombatNodeTier.blue: 0.25,
        },
      3 => const {
          CombatNodeTier.green: 0.67,
          CombatNodeTier.blue: 0.33,
        },
      4 => const {
          CombatNodeTier.green: 0.10,
          CombatNodeTier.blue: 0.60,
          CombatNodeTier.purple: 0.30,
        },
      _ => const {
          CombatNodeTier.purple: 1,
        },
    };
  }

  double _rarityProgressionWeight(int dayNumber, RarityTier rarity) {
    final weights = switch (dayNumber) {
      1 => const {
          RarityTier.gray: 1.35,
          RarityTier.green: 0.58,
          RarityTier.blue: 0.16,
          RarityTier.purple: 0.04,
          RarityTier.yellow: 0.01,
        },
      2 => const {
          RarityTier.gray: 0.85,
          RarityTier.green: 1.05,
          RarityTier.blue: 0.36,
          RarityTier.purple: 0.08,
          RarityTier.yellow: 0.02,
        },
      3 => const {
          RarityTier.gray: 0.26,
          RarityTier.green: 0.95,
          RarityTier.blue: 0.78,
          RarityTier.purple: 0.26,
          RarityTier.yellow: 0.05,
        },
      4 => const {
          RarityTier.gray: 0.08,
          RarityTier.green: 0.42,
          RarityTier.blue: 1.05,
          RarityTier.purple: 0.62,
          RarityTier.yellow: 0.12,
        },
      _ => const {
          RarityTier.gray: 0.02,
          RarityTier.green: 0.12,
          RarityTier.blue: 0.72,
          RarityTier.purple: 1.05,
          RarityTier.yellow: 0.28,
        },
    };

    return weights[rarity] ?? 0;
  }

  List<CombatPathNode> _combatPoolForTier(CombatNodeTier tier) {
    return switch (tier) {
      CombatNodeTier.gray => grayCombatNodes,
      CombatNodeTier.green => greenCombatNodes,
      CombatNodeTier.blue => blueCombatNodes,
      CombatNodeTier.purple => purpleCombatNodes,
      CombatNodeTier.yellow => sunriseCombatNodes,
    };
  }

  List<PathNode> _pickCombatNodesForTiers(List<CombatNodeTier> tiers) {
    final selectedNodes = <CombatPathNode>[];
    final selectedNodeIds = <String>{};

    for (final tier in tiers) {
      final selected = _pickCombatNodeFromTier(
        tier,
        excludedNodeIds: selectedNodeIds,
      );
      selectedNodes.add(selected);
      selectedNodeIds.add(selected.nodeId);
    }

    return List<PathNode>.unmodifiable(selectedNodes);
  }

  CombatPathNode _pickCombatNodeFromTier(
    CombatNodeTier tier, {
    Set<String> excludedNodeIds = const {},
  }) {
    var candidates = _combatPoolForTier(tier)
        .where((node) => !excludedNodeIds.contains(node.nodeId))
        .toList(growable: false);
    if (candidates.isEmpty) {
      candidates = _combatPoolForTier(tier);
    }

    if (candidates.isEmpty) {
      throw StateError('No combat nodes available for tier ${tier.name}.');
    }

    return candidates[_randomizer.nextInt(candidates.length)];
  }

  List<PathNode> _scaleCombatNodesForDay(
    List<PathNode> nodes, {
    required int dayNumber,
  }) {
    return nodes
        .map(
          (node) =>
              node is CombatPathNode ? node.scaledForDay(dayNumber) : node,
        )
        .toList(growable: false);
  }

  List<_WeightedPathNode> _scaleWeightedNodes(
    List<_WeightedPathNode> candidates, {
    required double targetTotalWeight,
  }) {
    if (candidates.isEmpty || targetTotalWeight <= 0) {
      return const <_WeightedPathNode>[];
    }

    final currentTotalWeight = _totalWeight(candidates);
    if (currentTotalWeight <= 0) {
      final distributedWeight = targetTotalWeight / candidates.length;
      return candidates
          .map(
            (candidate) => _WeightedPathNode(
              node: candidate.node,
              weight: distributedWeight,
            ),
          )
          .toList(growable: false);
    }

    final scaleFactor = targetTotalWeight / currentTotalWeight;
    return candidates
        .map(
          (candidate) => _WeightedPathNode(
            node: candidate.node,
            weight: candidate.weight * scaleFactor,
          ),
        )
        .toList(growable: false);
  }

  double _totalWeight(Iterable<_WeightedPathNode> candidates) {
    return candidates.fold<double>(
      0,
      (sum, candidate) => sum + candidate.weight,
    );
  }

  List<PathNode> _pickDistinctWeightedNodes(
    List<_WeightedPathNode> candidates, {
    required int count,
    Set<String> excludedKeys = const {},
  }) {
    final remainingCandidates = candidates
        .where((candidate) => !excludedKeys.contains(_nodeKey(candidate.node)))
        .toList(growable: true);
    final selectedNodes = <PathNode>[];

    while (selectedNodes.length < count && remainingCandidates.isNotEmpty) {
      final pickedNode = _pickWeightedNode(remainingCandidates);
      final pickedKey = _nodeKey(pickedNode);
      selectedNodes.add(pickedNode);
      remainingCandidates.removeWhere(
        (candidate) => _nodeKey(candidate.node) == pickedKey,
      );
    }

    return selectedNodes;
  }

  List<PathNode> _limitShopNodes(
    List<PathNode> nodes, {
    required int nodeCount,
  }) {
    final selectedNodes = <PathNode>[];
    var hasSelectedShop = false;

    for (final node in nodes) {
      if (selectedNodes.length >= nodeCount) break;
      if (node is ShopPathNode) {
        if (hasSelectedShop) continue;
        hasSelectedShop = true;
      }
      selectedNodes.add(node);
    }

    return selectedNodes;
  }

  String _nodeKey(PathNode node) {
    return node.nodeId;
  }

  PathNode _pickWeightedNode(List<_WeightedPathNode> candidates) {
    if (candidates.isEmpty) {
      throw StateError('Cannot pick from an empty weighted node list.');
    }

    final totalWeight = candidates.fold<double>(
      0,
      (sum, candidate) => sum + candidate.weight,
    );
    var roll = _randomizer.nextDouble() * totalWeight;

    for (final candidate in candidates) {
      roll -= candidate.weight;
      if (roll <= 0) return candidate.node;
    }

    return candidates.last.node;
  }

  List<ShopPathNode> _deduplicateShopNodes(Iterable<ShopPathNode> nodes) {
    final seenIds = <String>{};
    final result = <ShopPathNode>[];

    for (final node in nodes) {
      if (!seenIds.add(node.nodeId)) continue;
      result.add(node);
    }

    return List<ShopPathNode>.unmodifiable(result);
  }
}

class _RunStageDefinition {
  final RunHourPhase phase;
  final String title;
  final String subtitle;
  final List<PathNode> nodes;

  const _RunStageDefinition({
    required this.phase,
    required this.title,
    required this.subtitle,
    required this.nodes,
  });
}

class _WeightedPathNode {
  final PathNode node;
  final double weight;

  const _WeightedPathNode({
    required this.node,
    required this.weight,
  });
}
