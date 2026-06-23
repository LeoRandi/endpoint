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
        ..._buildMailboxRewards(
          player: player,
          randomizer: randomizer,
        ),
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
    final lootItems = <ItemId, Item>{
      for (final item in [
        ...enemy.equippedItems,
        ...enemy.inventoryItems,
      ])
        item.id: _runtimeService.runtimeItem(item, forceNewInstance: true),
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

  List<BattleItemReward> _buildMailboxRewards({
    required Battler player,
    required RunRandomizer randomizer,
  }) {
    var projectedPlayer = player;
    final rewards = <BattleItemReward>[];

    for (final mailbox in player.equippedItems.where(_isVirtualMailbox)) {
      final candidates = itemPresets.where((candidate) {
        return candidate.id != mailbox.id &&
            candidate.rarity == mailbox.rarity &&
            candidate.hasTag(_mailboxFocusTag(mailbox)) &&
            projectedPlayer.canReceiveItemInInventoryOrEquipment(candidate);
      }).toList(growable: false);
      if (candidates.isEmpty) continue;

      final selected = candidates[randomizer.nextInt(candidates.length)];
      final rewardItem = _runtimeService.runtimeItem(
        selected,
        forceNewInstance: true,
      );
      rewards.add(BattleItemReward(item: rewardItem, sourceItem: mailbox));

      final previousSuppression = CodexDiscoveryHook.isSuppressed;
      CodexDiscoveryHook.isSuppressed = true;
      projectedPlayer =
          projectedPlayer.addItemToInventoryOrEquipment(rewardItem);
      CodexDiscoveryHook.isSuppressed = previousSuppression;
    }

    return List<BattleItemReward>.unmodifiable(rewards);
  }

  bool _isVirtualMailbox(Item item) {
    return item.id == ItemId.buzonVirtualAzul ||
        item.id == ItemId.buzonVirtualRojo ||
        item.id == ItemId.buzonVirtualVerde;
  }

  EntityTag _mailboxFocusTag(Item item) {
    switch (item.id) {
      case ItemId.buzonVirtualAzul:
        return item.rarity.index <= RarityTier.gray.index
            ? EntityTag.accesorio
            : EntityTag.ciclo;
      case ItemId.buzonVirtualRojo:
        return item.rarity.index <= RarityTier.gray.index
            ? EntityTag.ataque
            : EntityTag.quemadura;
      case ItemId.buzonVirtualVerde:
        return item.rarity.index <= RarityTier.green.index
            ? EntityTag.barrera
            : EntityTag.resonancia;
      default:
        return EntityTag.economia;
    }
  }
}
