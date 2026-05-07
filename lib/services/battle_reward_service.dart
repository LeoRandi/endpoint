import '_imports.dart';

class BattleRewardBundle {
  final Item? lootItem;
  final BattlerAbility? lootAbility;
  final int moneyReward;

  const BattleRewardBundle({
    this.lootItem,
    this.lootAbility,
    this.moneyReward = 0,
  }) : assert(lootItem == null || lootAbility == null);

  bool get hasRewards =>
      lootItem != null || lootAbility != null || moneyReward > 0;
}

class BattleRewardService {
  const BattleRewardService();

  BattleRewardBundle buildVictoryRewards({
    required Battler enemy,
    required Battler player,
    required int victoryMoneyFactor,
    required RunRandomizer randomizer,
  }) {
    final lootReward = _selectVictoryLoot(
      enemy: enemy,
      player: player,
      randomizer: randomizer,
    );

    return BattleRewardBundle(
      lootItem: lootReward.lootItem,
      lootAbility: lootReward.lootAbility,
      moneyReward: _buildVictoryMoneyReward(
        player: player,
        victoryMoneyFactor: victoryMoneyFactor,
      ),
    );
  }

  BattleFlowResult sanitizeExitResult(BattleFlowResult exitResult) {
    return BattleFlowResult(
      type: exitResult.type,
      player: exitResult.player.finalizeCombatState(),
    );
  }

  int _buildVictoryMoneyReward({
    required Battler player,
    required int victoryMoneyFactor,
  }) {
    return max(0, player.income * victoryMoneyFactor);
  }

  BattleRewardBundle _selectVictoryLoot({
    required Battler enemy,
    required Battler player,
    required RunRandomizer randomizer,
  }) {
    final lootItems = <ItemId, Item>{
      for (final item in [
        ...enemy.equippedItems,
        ...enemy.inventoryItems,
      ])
        item.id: item,
    }.values.toList(growable: false);
    final lootAbilities = <BattlerAbilityId, BattlerAbility>{
      for (final ability in enemy.abilities)
        if (_canOfferAbilityLoot(player: player, ability: ability))
          ability.id: ability.resetState(),
    }.values.toList(growable: false);
    final totalLootCount = lootItems.length + lootAbilities.length;
    if (totalLootCount <= 0) {
      return const BattleRewardBundle();
    }

    final selectedIndex = randomizer.nextInt(totalLootCount);
    if (selectedIndex < lootItems.length) {
      return BattleRewardBundle(lootItem: lootItems[selectedIndex]);
    }

    return BattleRewardBundle(
      lootAbility: lootAbilities[selectedIndex - lootItems.length],
    );
  }

  bool _canOfferAbilityLoot({
    required Battler player,
    required BattlerAbility ability,
  }) {
    final ownedAbility = player.abilityById(ability.id);
    if (ownedAbility == null) return true;

    return ownedAbility.rarity == ability.rarity && ownedAbility.canUpgrade;
  }
}
