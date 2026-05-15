import '../entities/_exports.dart';

abstract final class OperativePatternCombatRules {
  static const int initialMaxPatternPoints = 3;

  static int maxPatternPointsFor(Battler player) {
    return initialMaxPatternPoints +
        Battler.evenLevelProgressionBonusFor(player.level);
  }
}
