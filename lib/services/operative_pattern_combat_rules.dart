import '../entities/_exports.dart';

abstract final class OperativePatternCombatRules {
  static const int initialMaxPatternPoints = 3;

  static int maxPatternPointsFor(Battler player) {
    return initialMaxPatternPoints +
        Battler.evenLevelProgressionBonusFor(player.level) +
        _archetypePatternPointBonus(player);
  }

  static int _archetypePatternPointBonus(Battler player) {
    switch (player.archetypeId) {
      case ArchetypeId.veloz:
        return 2;
      case ArchetypeId.imparable:
      case ArchetypeId.inamovible:
      case ArchetypeId.mercante:
        return 1;
      case null:
        return 0;
    }
  }
}
