import 'dart:math';

import '../entities/_exports.dart';

class OperativePatternLayoutResult {
  final Battler player;
  final Map<String, Item> itemsByPointKey;

  const OperativePatternLayoutResult({
    required this.player,
    required this.itemsByPointKey,
  });
}

abstract final class OperativePatternLayoutService {
  static OperativePatternLayoutResult resolveForPlayer({
    required Battler player,
    Random? random,
  }) {
    final equippedItems = player.equippedItems;
    final validPointKeys =
        operativePatternPoints.map((point) => point.key).toSet();
    final equippedItemKeys = equippedItems.map(itemKey).toSet();
    final existingAssignments = Map<String, String>.from(
      player.patternItemPointKeys,
    )..removeWhere(
        (itemKey, pointKey) =>
            !equippedItemKeys.contains(itemKey) ||
            !validPointKeys.contains(pointKey),
      );

    final usedPointKeys = <String>{};
    final resolvedAssignments = <String, String>{};
    for (final item in equippedItems) {
      final key = itemKey(item);
      final assignedPointKey = existingAssignments[key];
      if (assignedPointKey == null ||
          usedPointKeys.contains(assignedPointKey)) {
        continue;
      }

      resolvedAssignments[key] = assignedPointKey;
      usedPointKeys.add(assignedPointKey);
    }

    final randomizer = random ?? Random();
    final availablePointKeys = operativePatternPoints
        .map((point) => point.key)
        .where((pointKey) => !usedPointKeys.contains(pointKey))
        .toList(growable: false)
      ..shuffle(randomizer);

    var nextPointIndex = 0;
    for (final item in equippedItems) {
      final key = itemKey(item);
      if (resolvedAssignments.containsKey(key)) continue;
      if (nextPointIndex >= availablePointKeys.length) break;

      resolvedAssignments[key] = availablePointKeys[nextPointIndex++];
    }

    final itemsByPointKey = <String, Item>{};
    for (final item in equippedItems) {
      final pointKey = resolvedAssignments[itemKey(item)];
      if (pointKey == null) continue;
      itemsByPointKey[pointKey] = item;
    }

    final resolvedPatternItemPointKeys = Map<String, String>.unmodifiable(
      resolvedAssignments,
    );
    return OperativePatternLayoutResult(
      player: _sameStringMap(
        player.patternItemPointKeys,
        resolvedPatternItemPointKeys,
      )
          ? player
          : player.copyWith(
              patternItemPointKeys: resolvedPatternItemPointKeys,
            ),
      itemsByPointKey: Map<String, Item>.unmodifiable(itemsByPointKey),
    );
  }

  static Battler rememberItemPoint({
    required Battler player,
    required Item item,
    required String pointKey,
  }) {
    final isValidPoint = operativePatternPoints.any(
      (point) => point.key == pointKey,
    );
    if (!isValidPoint) return player;

    final key = itemKey(item);
    final nextAssignments = Map<String, String>.from(
      player.patternItemPointKeys,
    )..removeWhere(
        (otherKey, assignedPointKey) =>
            otherKey != key && assignedPointKey == pointKey,
      );
    nextAssignments[key] = pointKey;

    return player.copyWith(
      patternItemPointKeys: Map<String, String>.unmodifiable(nextAssignments),
    );
  }

  static Battler forgetItem({
    required Battler player,
    required Item item,
  }) {
    final key = itemKey(item);
    if (!player.patternItemPointKeys.containsKey(key)) return player;

    final nextAssignments = Map<String, String>.from(
      player.patternItemPointKeys,
    )..remove(key);
    return player.copyWith(
      patternItemPointKeys: Map<String, String>.unmodifiable(nextAssignments),
    );
  }

  static String itemKey(Item item) {
    return item.instanceId ?? '${item.id.name}:${identityHashCode(item)}';
  }

  static bool _sameStringMap(
    Map<String, String> first,
    Map<String, String> second,
  ) {
    if (identical(first, second)) return true;
    if (first.length != second.length) return false;

    for (final entry in first.entries) {
      if (second[entry.key] != entry.value) return false;
    }
    return true;
  }
}
