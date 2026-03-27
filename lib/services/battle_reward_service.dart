import '_imports.dart';

class BattleRewardBundle {
  final Item? lootItem;
  final int moneyReward;

  const BattleRewardBundle({
    this.lootItem,
    this.moneyReward = 0,
  });

  bool get hasRewards => lootItem != null || moneyReward > 0;
}

class BattleRewardService {
  const BattleRewardService();

  BattleRewardBundle buildVictoryRewards({
    required Battler enemy,
    required Battler player,
    required int victoryMoneyFactor,
    required RunRandomizer randomizer,
  }) {
    return BattleRewardBundle(
      lootItem: _selectVictoryLoot(
        enemy: enemy,
        player: player,
        randomizer: randomizer,
      ),
      moneyReward: _buildVictoryMoneyReward(
        player: player,
        victoryMoneyFactor: victoryMoneyFactor,
      ),
    );
  }

  BattleFlowResult sanitizeExitResult(BattleFlowResult exitResult) {
    return BattleFlowResult(
      type: exitResult.type,
      player: exitResult.player
          .resetAbilitiesForContext(
            BattlerAbilityActivationContext.battle,
          )
          .clearCombatFlags(),
    );
  }

  int _buildVictoryMoneyReward({
    required Battler player,
    required int victoryMoneyFactor,
  }) {
    return max(0, player.income * victoryMoneyFactor);
  }

  Item? _selectVictoryLoot({
    required Battler enemy,
    required Battler player,
    required RunRandomizer randomizer,
  }) {
    final lootPool = <ItemId, Item>{
      for (final item in [
        ...enemy.equippedItems,
        ...enemy.inventoryItems,
      ])
        item.id: item,
    }.values.toList(growable: false);
    if (lootPool.isEmpty) return null;

    final preferredPool = lootPool
        .where((item) => !player.ownsItemOfType(item.id))
        .toList(growable: false);
    final resolvedPool = preferredPool.isNotEmpty ? preferredPool : lootPool;

    return resolvedPool[randomizer.nextInt(resolvedPool.length)];
  }
}
