import '_imports.dart';

class PathNodeService {
  static const startStageIndex = 0;
  static const duskStageIndex = 5;
  static const sunriseStageIndex = 11;
  static const _centerShopPremiumChance = 0.78;
  static const _centerShopPremiumMultiplier = 1.2;

  final Random _random;

  PathNodeService({
    int? seed,
  }) : _random = seed == null ? Random() : Random(seed);

  RunHourSnapshot buildHourSnapshot({
    required int stageIndex,
  }) {
    final clampedStageIndex = stageIndex.clamp(
      startStageIndex,
      sunriseStageIndex,
    );

    if (clampedStageIndex < duskStageIndex) {
      return RunHourSnapshot(
        stageIndex: clampedStageIndex,
        phase: RunHourPhase.day,
        title: 'HORA $clampedStageIndex',
        subtitle: 'Mercados y favores tensos antes del anochecer.',
        nodes: List<PathNode>.unmodifiable(_buildDayNodes()),
      );
    }

    if (clampedStageIndex == duskStageIndex) {
      return RunHourSnapshot(
        stageIndex: clampedStageIndex,
        phase: RunHourPhase.dusk,
        title: 'ANOCHECER',
        subtitle:
            'La ciudad se cierra. Tres enfrentamientos marcan la entrada en la noche.',
        nodes: List<PathNode>.unmodifiable(duskCombatNodes),
      );
    }

    if (clampedStageIndex < sunriseStageIndex) {
      return RunHourSnapshot(
        stageIndex: clampedStageIndex,
        phase: RunHourPhase.night,
        title: 'NOCHE ${clampedStageIndex - duskStageIndex}',
        subtitle: 'Más violencia, peores tratos y menos margen de error.',
        nodes: List<PathNode>.unmodifiable(_buildNightNodes()),
      );
    }

    return RunHourSnapshot(
      stageIndex: clampedStageIndex,
      phase: RunHourPhase.sunrise,
      title: 'SUNRISE',
      subtitle: 'Solo queda un combate. El peor de toda la run.',
      nodes: List<PathNode>.unmodifiable(sunriseCombatNodes.take(1)),
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

    final shouldApplyPremium =
        _random.nextDouble() <= _centerShopPremiumChance;
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

class _WeightedPathNode {
  final PathNode node;
  final double weight;

  const _WeightedPathNode({
    required this.node,
    required this.weight,
  });
}
