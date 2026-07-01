import '../../entities/_exports.dart';

enum BattlePatternActionPileEntryKind {
  itemAction,
  matrixBonus,
}

class BattlePatternActionPileEntry {
  final BattlePatternActionPileEntryKind kind;
  final String pointKey;
  final String chainKey;
  final Item? item;
  final ActionEffect? action;
  final OperativePatternBonus? bonus;

  const BattlePatternActionPileEntry.itemAction({
    required this.pointKey,
    required this.chainKey,
    required Item this.item,
    required ActionEffect this.action,
  })  : kind = BattlePatternActionPileEntryKind.itemAction,
        bonus = null;

  const BattlePatternActionPileEntry.matrixBonus({
    required this.pointKey,
    required this.chainKey,
    required OperativePatternBonus this.bonus,
  })  : kind = BattlePatternActionPileEntryKind.matrixBonus,
        item = null,
        action = null;

  ItemActionType get actionType {
    final resolvedAction = action;
    if (resolvedAction != null) return resolvedAction.actionType;

    final resolvedBonus = bonus;
    if (resolvedBonus == null) return ItemActionType.none;
    return switch (resolvedBonus.kind) {
      OperativePatternBonusKind.attack => ItemActionType.attack,
      OperativePatternBonusKind.barrier => ItemActionType.block,
      OperativePatternBonusKind.health => ItemActionType.heal,
    };
  }

  int get value => action?.totalValue ?? bonus?.amount ?? 0;
}

class BattlePatternActionPileStep {
  final int playerIndex;
  final int enemyIndex;
  final bool playerActs;
  final bool enemyActs;

  const BattlePatternActionPileStep({
    required this.playerIndex,
    required this.enemyIndex,
    required this.playerActs,
    required this.enemyActs,
  });
}

typedef BattlePatternActionPileStepCallback = Future<void> Function(
  BattlePatternActionPileStep step,
);

typedef BattlePatternActionPileUpdateCallback = Future<void> Function({
  required bool isPlayer,
  required List<BattlePatternActionPileEntry> entries,
});
