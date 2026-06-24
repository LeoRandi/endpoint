import '_imports.dart';

class BattleItemReward {
  final Item item;
  final Item? sourceItem;

  const BattleItemReward({
    required this.item,
    this.sourceItem,
  });

  bool get hasSource => sourceItem != null;
}

class BattleRewardBundle {
  final Item? lootItem;
  final BattlerAbility? lootAbility;
  final int moneyReward;
  final List<BattleItemReward> itemRewards;

  BattleRewardBundle({
    this.lootItem,
    this.lootAbility,
    this.moneyReward = 0,
    List<BattleItemReward>? itemRewards,
  })  : assert(lootItem == null || lootAbility == null),
        itemRewards = List<BattleItemReward>.unmodifiable(
          itemRewards ??
              [
                if (lootItem != null) BattleItemReward(item: lootItem),
              ],
        );

  bool get hasRewards =>
      itemRewards.isNotEmpty || lootAbility != null || moneyReward > 0;
}

class BattleRewardService {
  final CatalogRuntimeService _runtimeService;

  const BattleRewardService({
    CatalogRuntimeService runtimeService = const CatalogRuntimeService(),
  }) : _runtimeService = runtimeService;

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
      itemRewards: [
        if (lootReward.lootItem != null)
          BattleItemReward(item: lootReward.lootItem!),
      ],
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
    final lootItems = <String, Item>{
      for (final item in [
        ...enemy.equippedItems,
        ...enemy.inventoryItems,
      ])
        item.catalogKey:
            _runtimeService.runtimeItem(item, forceNewInstance: true),
    }.values.toList(growable: false);
    final lootAbilities = <BattlerAbilityId, BattlerAbility>{
      for (final ability in enemy.abilities)
        if (_canOfferAbilityLoot(player: player, ability: ability))
          ability.id: _runtimeService.runtimeAbility(ability),
    }.values.toList(growable: false);
    final totalLootCount = lootItems.length + lootAbilities.length;
    if (totalLootCount <= 0) {
      return BattleRewardBundle();
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
