import 'dart:math';

import '../../entities/_exports.dart';
import '../../services/pattern/_exports.dart';
import '../path/operative_pattern_overlay.dart';

abstract final class BattlePatternMatchPresenter {
  static BattlePatternMatchContext buildContext({
    required List<OperativePatternPoint> patternPoints,
    required Map<String, Item> equippedItemsByPointKey,
    required OperativePatternResolution resolution,
    int otherArchetypeItemCount = 0,
  }) {
    final usedItemPointKeys = itemPointKeysUsedBy(
      patternPoints: patternPoints,
      equippedItemsByPointKey: equippedItemsByPointKey,
    );
    return BattlePatternMatchContext(
      patternPoints: List<OperativePatternPoint>.unmodifiable(patternPoints),
      attackBonus: resolution.attackBonus,
      barrierBonus: resolution.barrierBonus,
      otherArchetypeItemCount: otherArchetypeItemCount,
      usedItemPointKeys: List<String>.unmodifiable(usedItemPointKeys),
      repeatedItemPointKeys: Set<String>.unmodifiable(
        repeatedItemPointKeys(usedItemPointKeys),
      ),
      firstRepeatedItemPointKey: firstRepeatedItemPointKey(usedItemPointKeys),
      firstUsedItemHasAttackBonus: firstUsedItemHasAttackBonus(
        usedItemPointKeys: usedItemPointKeys,
        equippedItemsByPointKey: equippedItemsByPointKey,
      ),
      activatedItemEffectCount: activatedItemEffectCount(
        usedItemPointKeys: usedItemPointKeys,
        equippedItemsByPointKey: equippedItemsByPointKey,
      ),
    );
  }

  static List<String> itemPointKeysUsedBy({
    required List<OperativePatternPoint> patternPoints,
    required Map<String, Item> equippedItemsByPointKey,
  }) {
    return [
      for (final point in OperativePatternRequirement.normalizedSequence(
        patternPoints,
      ))
        if (equippedItemsByPointKey.containsKey(point.key)) point.key,
    ];
  }

  static Set<String> repeatedItemPointKeys(List<String> usedItemPointKeys) {
    final seen = <String>{};
    final repeated = <String>{};
    for (final pointKey in usedItemPointKeys) {
      if (!seen.add(pointKey)) {
        repeated.add(pointKey);
      }
    }
    return repeated;
  }

  static String? firstRepeatedItemPointKey(List<String> usedItemPointKeys) {
    final seen = <String>{};
    for (final pointKey in usedItemPointKeys) {
      if (!seen.add(pointKey)) return pointKey;
    }
    return null;
  }

  static bool firstUsedItemHasAttackBonus({
    required List<String> usedItemPointKeys,
    required Map<String, Item> equippedItemsByPointKey,
  }) {
    if (usedItemPointKeys.isEmpty) return false;

    final item = equippedItemsByPointKey[usedItemPointKeys.first];
    if (item == null) return false;

    return item.actionEffects.any(
          (effect) => effect.actionType == ItemActionType.attack,
        ) ||
        item.patternEffects.any(
          (effect) => effect.actionEffect.actionType == ItemActionType.attack,
        );
  }

  static int activatedItemEffectCount({
    required List<String> usedItemPointKeys,
    required Map<String, Item> equippedItemsByPointKey,
  }) {
    var count = 0;
    final seen = <String>{};
    for (final pointKey in usedItemPointKeys) {
      if (!seen.add(pointKey)) continue;
      final item = equippedItemsByPointKey[pointKey];
      if (item == null) continue;
      if (item.patternEffects.isNotEmpty ||
          item.passiveEffects.any(
            (effect) =>
                effect.hook == ItemEffectHook.patternUsed ||
                effect.hook == ItemEffectHook.prePatternAttack,
          )) {
        count++;
      }
    }
    return count;
  }

  static Map<String, OperativePatternPointContent> buildContentsByPointKey({
    required Map<String, Item> equippedItemsByPointKey,
    required Map<String, OperativePatternBonus> bonusesByPointKey,
    required OperativePatternResolution resolution,
    bool Function(Item item)? isFallbackBonusEligible,
  }) {
    final allowedBonusKinds = <OperativePatternBonusKind>{
      for (final item in equippedItemsByPointKey.values)
        for (final effect in item.patternEffects)
          if (effect.actionEffect.actionType == ItemActionType.attack)
            OperativePatternBonusKind.attack
          else if (effect.actionEffect.actionType == ItemActionType.block)
            OperativePatternBonusKind.barrier
          else if (effect.actionEffect.actionType == ItemActionType.heal)
            OperativePatternBonusKind.health,
    };
    return <String, OperativePatternPointContent>{
      for (final entry in equippedItemsByPointKey.entries)
        entry.key: OperativePatternPointContent(
          item: entry.value,
          bonus: entry.value.primaryPatternBonus != null &&
                  allowedBonusKinds
                      .contains(entry.value.primaryPatternBonus!.kind)
              ? entry.value.primaryPatternBonus
              : entry.value.primaryActionEffect != null ||
                      isFallbackBonusEligible?.call(entry.value) == false
                  ? null
                  : bonusesByPointKey[entry.key],
          requirement: entry.value.primaryPatternBonus != null &&
                  allowedBonusKinds
                      .contains(entry.value.primaryPatternBonus!.kind)
              ? entry.value.primaryPatternEffect!.patternType
              : null,
          adjacencyBonuses: const <OperativePatternAdjacencyBonus>[],
          activatedAdjacencyBonuses:
              resolution.activatedAdjacencyBonusesAt(entry.key),
          isBonusEnabled: resolution.isItemBonusEnabledAt(entry.key),
          isPatternBonusActivated: resolution.isItemBonusEnabledAt(entry.key),
          hasAura: false,
        ),
      for (final entry in bonusesByPointKey.entries)
        if (!equippedItemsByPointKey.containsKey(entry.key))
          entry.key: OperativePatternPointContent(bonus: entry.value),
    };
  }
}

abstract final class BattlePatternEnemyPlanner {
  static List<OperativePatternPoint> buildClosedPatternOrPass({
    required int maxPatternPoints,
    required Set<String> blockedPointKeys,
    required Map<String, Item> equippedItemsByPointKey,
    required Iterable<OperativePatternWallSegment> activeWalls,
    List<List<String>> bannedPatternPointKeys = const <List<String>>[],
  }) {
    for (var attempt = 0; attempt < 3; attempt++) {
      final pattern = buildPattern(
        maxPatternPoints: maxPatternPoints,
        blockedPointKeys: blockedPointKeys,
        equippedItemsByPointKey: equippedItemsByPointKey,
        activeWalls: activeWalls,
        bannedPatternPointKeys: bannedPatternPointKeys,
      );
      if (OperativePatternRequirement.isClosedPattern(pattern)) {
        return pattern;
      }
    }

    return const <OperativePatternPoint>[];
  }

  static List<OperativePatternPoint> buildPattern({
    required int maxPatternPoints,
    required Set<String> blockedPointKeys,
    required Map<String, Item> equippedItemsByPointKey,
    required Iterable<OperativePatternWallSegment> activeWalls,
    List<List<String>> bannedPatternPointKeys = const <List<String>>[],
  }) {
    final maxDistinctPoints = max(3, maxPatternPoints);
    final candidates = <OperativePatternPoint>[
      for (final point in operativePatternPoints)
        if (!blockedPointKeys.contains(point.key)) point,
    ];
    if (candidates.length < 3) return const <OperativePatternPoint>[];

    candidates.sort((a, b) {
      final aScore = pointPriority(equippedItemsByPointKey[a.key]);
      final bScore = pointPriority(equippedItemsByPointKey[b.key]);
      return bScore.compareTo(aScore);
    });

    for (var targetLength = min(maxDistinctPoints, candidates.length);
        targetLength >= 3;
        targetLength--) {
      final selected = _bestClosedPattern(
        candidates: candidates,
        targetLength: targetLength,
        equippedItemsByPointKey: equippedItemsByPointKey,
        activeWalls: activeWalls,
        bannedPatternPointKeys: bannedPatternPointKeys,
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

  static List<OperativePatternPoint>? _bestClosedPattern({
    required List<OperativePatternPoint> candidates,
    required int targetLength,
    required Map<String, Item> equippedItemsByPointKey,
    required Iterable<OperativePatternWallSegment> activeWalls,
    required List<List<String>> bannedPatternPointKeys,
  }) {
    List<OperativePatternPoint>? bestPattern;
    var bestScore = -1;

    void visit(
      List<OperativePatternPoint> path,
      Set<String> usedKeys,
    ) {
      if (path.length == targetLength) {
        if (isSegmentBlocked(
          from: path.last,
          to: path.first,
          activeWalls: activeWalls,
        )) {
          return;
        }
        final closedPointKeys = <String>[
          ...path.map((point) => point.key),
          path.first.key,
        ];
        if (bannedPatternPointKeys.any(
          (banned) => _sameOrderedPointKeys(banned, closedPointKeys),
        )) {
          return;
        }
        final score = path.fold<int>(
          0,
          (sum, point) =>
              sum + pointPriority(equippedItemsByPointKey[point.key]),
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
            isSegmentBlocked(
              from: path.last,
              to: point,
              activeWalls: activeWalls,
            )) {
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

  static bool isSegmentBlocked({
    required OperativePatternPoint from,
    required OperativePatternPoint to,
    required Iterable<OperativePatternWallSegment> activeWalls,
  }) {
    final connectedWallKeys = connectedWallKeysFor(activeWalls);
    return activeWalls.any(
      (wall) => wall.blocks(
        from,
        to,
        isConnected: connectedWallKeys.contains(wall.key),
      ),
    );
  }

  static bool _sameOrderedPointKeys(List<String> first, List<String> second) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) return false;
    }
    return true;
  }

  static Set<String> connectedWallKeysFor(
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

  static int pointPriority(Item? item) {
    if (item == null) return 0;
    var score = 0;
    for (final effect in <ActionEffect>[
      ...item.actionEffects,
      ...item.patternEffects.map((effect) => effect.actionEffect),
    ]) {
      score += switch (effect.actionType) {
        ItemActionType.attack => effect.value * 4,
        ItemActionType.block => effect.value * 3,
        ItemActionType.heal => effect.value * 2,
        ItemActionType.none => 0,
      };
    }
    return score;
  }
}
