import 'dart:math';

import '../entities/_exports.dart';

abstract final class OperativePatternCombatRules {
  static const int initialMaxPatternPoints = 3;

  static int maxPatternPointsFor(Battler player) {
    final levelBonus = max(0, player.level - Battler.initialLevel);
    final freeCapacityBonus = max(
      0,
      player.remainingEquipmentCapacity - Battler.defaultEquipmentCapacity,
    );
    return initialMaxPatternPoints + levelBonus + freeCapacityBonus;
  }
}
