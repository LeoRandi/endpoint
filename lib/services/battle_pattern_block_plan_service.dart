import 'dart:math';

import '../entities/_exports.dart';

enum BattlePatternBlockMode {
  pass,
  randomOne,
  itemOne,
  randomTwo,
  randomAndItem,
  mostUsedItem,
  randomThree,
  itemTwo,
  randomAndMostUsed,
}

class BattlePatternBlockPlan {
  final BattlePatternBlockMode mode;
  final List<OperativePatternPoint> points;

  const BattlePatternBlockPlan({
    required this.mode,
    required this.points,
  });

  Set<String> get pointKeys => Set<String>.unmodifiable(
        points.map((point) => point.key),
      );
}

abstract final class BattlePatternBlockPlanService {
  static BattlePatternBlockPlan resolve({
    required int enemyTier,
    required int combatRound,
    required int maxBlockingPoints,
    required Map<String, Item> equippedItemsByPointKey,
    required Map<String, int> itemPointUseCounts,
    required BattlePatternBlockMode? previousYellowBlockMode,
    required int Function(int max) nextInt,
  }) {
    if (maxBlockingPoints <= 0) {
      return const BattlePatternBlockPlan(
        mode: BattlePatternBlockMode.pass,
        points: <OperativePatternPoint>[],
      );
    }

    final mode = _modeFor(
      enemyTier: enemyTier,
      combatRound: combatRound,
      previousYellowBlockMode: previousYellowBlockMode,
      nextInt: nextInt,
    );
    final points = _pointsForMode(
      mode: mode,
      equippedItemsByPointKey: equippedItemsByPointKey,
      itemPointUseCounts: itemPointUseCounts,
      nextInt: nextInt,
    );
    final cappedPointCount = max(0, maxBlockingPoints);
    final cappedPoints = points.take(cappedPointCount).toList(growable: false);

    return BattlePatternBlockPlan(
      mode: mode,
      points: cappedPoints.isEmpty
          ? _randomPoints(
              count: 1,
              excludedPointKeys: const <String>{},
              nextInt: nextInt,
            )
          : List<OperativePatternPoint>.unmodifiable(cappedPoints),
    );
  }

  static BattlePatternBlockMode _modeFor({
    required int enemyTier,
    required int combatRound,
    required BattlePatternBlockMode? previousYellowBlockMode,
    required int Function(int max) nextInt,
  }) {
    final safeTier = max(1, enemyTier);
    final isOddRound = combatRound.isOdd;

    if (safeTier >= RarityTier.yellow.factor) {
      const yellowModes = <BattlePatternBlockMode>[
        BattlePatternBlockMode.randomThree,
        BattlePatternBlockMode.itemTwo,
        BattlePatternBlockMode.randomAndMostUsed,
      ];
      final availableModes = yellowModes
          .where((mode) => mode != previousYellowBlockMode)
          .toList(growable: false);
      final choices = availableModes.isEmpty ? yellowModes : availableModes;
      return choices[nextInt(choices.length)];
    }
    if (safeTier >= RarityTier.purple.factor) {
      return isOddRound
          ? BattlePatternBlockMode.randomAndItem
          : BattlePatternBlockMode.mostUsedItem;
    }
    if (safeTier >= RarityTier.blue.factor) {
      return isOddRound
          ? BattlePatternBlockMode.randomTwo
          : BattlePatternBlockMode.itemOne;
    }
    if (safeTier >= RarityTier.green.factor) {
      return isOddRound
          ? BattlePatternBlockMode.randomOne
          : BattlePatternBlockMode.itemOne;
    }

    return BattlePatternBlockMode.randomOne;
  }

  static List<OperativePatternPoint> _pointsForMode({
    required BattlePatternBlockMode mode,
    required Map<String, Item> equippedItemsByPointKey,
    required Map<String, int> itemPointUseCounts,
    required int Function(int max) nextInt,
  }) {
    final selected = <OperativePatternPoint>[];
    final selectedPointKeys = <String>{};

    void addPoint(OperativePatternPoint? point) {
      if (point == null || !selectedPointKeys.add(point.key)) return;
      selected.add(point);
    }

    void addRandomPoints(int count) {
      for (final point in _randomPoints(
        count: count,
        excludedPointKeys: selectedPointKeys,
        nextInt: nextInt,
      )) {
        addPoint(point);
      }
    }

    void addRandomItemPoints(int count) {
      final before = selected.length;
      for (final point in _randomItemPoints(
        count: count,
        equippedItemsByPointKey: equippedItemsByPointKey,
        excludedPointKeys: selectedPointKeys,
        nextInt: nextInt,
      )) {
        addPoint(point);
      }
      final added = selected.length - before;
      if (added < count) {
        addRandomPoints(count - added);
      }
    }

    switch (mode) {
      case BattlePatternBlockMode.pass:
        break;
      case BattlePatternBlockMode.randomOne:
        addRandomPoints(1);
        break;
      case BattlePatternBlockMode.itemOne:
        addRandomItemPoints(1);
        break;
      case BattlePatternBlockMode.randomTwo:
        addRandomPoints(2);
        break;
      case BattlePatternBlockMode.randomAndItem:
        addRandomItemPoints(1);
        addRandomPoints(1);
        break;
      case BattlePatternBlockMode.mostUsedItem:
        addPoint(
          _mostUsedItemPoint(
            equippedItemsByPointKey: equippedItemsByPointKey,
            itemPointUseCounts: itemPointUseCounts,
            nextInt: nextInt,
          ),
        );
        if (selected.isEmpty) addRandomPoints(1);
        break;
      case BattlePatternBlockMode.randomThree:
        addRandomPoints(3);
        break;
      case BattlePatternBlockMode.itemTwo:
        addRandomItemPoints(2);
        break;
      case BattlePatternBlockMode.randomAndMostUsed:
        final mostUsedPoint = _mostUsedItemPoint(
          equippedItemsByPointKey: equippedItemsByPointKey,
          itemPointUseCounts: itemPointUseCounts,
          nextInt: nextInt,
        );
        if (mostUsedPoint == null) {
          addRandomPoints(2);
        } else {
          addPoint(mostUsedPoint);
          addRandomPoints(1);
        }
        break;
    }

    return List<OperativePatternPoint>.unmodifiable(selected);
  }

  static OperativePatternPoint? _mostUsedItemPoint({
    required Map<String, Item> equippedItemsByPointKey,
    required Map<String, int> itemPointUseCounts,
    required int Function(int max) nextInt,
  }) {
    final candidates = equippedItemsByPointKey.entries
        .where((entry) => operativePatternPointsByKey.containsKey(entry.key))
        .toList(growable: false);
    if (candidates.isEmpty) return null;

    final highestUseCount = candidates
        .map((entry) => max(0, itemPointUseCounts[entry.key] ?? 0))
        .reduce(max);
    final mostUsedCandidates = candidates
        .where(
          (entry) =>
              max(0, itemPointUseCounts[entry.key] ?? 0) == highestUseCount,
        )
        .toList(growable: false);
    final highestTier = mostUsedCandidates
        .map((entry) => entry.value.rarity.factor)
        .reduce(max);
    final highestTierCandidates = mostUsedCandidates
        .where((entry) => entry.value.rarity.factor == highestTier)
        .toList(growable: false);
    final selectedEntry =
        highestTierCandidates[nextInt(highestTierCandidates.length)];

    return operativePatternPointsByKey[selectedEntry.key];
  }

  static List<OperativePatternPoint> _randomItemPoints({
    required int count,
    required Map<String, Item> equippedItemsByPointKey,
    required Set<String> excludedPointKeys,
    required int Function(int max) nextInt,
  }) {
    final candidates = <OperativePatternPoint>[
      for (final pointKey in equippedItemsByPointKey.keys)
        if (!excludedPointKeys.contains(pointKey) &&
            operativePatternPointsByKey[pointKey] != null)
          operativePatternPointsByKey[pointKey]!,
    ];

    return _takeRandom(
      candidates: candidates,
      count: count,
      nextInt: nextInt,
    );
  }

  static List<OperativePatternPoint> _randomPoints({
    required int count,
    required Set<String> excludedPointKeys,
    required int Function(int max) nextInt,
  }) {
    final candidates = <OperativePatternPoint>[
      for (final point in operativePatternPoints)
        if (!excludedPointKeys.contains(point.key)) point,
    ];

    return _takeRandom(
      candidates: candidates,
      count: count,
      nextInt: nextInt,
    );
  }

  static List<OperativePatternPoint> _takeRandom({
    required List<OperativePatternPoint> candidates,
    required int count,
    required int Function(int max) nextInt,
  }) {
    if (count <= 0 || candidates.isEmpty) {
      return const <OperativePatternPoint>[];
    }

    final pool = List<OperativePatternPoint>.from(candidates);
    final selected = <OperativePatternPoint>[];
    while (selected.length < count && pool.isNotEmpty) {
      selected.add(pool.removeAt(nextInt(pool.length)));
    }

    return List<OperativePatternPoint>.unmodifiable(selected);
  }
}
