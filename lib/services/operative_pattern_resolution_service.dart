import '../entities/_exports.dart';

class OperativePatternResolution {
  final List<OperativePatternPoint> patternPoints;
  final bool isClosed;
  final int distinctPointCount;
  final int attackBonus;
  final int barrierBonus;
  final Map<String, OperativePatternBonus> activatedPatternBonusesByPointKey;
  final Map<String, List<OperativePatternAdjacencyBonus>>
      activatedAdjacencyBonusesByPointKey;
  final Map<String, bool> itemActivationByPointKey;

  const OperativePatternResolution({
    required this.patternPoints,
    required this.isClosed,
    required this.distinctPointCount,
    required this.attackBonus,
    required this.barrierBonus,
    required this.activatedPatternBonusesByPointKey,
    required this.activatedAdjacencyBonusesByPointKey,
    required this.itemActivationByPointKey,
  });

  bool get hasBonus => attackBonus > 0 || barrierBonus > 0;

  bool isItemBonusEnabledAt(String pointKey) {
    return itemActivationByPointKey[pointKey] ?? false;
  }

  List<OperativePatternAdjacencyBonus> activatedAdjacencyBonusesAt(
    String pointKey,
  ) {
    return activatedAdjacencyBonusesByPointKey[pointKey] ??
        const <OperativePatternAdjacencyBonus>[];
  }
}

abstract final class OperativePatternResolutionService {
  static OperativePatternResolution resolve({
    required List<OperativePatternPoint> patternPoints,
    required Map<String, Item> equippedItemsByPointKey,
    required Map<String, OperativePatternBonus> bonusesByPointKey,
    Set<String> blockedPointKeys = const <String>{},
  }) {
    final stablePatternPoints =
        List<OperativePatternPoint>.unmodifiable(patternPoints);
    final isClosed = OperativePatternRequirement.isClosedPattern(
      stablePatternPoints,
    );
    final distinctPointCount = OperativePatternRequirement.distinctPointCount(
      stablePatternPoints,
    );
    final itemActivationByPointKey = <String, bool>{
      for (final pointKey in equippedItemsByPointKey.keys) pointKey: false,
    };

    if (!isClosed) {
      return OperativePatternResolution(
        patternPoints: stablePatternPoints,
        isClosed: false,
        distinctPointCount: distinctPointCount,
        attackBonus: 0,
        barrierBonus: 0,
        activatedPatternBonusesByPointKey: const <String,
            OperativePatternBonus>{},
        activatedAdjacencyBonusesByPointKey: const <String,
            List<OperativePatternAdjacencyBonus>>{},
        itemActivationByPointKey: Map<String, bool>.unmodifiable(
          itemActivationByPointKey,
        ),
      );
    }

    final seenPointKeys = <String>{};
    final activatedPatternBonusesByPointKey = <String, OperativePatternBonus>{};
    final activatedAdjacencyBonusesByPointKey =
        <String, List<OperativePatternAdjacencyBonus>>{};
    var attackBonus = 0;
    var barrierBonus = 0;

    for (final point in stablePatternPoints) {
      if (!seenPointKeys.add(point.key)) continue;
      if (blockedPointKeys.contains(point.key)) continue;

      final item = equippedItemsByPointKey[point.key];
      final bonus = item == null
          ? bonusesByPointKey[point.key]
          : _resolveItemPatternBonus(
              item: item,
              point: point,
              patternPoints: stablePatternPoints,
              itemActivationByPointKey: itemActivationByPointKey,
            );
      if (bonus != null) {
        activatedPatternBonusesByPointKey[point.key] = bonus;
        switch (bonus.kind) {
          case OperativePatternBonusKind.attack:
            attackBonus += bonus.amount;
            break;
          case OperativePatternBonusKind.barrier:
            barrierBonus += bonus.amount;
            break;
        }
      }

      if (item == null) continue;
      final adjacencyBonuses = _resolveItemAdjacencyBonuses(
        item: item,
        point: point,
        equippedItemsByPointKey: equippedItemsByPointKey,
      );
      if (adjacencyBonuses.isEmpty) continue;

      activatedAdjacencyBonusesByPointKey[point.key] = adjacencyBonuses;
      for (final adjacencyBonus in adjacencyBonuses) {
        switch (adjacencyBonus.bonus.kind) {
          case OperativePatternBonusKind.attack:
            attackBonus += adjacencyBonus.bonus.amount;
            break;
          case OperativePatternBonusKind.barrier:
            barrierBonus += adjacencyBonus.bonus.amount;
            break;
        }
      }
    }

    final activatedPatternBonuses =
        Map<String, OperativePatternBonus>.unmodifiable(
      activatedPatternBonusesByPointKey,
    );
    final activatedAdjacencyBonuses =
        Map<String, List<OperativePatternAdjacencyBonus>>.unmodifiable(
      activatedAdjacencyBonusesByPointKey.map(
        (pointKey, bonuses) => MapEntry(
          pointKey,
          List<OperativePatternAdjacencyBonus>.unmodifiable(bonuses),
        ),
      ),
    );
    final itemActivations = Map<String, bool>.unmodifiable(
      itemActivationByPointKey,
    );

    return OperativePatternResolution(
      patternPoints: stablePatternPoints,
      isClosed: true,
      distinctPointCount: distinctPointCount,
      attackBonus: attackBonus,
      barrierBonus: barrierBonus,
      activatedPatternBonusesByPointKey: activatedPatternBonuses,
      activatedAdjacencyBonusesByPointKey: activatedAdjacencyBonuses,
      itemActivationByPointKey: itemActivations,
    );
  }

  static OperativePatternBonus? _resolveItemPatternBonus({
    required Item item,
    required OperativePatternPoint point,
    required List<OperativePatternPoint> patternPoints,
    required Map<String, bool> itemActivationByPointKey,
  }) {
    final isEnabled = item.patternRequirement.isSatisfiedBy(
      patternPoints: patternPoints,
      itemPoint: point,
    );
    itemActivationByPointKey[point.key] = isEnabled;

    return isEnabled ? item.patternBonus : null;
  }

  static List<OperativePatternAdjacencyBonus> _resolveItemAdjacencyBonuses({
    required Item item,
    required OperativePatternPoint point,
    required Map<String, Item> equippedItemsByPointKey,
  }) {
    final activatedBonuses = <OperativePatternAdjacencyBonus>[];
    for (final adjacencyBonus in item.patternAdjacencyBonuses) {
      final adjacentPointKey = operativePatternPointKey(
        point.x + adjacencyBonus.direction.dx,
        point.y + adjacencyBonus.direction.dy,
      );
      final adjacentItem = equippedItemsByPointKey[adjacentPointKey];
      if (adjacentItem == null) continue;
      if (!adjacentItem.hasTag(adjacencyBonus.requiredTag)) continue;

      activatedBonuses.add(adjacencyBonus);
    }

    return List<OperativePatternAdjacencyBonus>.unmodifiable(activatedBonuses);
  }
}
