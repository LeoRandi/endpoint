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
        _archetypePatternPointBonus(player) +
        _itemPatternPointBonus(player);
  }

  static int maxBlockingPointsFor(Battler player) {
    return max(
      0,
      initialMaxBlockingPoints +
          Battler.evenLevelProgressionBonusFor(player.level) +
          _itemBlockingPointBonus(player),
    );
  }

  static int wallActionsPerBlockingTurnFor(Battler player) {
    return 1 +
        player.equippedItems
            .where((item) => item.id == ItemId.tonfasEscudo)
            .length;
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
    return player.equippedItems.fold<int>(0, (total, item) {
      return total +
          switch (item.id) {
            ItemId.passCard => 1,
            ItemId.tonfasEscudo => -1,
            ItemId.constructionSeal => 4,
            ItemId.compraAgresiva => player.itemCombatFlagValue(
                      item: item,
                      kind: ItemCombatFlagKind.compraAgresivaBpUnlocked,
                    ) !=
                    null
                ? 1
                : 0,
            _ => 0,
          };
    });
  }
}
