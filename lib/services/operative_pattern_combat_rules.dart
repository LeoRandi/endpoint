import '../entities/_exports.dart';

abstract final class OperativePatternCombatRules {
  static const int initialMaxPatternPoints = 3;
  static const int initialMaxBlockingPoints = 2;

  static int maxPatternPointsFor(Battler player) {
    return initialMaxPatternPoints +
        Battler.evenLevelProgressionBonusFor(player.level) +
        _archetypePatternPointBonus(player) +
        _itemPatternPointBonus(player);
  }

  static int maxBlockingPointsFor(Battler player) {
    return initialMaxBlockingPoints +
        Battler.evenLevelProgressionBonusFor(player.level) +
        _itemBlockingPointBonus(player);
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

  static int _itemPatternPointBonus(Battler player) {
    return player.equippedItems
        .where((item) => item.id == ItemId.buzonVirtualAzul)
        .length;
  }

  static int _itemBlockingPointBonus(Battler player) {
    return player.equippedItems
        .where((item) => item.id == ItemId.passCard)
        .length;
  }
}
