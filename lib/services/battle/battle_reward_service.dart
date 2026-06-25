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
  final Augment? lootAugment;
  final int moneyReward;
  final List<BattleItemReward> itemRewards;

  BattleRewardBundle({
    this.lootItem,
    this.lootAugment,
    this.moneyReward = 0,
    List<BattleItemReward>? itemRewards,
  })  : assert(lootItem == null || lootAugment == null),
        itemRewards = List<BattleItemReward>.unmodifiable(
          itemRewards ??
              [
                if (lootItem != null) BattleItemReward(item: lootItem),
              ],
        );

  bool get hasRewards =>
      itemRewards.isNotEmpty || lootAugment != null || moneyReward > 0;
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
      lootAugment: lootReward.lootAugment,
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
    final lootAugments = <int, Augment>{
      for (final augment in enemy.augments)
        if (_canOfferAugmentLoot(player: player, augment: augment))
          augment.id: _runtimeService.runtimeAugment(augment),
    }.values.toList(growable: false);
    final totalLootCount = lootItems.length + lootAugments.length;
    if (totalLootCount <= 0) {
      return BattleRewardBundle();
    }

    final selectedIndex = randomizer.nextInt(totalLootCount);
    if (selectedIndex < lootItems.length) {
      return BattleRewardBundle(lootItem: lootItems[selectedIndex]);
    }

    return BattleRewardBundle(
      lootAugment: lootAugments[selectedIndex - lootItems.length],
    );
  }

  bool _canOfferAugmentLoot({
    required Battler player,
    required Augment augment,
  }) {
    final ownedAugment = player.augmentById(augment.id);
    if (ownedAugment == null) return true;

    return ownedAugment.rarity == augment.rarity && ownedAugment.canUpgrade;
  }
}
