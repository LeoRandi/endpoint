import '_imports.dart';

class PathNodeService {
  static const startStageIndex = 0;
  static const duskStageIndex = 6;
  static const sunriseStageIndex = 12;
  static const _openingArchetypeCount = 3;
  static const _centerShopPremiumChance = 0.78;
  static const _centerShopPremiumMultiplier = 1.2;
  static const _dayEventRelativeWeight = 0.9;

  final RunRandomizer _randomizer;
  final PathEventService _pathEventService;
  late final List<_RunStageDefinition> _stageDefinitions = [
    _RunStageDefinition(
      matches: (stageIndex) => stageIndex == startStageIndex,
      phase: RunHourPhase.day,
      titleBuilder: (_) => 'HORA 1',
      subtitle: 'Elige el arquetipo con el que abrira la run.',
      buildNodes: (_, __) => _buildOpeningArchetypeNodes(),
    ),
    _RunStageDefinition(
      matches: (stageIndex) =>
          stageIndex > startStageIndex && stageIndex < duskStageIndex,
      phase: RunHourPhase.day,
      titleBuilder: (stageIndex) => 'HORA ${stageIndex + 1}',
      subtitle: 'Mercados y favores tensos antes del anochecer.',
      buildNodes: _buildDayNodes,
    ),
    _RunStageDefinition(
      matches: (stageIndex) => stageIndex == duskStageIndex,
      phase: RunHourPhase.dusk,
      titleBuilder: (_) => 'ANOCHECER',
      subtitle:
          'La ciudad se cierra. Tres enfrentamientos marcan la entrada en la noche.',
      buildNodes: (_, __) => duskCombatNodes,
    ),
    _RunStageDefinition(
      matches: (stageIndex) => stageIndex < sunriseStageIndex,
      phase: RunHourPhase.night,
      titleBuilder: (stageIndex) => 'NOCHE ${stageIndex - duskStageIndex}',
      subtitle: 'Mas violencia, peores tratos y menos margen de error.',
      buildNodes: _buildNightNodes,
    ),
    _RunStageDefinition(
      matches: (_) => true,
      phase: RunHourPhase.sunrise,
      titleBuilder: (_) => 'SUNRISE',
      subtitle: 'Solo queda un combate. El peor de toda la run.',
      buildNodes: (_, __) => sunriseCombatNodes.take(1).toList(growable: false),
    ),
  ];
  late final List<_WeightedPathNode> _dayShopCandidates =
      _buildWeightedNodes(dayShopNodes);
  late final List<_WeightedPathNode> _nightShopCandidates =
      _buildWeightedNodes(nightShopNodes);
  late final double _dayShopTotalWeight = _totalWeight(_dayShopCandidates);
  late final List<_WeightedPathNode> _rareDayCombatCandidates =
      _scaleWeightedNodes(
    _buildWeightedNodes(
      rareDayCombatNodes.where(_isAllowedDayCombatNode),
    ),
    targetTotalWeight: _dayShopTotalWeight,
  );
  late final List<_WeightedPathNode> _nightCombatCandidates =
      List<_WeightedPathNode>.unmodifiable(
    nightCombatNodes.map(
      (node) => _WeightedPathNode(
        node: node,
        weight: node.rollWeight * 1.35,
      ),
    ),
  );
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
  })  : _randomizer = randomizer,
        _pathEventService = pathEventService;

  RunRandomizer get randomizer => _randomizer;

  RunHourSnapshot buildHourSnapshot({
    required int stageIndex,
    Battler? player,
    List<PathNode>? availableNodes,
    int nodeCount = 3,
  }) {
    final clampedStageIndex = stageIndex.clamp(
      startStageIndex,
      sunriseStageIndex,
    );
    final resolvedNodeCount = max(1, nodeCount);
    final definition = _definitionFor(clampedStageIndex);

    return RunHourSnapshot(
      stageIndex: clampedStageIndex,
      phase: definition.phase,
      title: definition.titleBuilder(clampedStageIndex),
      subtitle: definition.subtitle,
      nodes: List<PathNode>.unmodifiable(
        _resolveNodes(
          fallbackNodes: definition.buildNodes(clampedStageIndex, player),
          availableNodes: availableNodes,
          nodeCount: resolvedNodeCount,
          player: player,
        ),
      ),
    );
  }

  _RunStageDefinition _definitionFor(int stageIndex) {
    return _stageDefinitions.firstWhere(
      (definition) => definition.matches(stageIndex),
    );
  }

  List<PathNode> _buildOpeningArchetypeNodes() {
    return _randomizer.pickDistinct(
      openingArchetypeNodes,
      _openingArchetypeCount,
    );
  }

  List<PathNode> _buildDayNodes(int stageIndex, Battler? player) {
    return _buildUniqueHourNodes(
      sideCandidates: _buildDaySideCandidates(player),
      shopPool: dayShopNodes,
    );
  }

  List<PathNode> _buildNightNodes(int stageIndex, Battler? player) {
    if (stageIndex == sunriseStageIndex - 1) {
      return _buildFinalNightNodes();
    }

    return _buildUniqueHourNodes(
      sideCandidates: _buildNightSideCandidates(player),
      shopPool: nightShopNodes,
    );
  }

  List<PathNode> _resolveNodes({
    required List<PathNode> fallbackNodes,
    required int nodeCount,
    Battler? player,
    List<PathNode>? availableNodes,
  }) {
    final sourceNodes = availableNodes == null || availableNodes.isEmpty
        ? fallbackNodes
        : availableNodes;
    final resolvedNodes = sourceNodes
        .where((node) => _canAppearForPlayer(node, player))
        .toList(growable: false);

    return resolvedNodes.take(min(nodeCount, resolvedNodes.length)).toList(
          growable: false,
        );
  }

  List<_WeightedPathNode> _buildDaySideCandidates(Battler? player) {
    final eventCandidates = _scaleWeightedNodes(
      _buildWeightedNodes(_filterEventNodes(dayEventNodes, player)),
      targetTotalWeight: _dayShopTotalWeight * _dayEventRelativeWeight,
    );

    return [
      ..._dayShopCandidates,
      ...eventCandidates,
      _restZoneCandidate,
      _severeMedicationCandidate,
      ..._rareDayCombatCandidates,
    ];
  }

  List<_WeightedPathNode> _buildNightSideCandidates(Battler? player) {
    return [
      ..._nightCombatCandidates,
      ..._nightShopCandidates,
      ..._filterEventNodes(nightEventNodes, player).map(
        (node) => _WeightedPathNode(node: node, weight: node.rollWeight),
      ),
      _restZoneCandidate,
      _severeMedicationCandidate,
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

  bool _canAppearForPlayer(PathNode node, Battler? player) {
    if (node is! EventPathNode) return true;

    return _pathEventService.canAppear(
      node: node,
      player: player,
    );
  }

  List<PathNode> _buildFinalNightNodes() {
    final centerNode = _buildCenterShopNode(nightShopNodes);

    return [
      restZoneCampNode,
      centerNode,
      severeMedicationCampNode,
    ];
  }

  List<PathNode> _buildUniqueHourNodes({
    required List<_WeightedPathNode> sideCandidates,
    required List<ShopPathNode> shopPool,
  }) {
    final centerNode = _buildCenterShopNode(shopPool);
    final sideNodes = _pickDistinctWeightedNodes(
      sideCandidates,
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

  ShopPathNode _buildCenterShopNode(List<ShopPathNode> shopPool) {
    final baseNode = _pickWeightedNode(
      _weightedShopCandidatesFor(shopPool),
    ) as ShopPathNode;

    final shouldApplyPremium = _randomizer.chance(_centerShopPremiumChance);
    if (!shouldApplyPremium) return baseNode;

    return baseNode.withPriceMultiplier(_centerShopPremiumMultiplier);
  }

  bool _isAllowedDayCombatNode(CombatPathNode node) {
    return node.tier.index <= CombatNodeTier.green.index;
  }

  List<_WeightedPathNode> _buildWeightedNodes(Iterable<PathNode> nodes) {
    return nodes
        .map(
          (node) => _WeightedPathNode(
            node: node,
            weight: node.rollWeight,
          ),
        )
        .toList(growable: false);
  }

  List<_WeightedPathNode> _weightedShopCandidatesFor(
      List<ShopPathNode> shopPool) {
    if (identical(shopPool, dayShopNodes)) {
      return _dayShopCandidates;
    }
    if (identical(shopPool, nightShopNodes)) {
      return _nightShopCandidates;
    }

    return _buildWeightedNodes(shopPool);
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
}

class _RunStageDefinition {
  final bool Function(int stageIndex) matches;
  final RunHourPhase phase;
  final String Function(int stageIndex) titleBuilder;
  final String subtitle;
  final List<PathNode> Function(int stageIndex, Battler? player) buildNodes;

  const _RunStageDefinition({
    required this.matches,
    required this.phase,
    required this.titleBuilder,
    required this.subtitle,
    required this.buildNodes,
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
