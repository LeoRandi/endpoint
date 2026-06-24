import 'dart:math';

import '../../entities/_exports.dart';
import 'operative_pattern_adjacency_service.dart';

class OperativePatternResolution {
  final List<OperativePatternPoint> patternPoints;
  final bool isClosed;
  final int distinctPointCount;
  final int attackBonus;
  final int barrierBonus;
  final int healthBonus;
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
    this.healthBonus = 0,
    required this.activatedPatternBonusesByPointKey,
    required this.activatedAdjacencyBonusesByPointKey,
    required this.itemActivationByPointKey,
  });

  bool get hasBonus => attackBonus > 0 || barrierBonus > 0 || healthBonus > 0;

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
    int adaptationMaxEmptyItemBonus = 0,
    bool shouldDilutePositiveBonuses = false,
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
        healthBonus: 0,
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
    final allowedBonusKinds = _actionBonusKindsFor(
      equippedItemsByPointKey.values,
    );
    var attackBonus = 0;
    var barrierBonus = 0;
    var healthBonus = 0;

    for (final point in stablePatternPoints) {
      if (!seenPointKeys.add(point.key)) continue;
      if (blockedPointKeys.contains(point.key)) continue;

      final item = equippedItemsByPointKey[point.key];
      final OperativePatternBonus? resolvedBonus;
      if (item == null) {
        resolvedBonus = bonusesByPointKey[point.key];
      } else if (_canUseAdaptationBonus(
        item: item,
        adaptationMaxEmptyItemBonus: adaptationMaxEmptyItemBonus,
      )) {
        resolvedBonus = _resolveAdaptationBonus(
          pointKey: point.key,
          bonusesByPointKey: bonusesByPointKey,
          itemActivationByPointKey: itemActivationByPointKey,
          adaptationMaxEmptyItemBonus: adaptationMaxEmptyItemBonus,
        );
      } else {
        _activateItemPatternEffects(
          item: item,
          point: point,
          patternPoints: stablePatternPoints,
          itemActivationByPointKey: itemActivationByPointKey,
        );
        // PatternEffect actions resolve as their own actions in battle; they
        // must not also be folded into the pattern's generic stat bonus.
        resolvedBonus = null;
      }
      final bonus = resolvedBonus != null &&
              allowedBonusKinds.contains(resolvedBonus.kind)
          ? resolvedBonus
          : null;
      if (bonus != null) {
        activatedPatternBonusesByPointKey[point.key] = bonus;
        switch (bonus.kind) {
          case OperativePatternBonusKind.attack:
            attackBonus += bonus.amount;
            break;
          case OperativePatternBonusKind.barrier:
            barrierBonus += bonus.amount;
            break;
          case OperativePatternBonusKind.health:
            healthBonus += bonus.amount;
            break;
        }
      }

      if (item == null) continue;
      final adjacencyBonuses = _resolveItemAdjacencyBonuses(
        point: point,
        equippedItemsByPointKey: equippedItemsByPointKey,
        shouldHalveItemPatternBonuses: shouldDilutePositiveBonuses,
      )
          .where(
            (bonus) => allowedBonusKinds.contains(bonus.bonus.kind),
          )
          .toList(growable: false);
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
          case OperativePatternBonusKind.health:
            healthBonus += adjacencyBonus.bonus.amount;
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
      healthBonus: healthBonus,
      activatedPatternBonusesByPointKey: activatedPatternBonuses,
      activatedAdjacencyBonusesByPointKey: activatedAdjacencyBonuses,
      itemActivationByPointKey: itemActivations,
    );
  }

  static bool _canUseAdaptationBonus({
    required Item item,
    required int adaptationMaxEmptyItemBonus,
  }) {
    return adaptationMaxEmptyItemBonus > 0 && item.patternEffects.isEmpty;
  }

  static Set<OperativePatternBonusKind> _actionBonusKindsFor(
    Iterable<Item> items,
  ) {
    final kinds = <OperativePatternBonusKind>{};
    for (final item in items) {
      for (final effect in item.patternEffects) {
        switch (effect.actionEffect.actionType) {
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

  static OperativePatternBonus? _resolveAdaptationBonus({
    required String pointKey,
    required Map<String, OperativePatternBonus> bonusesByPointKey,
    required Map<String, bool> itemActivationByPointKey,
    required int adaptationMaxEmptyItemBonus,
  }) {
    final bonus = bonusesByPointKey[pointKey];
    if (bonus == null) return null;

    final amount = min(bonus.amount, max(1, adaptationMaxEmptyItemBonus));
    itemActivationByPointKey[pointKey] = amount > 0;
    if (amount <= 0) return null;

    return OperativePatternBonus(kind: bonus.kind, amount: amount);
  }

  static void _activateItemPatternEffects({
    required Item item,
    required OperativePatternPoint point,
    required List<OperativePatternPoint> patternPoints,
    required Map<String, bool> itemActivationByPointKey,
  }) {
    final matchedEffects = item.matchingPatternEffects(
      patternPoints: patternPoints,
      itemPoint: point,
    );
    itemActivationByPointKey[point.key] = matchedEffects.isNotEmpty;
  }

  static List<OperativePatternAdjacencyBonus> _resolveItemAdjacencyBonuses({
    required OperativePatternPoint point,
    required Map<String, Item> equippedItemsByPointKey,
    required bool shouldHalveItemPatternBonuses,
  }) {
    return OperativePatternAdjacencyService.matchedBonusesForPoint(
      itemsByPointKey: equippedItemsByPointKey,
      point: point,
      shouldHalveItemPatternBonuses: shouldHalveItemPatternBonuses,
    );
  }
}
