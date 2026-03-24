import '_imports.dart';

class PathNodeService {
  static const startStageIndex = 0;
  static const duskStageIndex = 5;
  static const sunriseStageIndex = 11;
  static const _centerShopPremiumChance = 0.78;
  static const _centerShopPremiumMultiplier = 1.2;

  final Random _random;
  late final List<_RunStageDefinition> _stageDefinitions = [
    _RunStageDefinition(
      matches: (stageIndex) => stageIndex < duskStageIndex,
      phase: RunHourPhase.day,
      titleBuilder: (stageIndex) => 'HORA $stageIndex',
      subtitle: 'Mercados y favores tensos antes del anochecer.',
      buildNodes: _buildDayNodes,
    ),
    _RunStageDefinition(
      matches: (stageIndex) => stageIndex == duskStageIndex,
      phase: RunHourPhase.dusk,
      titleBuilder: (_) => 'ANOCHECER',
      subtitle:
          'La ciudad se cierra. Tres enfrentamientos marcan la entrada en la noche.',
      buildNodes: () => duskCombatNodes,
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
      buildNodes: () => sunriseCombatNodes.take(1).toList(growable: false),
    ),
  ];

  PathNodeService({
    int? seed,
  }) : _random = seed == null ? Random() : Random(seed);

  RunHourSnapshot buildHourSnapshot({
    required int stageIndex,
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
          fallbackNodes: definition.buildNodes(),
          availableNodes: availableNodes,
          nodeCount: resolvedNodeCount,
        ),
      ),
    );
  }

  _RunStageDefinition _definitionFor(int stageIndex) {
    return _stageDefinitions.firstWhere(
      (definition) => definition.matches(stageIndex),
    );
  }

  List<PathNode> _buildDayNodes() {
    return [
      _pickWeightedNode(_buildDaySideCandidates()),
      _buildCenterShopNode(dayShopNodes),
      _pickWeightedNode(_buildDaySideCandidates()),
    ];
  }

  List<PathNode> _buildNightNodes() {
    return [
      _pickWeightedNode(_buildNightSideCandidates()),
      _buildCenterShopNode(nightShopNodes),
      _pickWeightedNode(_buildNightSideCandidates()),
    ];
  }

  List<PathNode> _resolveNodes({
    required List<PathNode> fallbackNodes,
    required int nodeCount,
    List<PathNode>? availableNodes,
  }) {
    final sourceNodes = availableNodes == null || availableNodes.isEmpty
        ? fallbackNodes
        : availableNodes;

    return sourceNodes.take(min(nodeCount, sourceNodes.length)).toList(
          growable: false,
        );
  }

  List<_WeightedPathNode> _buildDaySideCandidates() {
    return [
      ...dayShopNodes.map(
        (node) => _WeightedPathNode(node: node, weight: node.rollWeight),
      ),
      ...dayEventNodes.map(
        (node) => _WeightedPathNode(node: node, weight: node.rollWeight),
      ),
      _WeightedPathNode(
        node: dayCampNode,
        weight: dayCampNode.rollWeight,
      ),
      ...rareDayCombatNodes.map(
        (node) => _WeightedPathNode(
          node: node,
          weight: _dayCombatWeight(node),
        ),
      ),
    ];
  }

  List<_WeightedPathNode> _buildNightSideCandidates() {
    return [
      ...nightCombatNodes.map(
        (node) => _WeightedPathNode(
          node: node,
          weight: node.rollWeight * 1.35,
        ),
      ),
      ...nightShopNodes.map(
        (node) => _WeightedPathNode(node: node, weight: node.rollWeight),
      ),
      ...nightEventNodes.map(
        (node) => _WeightedPathNode(node: node, weight: node.rollWeight),
      ),
    ];
  }

  ShopPathNode _buildCenterShopNode(List<ShopPathNode> shopPool) {
    final baseNode = _pickWeightedNode(
      shopPool
          .map(
            (node) => _WeightedPathNode(
              node: node,
              weight: node.rollWeight,
            ),
          )
          .toList(),
    ) as ShopPathNode;

    final shouldApplyPremium = _random.nextDouble() <= _centerShopPremiumChance;
    if (!shouldApplyPremium) return baseNode;

    return baseNode.withPriceMultiplier(_centerShopPremiumMultiplier);
  }

  double _dayCombatWeight(CombatPathNode node) {
    switch (node.tier) {
      case CombatNodeTier.gray:
        return RarityTier.blue.rollWeight;
      case CombatNodeTier.green:
        return RarityTier.purple.rollWeight;
      case CombatNodeTier.blue:
        return RarityTier.yellow.rollWeight;
      case CombatNodeTier.purple:
      case CombatNodeTier.yellow:
        return 0;
    }
  }

  PathNode _pickWeightedNode(List<_WeightedPathNode> candidates) {
    if (candidates.isEmpty) {
      throw StateError('Cannot pick from an empty weighted node list.');
    }

    final totalWeight = candidates.fold<double>(
      0,
      (sum, candidate) => sum + candidate.weight,
    );
    var roll = _random.nextDouble() * totalWeight;

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
  final List<PathNode> Function() buildNodes;

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
