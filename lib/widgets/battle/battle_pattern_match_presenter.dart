import 'dart:math';

import '../../entities/_exports.dart';
import '../../services/battle/_exports.dart';
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

  static List<BattlePatternActionPileEntry> buildActionPile({
    required List<OperativePatternPoint> patternPoints,
    required Map<String, Item> equippedItemsByPointKey,
    required Map<String, OperativePatternBonus> bonusesByPointKey,
    required OperativePatternResolution resolution,
  }) {
    final entries = <BattlePatternActionPileEntry>[];
    var bonusSequence = 0;

    void addMatrixBonus({
      required String pointKey,
      required OperativePatternBonus bonus,
    }) {
      entries.add(
        BattlePatternActionPileEntry.matrixBonus(
          pointKey: pointKey,
          chainKey: 'bonus:$pointKey:${bonusSequence++}',
          bonus: bonus,
        ),
      );
    }

    for (final point in OperativePatternRequirement.normalizedSequence(
      patternPoints,
    )) {
      final pointKey = point.key;
      final patternBonus =
          resolution.activatedPatternBonusesByPointKey[pointKey] ??
              bonusesByPointKey[pointKey];
      if (patternBonus != null) {
        addMatrixBonus(pointKey: pointKey, bonus: patternBonus);
      }

      for (final adjacencyBonus
          in resolution.activatedAdjacencyBonusesAt(pointKey)) {
        addMatrixBonus(pointKey: pointKey, bonus: adjacencyBonus.bonus);
      }

      final item = equippedItemsByPointKey[pointKey];
      if (item == null) continue;
      final itemPoint = point;
      final actions = <ActionEffect>[
        ...item.actionEffects,
        ...item
            .matchingPatternEffects(
              patternPoints: patternPoints,
              itemPoint: itemPoint,
            )
            .map((effect) => effect.actionEffect),
      ];
      for (final action in actions) {
        entries.add(
          BattlePatternActionPileEntry.itemAction(
            pointKey: pointKey,
            chainKey: 'item:$pointKey',
            item: item,
            action: action,
          ),
        );
      }
    }
    return List<BattlePatternActionPileEntry>.unmodifiable(entries);
  }
}

abstract final class BattlePatternEnemyPlanner {
  static List<OperativePatternPoint> buildClosedPatternOrPass({
    required int maxPatternPoints,
    required Set<String> blockedPointKeys,
    required Map<String, Item> equippedItemsByPointKey,
    required Map<String, OperativePatternBonus> bonusesByPointKey,
    required Iterable<OperativePatternWallSegment> activeWalls,
    List<List<String>> bannedPatternPointKeys = const <List<String>>[],
  }) {
    final pattern = buildPattern(
      maxPatternPoints: maxPatternPoints,
      blockedPointKeys: blockedPointKeys,
      equippedItemsByPointKey: equippedItemsByPointKey,
      bonusesByPointKey: bonusesByPointKey,
      activeWalls: activeWalls,
      bannedPatternPointKeys: bannedPatternPointKeys,
    );
    if (OperativePatternRequirement.isClosedPattern(pattern)) {
      return pattern;
    }

    return const <OperativePatternPoint>[];
  }

  static List<OperativePatternPoint> buildPattern({
    required int maxPatternPoints,
    required Set<String> blockedPointKeys,
    required Map<String, Item> equippedItemsByPointKey,
    required Map<String, OperativePatternBonus> bonusesByPointKey,
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
      final aScore = _pointStaticPriority(
        item: equippedItemsByPointKey[a.key],
        bonus: bonusesByPointKey[a.key],
      );
      final bScore = _pointStaticPriority(
        item: equippedItemsByPointKey[b.key],
        bonus: bonusesByPointKey[b.key],
      );
      return bScore.compareTo(aScore);
    });

    final itemPointKeysByPriority = candidates
        .where((point) => equippedItemsByPointKey.containsKey(point.key))
        .toList(growable: false)
      ..sort((a, b) {
        final aScore = pointPriority(equippedItemsByPointKey[a.key]);
        final bScore = pointPriority(equippedItemsByPointKey[b.key]);
        return bScore.compareTo(aScore);
      });

    for (var targetLength = min(maxDistinctPoints, candidates.length);
        targetLength >= 3;
        targetLength--) {
      final requiredItemPointKeys = itemPointKeysByPriority
          .take(targetLength)
          .map((point) => point.key)
          .toSet();
      final bonusPrefixLength = max(
        0,
        targetLength - requiredItemPointKeys.length,
      );
      final selected = _bestClosedPattern(
        candidates: candidates,
        targetLength: targetLength,
        requiredItemPointKeys: requiredItemPointKeys,
        bonusPrefixLength: bonusPrefixLength,
        equippedItemsByPointKey: equippedItemsByPointKey,
        bonusesByPointKey: bonusesByPointKey,
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
    required Set<String> requiredItemPointKeys,
    required int bonusPrefixLength,
    required Map<String, Item> equippedItemsByPointKey,
    required Map<String, OperativePatternBonus> bonusesByPointKey,
    required Iterable<OperativePatternWallSegment> activeWalls,
    required List<List<String>> bannedPatternPointKeys,
  }) {
    List<OperativePatternPoint>? bestPattern;
    var bestScore = _EnemyPatternScore.minimum;

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
        if (!_containsRequiredItemPoints(path, requiredItemPointKeys)) {
          return;
        }
        if (!_usesBonusPrefix(
          path: path,
          bonusPrefixLength: bonusPrefixLength,
          equippedItemsByPointKey: equippedItemsByPointKey,
          bonusesByPointKey: bonusesByPointKey,
        )) {
          return;
        }
        final closedPattern = <OperativePatternPoint>[
          ...path,
          path.first,
        ];
        final score = _scoreClosedPattern(
          patternPoints: closedPattern,
          equippedItemsByPointKey: equippedItemsByPointKey,
          bonusesByPointKey: bonusesByPointKey,
        );
        if (score.compareTo(bestScore) > 0) {
          bestScore = score;
          bestPattern = List<OperativePatternPoint>.unmodifiable(path);
        }
        return;
      }

      for (final point in candidates) {
        if (usedKeys.contains(point.key)) continue;
        if (!_canUsePointAtEnemyPatternIndex(
          point: point,
          index: path.length,
          bonusPrefixLength: bonusPrefixLength,
          equippedItemsByPointKey: equippedItemsByPointKey,
          bonusesByPointKey: bonusesByPointKey,
        )) {
          continue;
        }
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

  static bool _canUsePointAtEnemyPatternIndex({
    required OperativePatternPoint point,
    required int index,
    required int bonusPrefixLength,
    required Map<String, Item> equippedItemsByPointKey,
    required Map<String, OperativePatternBonus> bonusesByPointKey,
  }) {
    final pointKey = point.key;
    if (index < bonusPrefixLength) {
      return equippedItemsByPointKey[pointKey] == null &&
          bonusesByPointKey[pointKey] != null;
    }
    return equippedItemsByPointKey[pointKey] != null;
  }

  static bool _containsRequiredItemPoints(
    List<OperativePatternPoint> path,
    Set<String> requiredItemPointKeys,
  ) {
    if (requiredItemPointKeys.isEmpty) return true;

    final usedPointKeys = path.map((point) => point.key).toSet();
    return requiredItemPointKeys.every(usedPointKeys.contains);
  }

  static bool _usesBonusPrefix({
    required List<OperativePatternPoint> path,
    required int bonusPrefixLength,
    required Map<String, Item> equippedItemsByPointKey,
    required Map<String, OperativePatternBonus> bonusesByPointKey,
  }) {
    if (bonusPrefixLength <= 0) return true;
    if (path.length < bonusPrefixLength) return false;

    for (var index = 0; index < path.length; index++) {
      final pointKey = path[index].key;
      final item = equippedItemsByPointKey[pointKey];
      final bonus = bonusesByPointKey[pointKey];
      if (index < bonusPrefixLength) {
        if (item != null || bonus == null) return false;
      } else if (item == null) {
        return false;
      }
    }
    return true;
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
        ItemActionType.attack => effect.totalValue * 4,
        ItemActionType.block => effect.totalValue * 3,
        ItemActionType.heal => effect.totalValue * 2,
        ItemActionType.none => 0,
      };
    }
    return score;
  }

  static int _pointStaticPriority({
    required Item? item,
    required OperativePatternBonus? bonus,
  }) {
    final resolvedItem = item;
    if (resolvedItem != null) {
      var score = pointPriority(resolvedItem);
      score += resolvedItem.patternEffects.length * 120;
      score += resolvedItem.passiveEffects.where((effect) {
        return effect.hook == ItemEffectHook.patternUsed ||
            effect.hook == ItemEffectHook.prePatternAttack;
      }).length * 80;
      return score;
    }

    final resolvedBonus = bonus;
    if (resolvedBonus == null) return 0;
    return 24 + _bonusKindWeight(resolvedBonus.kind) + resolvedBonus.amount;
  }

  static _EnemyPatternScore _scoreClosedPattern({
    required List<OperativePatternPoint> patternPoints,
    required Map<String, Item> equippedItemsByPointKey,
    required Map<String, OperativePatternBonus> bonusesByPointKey,
  }) {
    final sequence = OperativePatternRequirement.normalizedSequence(
      patternPoints,
    );
    var itemActionStarted = false;
    var preActionBonusCount = 0;
    var lateBonusPenalty = 0;
    var itemActionScore = 0;
    var patternActionScore = 0;
    var missedPatternActionPenalty = 0;
    var actionPointCount = 0;

    for (final point in sequence) {
      final pointKey = point.key;
      final item = equippedItemsByPointKey[pointKey];
      if (item == null) {
        final bonus = bonusesByPointKey[pointKey];
        if (bonus == null) continue;

        if (itemActionStarted) {
          lateBonusPenalty += 1 + bonus.amount;
        } else {
          preActionBonusCount++;
          itemActionScore +=
              30 + _bonusKindWeight(bonus.kind) + (bonus.amount * 4);
        }
        continue;
      }

      itemActionStarted = true;
      actionPointCount++;
      itemActionScore += pointPriority(item);

      final matchedEffects = item.matchingPatternEffects(
        patternPoints: patternPoints,
        itemPoint: point,
      );
      for (final effect in matchedEffects) {
        patternActionScore += 1;
        itemActionScore += 260 + _actionScore(effect.actionEffect);
      }

      final missedPatternEffects =
          max(0, item.patternEffects.length - matchedEffects.length);
      missedPatternActionPenalty += missedPatternEffects;

      if (item.passiveEffects.any(
        (effect) =>
            effect.hook == ItemEffectHook.patternUsed ||
            effect.hook == ItemEffectHook.prePatternAttack,
      )) {
        itemActionScore += 110;
      }
    }

    return _EnemyPatternScore(
      patternActionScore: patternActionScore,
      preActionBonusCount: preActionBonusCount,
      actionPointCount: actionPointCount,
      itemActionScore: itemActionScore,
      missedPatternActionPenalty: missedPatternActionPenalty,
      lateBonusPenalty: lateBonusPenalty,
    );
  }

  static int _actionScore(ActionEffect effect) {
    return switch (effect.actionType) {
      ItemActionType.attack => effect.totalValue * 8,
      ItemActionType.block => effect.totalValue * 5,
      ItemActionType.heal => effect.totalValue * 3,
      ItemActionType.none => max(1, effect.totalValue) * 6,
    };
  }

  static int _bonusKindWeight(OperativePatternBonusKind kind) {
    return switch (kind) {
      OperativePatternBonusKind.attack => 18,
      OperativePatternBonusKind.barrier => 12,
      OperativePatternBonusKind.health => 8,
    };
  }
}

class _EnemyPatternScore implements Comparable<_EnemyPatternScore> {
  static const minimum = _EnemyPatternScore(
    patternActionScore: -1,
    preActionBonusCount: -1,
    actionPointCount: -1,
    itemActionScore: -1,
    missedPatternActionPenalty: 999999,
    lateBonusPenalty: 999999,
  );

  final int patternActionScore;
  final int preActionBonusCount;
  final int actionPointCount;
  final int itemActionScore;
  final int missedPatternActionPenalty;
  final int lateBonusPenalty;

  const _EnemyPatternScore({
    required this.patternActionScore,
    required this.preActionBonusCount,
    required this.actionPointCount,
    required this.itemActionScore,
    required this.missedPatternActionPenalty,
    required this.lateBonusPenalty,
  });

  @override
  int compareTo(_EnemyPatternScore other) {
    final comparisons = <int>[
      (-lateBonusPenalty).compareTo(-other.lateBonusPenalty),
      preActionBonusCount.compareTo(other.preActionBonusCount),
      patternActionScore.compareTo(other.patternActionScore),
      (-missedPatternActionPenalty).compareTo(
        -other.missedPatternActionPenalty,
      ),
      actionPointCount.compareTo(other.actionPointCount),
      itemActionScore.compareTo(other.itemActionScore),
    ];

    for (final comparison in comparisons) {
      if (comparison != 0) return comparison;
    }
    return 0;
  }
}
