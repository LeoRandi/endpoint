import '../entities/_exports.dart';

class BattleAttackDrawingBonus {
  final int attackBonus;
  final int healAmount;
  final int endTurnBarrierAmount;

  const BattleAttackDrawingBonus({
    this.attackBonus = 0,
    this.healAmount = 0,
    this.endTurnBarrierAmount = 0,
  });

  static const BattleAttackDrawingBonus empty = BattleAttackDrawingBonus();

  bool get hasAnyBonus =>
      attackBonus > 0 || healAmount > 0 || endTurnBarrierAmount > 0;
}

class BattleDrawingBonusResolution {
  final BattleAttackDrawingBonus bonus;
  final List<Item> activatedItems;
  final Map<ItemBonusShape, int> recognizedCounts;

  const BattleDrawingBonusResolution({
    this.bonus = BattleAttackDrawingBonus.empty,
    this.activatedItems = const <Item>[],
    this.recognizedCounts = const <ItemBonusShape, int>{},
  });

  bool get hasActivatedItems => activatedItems.isNotEmpty;

  bool isItemActivated(Item item) {
    return activatedItems.any(
      (candidate) => _matchesOwnedItem(candidate, item),
    );
  }

  static bool _matchesOwnedItem(Item first, Item second) {
    final firstInstanceId = first.instanceId;
    final secondInstanceId = second.instanceId;
    if (firstInstanceId != null &&
        secondInstanceId != null &&
        firstInstanceId == secondInstanceId) {
      return true;
    }

    return identical(first, second) || first.id == second.id;
  }
}

class BattleDrawingBonusResolver {
  const BattleDrawingBonusResolver();

  BattleDrawingBonusResolution resolve({
    required List<Item> equippedItems,
    required Map<ItemBonusShape, int> recognizedCounts,
  }) {
    if (equippedItems.isEmpty || recognizedCounts.isEmpty) {
      return BattleDrawingBonusResolution(
        recognizedCounts: Map<ItemBonusShape, int>.unmodifiable(
          recognizedCounts,
        ),
      );
    }

    final remainingCounts = <ItemBonusShape, int>{
      for (final entry in recognizedCounts.entries)
        entry.key: entry.value.clamp(0, 9999).toInt(),
    };
    final activatedItems = <Item>[];
    var attackBonus = 0;
    var healAmount = 0;
    var endTurnBarrierAmount = 0;

    for (final item in equippedItems) {
      final shape = item.bonusShape;
      final remaining = remainingCounts[shape] ?? 0;
      if (remaining <= 0) continue;

      activatedItems.add(item);
      remainingCounts[shape] = remaining - 1;
      final specialBonus = item.specialBonus;
      switch (specialBonus.kind) {
        case ItemSpecialBonusKind.attack:
          attackBonus += specialBonus.amount;
          break;
        case ItemSpecialBonusKind.barrierOnTurnEnd:
          endTurnBarrierAmount += specialBonus.amount;
          break;
        case ItemSpecialBonusKind.heal:
          healAmount += specialBonus.amount;
          break;
      }
    }

    return BattleDrawingBonusResolution(
      bonus: BattleAttackDrawingBonus(
        attackBonus: attackBonus,
        healAmount: healAmount,
        endTurnBarrierAmount: endTurnBarrierAmount,
      ),
      activatedItems: List<Item>.unmodifiable(activatedItems),
      recognizedCounts: Map<ItemBonusShape, int>.unmodifiable(recognizedCounts),
    );
  }
}
