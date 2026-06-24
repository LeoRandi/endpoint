import '../../entities/_exports.dart';

class OperativePatternAdjacencyEvaluation {
  final OperativePatternPoint sourcePoint;
  final OperativePatternPoint targetPoint;
  final Item item;
  final Item? targetItem;
  final OperativePatternAdjacencyBonus bonus;

  const OperativePatternAdjacencyEvaluation({
    required this.sourcePoint,
    required this.targetPoint,
    required this.item,
    required this.targetItem,
    required this.bonus,
  });

  bool get isMatched => targetItem?.hasTag(bonus.requiredTag) ?? false;
}

class OperativePatternAdjacencyTotals {
  final int attack;
  final int barrier;
  final int health;

  const OperativePatternAdjacencyTotals({
    required this.attack,
    required this.barrier,
    this.health = 0,
  });
}

abstract final class OperativePatternAdjacencyService {
  static List<OperativePatternAdjacencyEvaluation> evaluate({
    required Map<String, Item> itemsByPointKey,
    Iterable<OperativePatternPoint> points = operativePatternPoints,
    Iterable<OperativePatternAdjacencyBonus> Function(
      OperativePatternPoint point,
      Item item,
    )? adjacencyBonusesForItem,
  }) {
    final evaluations = <OperativePatternAdjacencyEvaluation>[];

    for (final point in points) {
      final item = itemsByPointKey[point.key];
      if (item == null) continue;

      final adjacencyBonuses = adjacencyBonusesForItem?.call(point, item) ??
          const <OperativePatternAdjacencyBonus>[];
      for (final adjacencyBonus in adjacencyBonuses) {
        final targetPoint = operativePatternPointAt(
          x: point.x + adjacencyBonus.direction.dx,
          y: point.y + adjacencyBonus.direction.dy,
        );
        if (targetPoint == null) continue;

        evaluations.add(
          OperativePatternAdjacencyEvaluation(
            sourcePoint: point,
            targetPoint: targetPoint,
            item: item,
            targetItem: itemsByPointKey[targetPoint.key],
            bonus: adjacencyBonus,
          ),
        );
      }
    }

    return List<OperativePatternAdjacencyEvaluation>.unmodifiable(evaluations);
  }

  static List<OperativePatternAdjacencyBonus> matchedBonusesForPoint({
    required Map<String, Item> itemsByPointKey,
    required OperativePatternPoint point,
    required bool shouldHalveItemPatternBonuses,
  }) {
    final matchedBonuses = <OperativePatternAdjacencyBonus>[];
    for (final evaluation in evaluate(
      itemsByPointKey: itemsByPointKey,
      points: <OperativePatternPoint>[point],
    )) {
      if (!evaluation.isMatched) continue;

      matchedBonuses.add(
        shouldHalveItemPatternBonuses
            ? _halvedPositiveBonus(evaluation.bonus)
            : evaluation.bonus,
      );
    }

    return List<OperativePatternAdjacencyBonus>.unmodifiable(matchedBonuses);
  }

  static OperativePatternAdjacencyTotals totalsFor(
    Iterable<OperativePatternAdjacencyEvaluation> evaluations,
  ) {
    var attack = 0;
    var barrier = 0;
    var health = 0;

    for (final evaluation in evaluations) {
      if (!evaluation.isMatched) continue;

      switch (evaluation.bonus.kind) {
        case OperativePatternBonusKind.attack:
          attack += evaluation.bonus.amount;
          break;
        case OperativePatternBonusKind.barrier:
          barrier += evaluation.bonus.amount;
          break;
        case OperativePatternBonusKind.health:
          health += evaluation.bonus.amount;
          break;
      }
    }

    return OperativePatternAdjacencyTotals(
      attack: attack,
      barrier: barrier,
      health: health,
    );
  }

  static OperativePatternAdjacencyBonus _halvedPositiveBonus(
    OperativePatternAdjacencyBonus bonus,
  ) {
    if (bonus.amount <= 0) return bonus;

    return OperativePatternAdjacencyBonus(
      direction: bonus.direction,
      requiredTag: bonus.requiredTag,
      kind: bonus.kind,
      amount: (bonus.amount + 1) ~/ 2,
    );
  }
}
