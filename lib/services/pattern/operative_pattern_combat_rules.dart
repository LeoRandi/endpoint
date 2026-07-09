import 'dart:math';

import '../../entities/_exports.dart';

abstract final class OperativePatternCombatRules {
  static const int initialMaxPatternPoints = 3;
  static const int initialMaxBlockingPoints = 2;
  static const int wallBlockingPointCost = 3;
  static const int pointBlockingPointCost = 1;

  static int maxPatternPointsFor(Battler player) {
    return initialMaxPatternPoints +
        Battler.evenLevelProgressionBonusFor(player.level) +
        _archetypePatternPointBonus(player);
  }

  static int maxBlockingPointsFor(Battler player) {
    return max(
      0,
      initialMaxBlockingPoints +
          Battler.evenLevelProgressionBonusFor(player.level),
    );
  }

  static int wallActionsPerBlockingTurnFor(Battler player) {
    return 1;
  }

  static int _archetypePatternPointBonus(Battler player) {
    switch (player.archetypeId) {
      case ArchetypeId.crepitans:
        return 2;
      case ArchetypeId.hercules:
      case ArchetypeId.diabolicus:
      case ArchetypeId.sacer:
        return 1;
      case null:
        return 0;
    }
  }
}
