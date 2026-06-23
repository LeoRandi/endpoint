part of '../path_event_service.dart';

/// Auction, sacrifice, and ability-swap use cases for Su Basta Ya.
extension SuBastaYaPathEventHandler on PathEventService {
  List<Item> buildSuBastaYaEligibleItems(Battler player) {
    return List<Item>.unmodifiable([
      ...player.equippedItems,
      ...player.inventoryItems,
    ]);
  }

  List<BattlerAbility> buildSuBastaYaEligibleAbilities(Battler player) {
    return List<BattlerAbility>.unmodifiable(player.abilities);
  }

  int suBastaYaAuctionPriceFor(Item item) {
    return max(item.cost, item.sellValue * 3);
  }

  Map<BattlerStat, int> suBastaYaStatRewardFor({
    required Item item,
    required SuBastaYaStatReward selectedReward,
  }) {
    if (item.rarity == RarityTier.yellow) {
      return const <BattlerStat, int>{
        BattlerStat.health: 15,
        BattlerStat.attack: 3,
        BattlerStat.barrier: 3,
      };
    }

    final factor = max(1, item.rarity.factor);
    return <BattlerStat, int>{
      selectedReward.stat:
          selectedReward == SuBastaYaStatReward.health ? 5 * factor : factor,
    };
  }

  PathEventVisitResult resolveSuBastaYaAuctionSale({
    required Battler player,
    required Item selectedItem,
  }) {
    if (!_ownsItem(player, selectedItem)) {
      return PathEventVisitResult(
        player: player,
        outcomeText: 'Ese objeto ya no esta disponible para subasta.',
      );
    }

    final payout = suBastaYaAuctionPriceFor(selectedItem);
    final updatedPlayer = player.removeItem(selectedItem).earnMoney(payout);
    return PathEventVisitResult(
      player: updatedPlayer,
      outcomeText: 'Subastas ${selectedItem.displayName} y cobras ${payout}C.',
    );
  }

  PathEventVisitResult resolveSuBastaYaStatSacrifice({
    required Battler player,
    required Item selectedItem,
    required SuBastaYaStatReward selectedReward,
  }) {
    if (!_ownsItem(player, selectedItem)) {
      return PathEventVisitResult(
        player: player,
        outcomeText: 'Ese objeto ya no esta disponible para reciclar.',
      );
    }

    final statRewards = suBastaYaStatRewardFor(
      item: selectedItem,
      selectedReward: selectedReward,
    );
    final updatedPlayer = _applyPermanentStatRewards(
      player.removeItem(selectedItem),
      statRewards,
    );
    return PathEventVisitResult(
      player: updatedPlayer,
      outcomeText:
          'Entregas ${selectedItem.displayName}. Recibes ${_statRewardSummary(statRewards)} permanente.',
    );
  }

  PathEventVisitResult resolveSuBastaYaAbilitySwap({
    required Battler player,
    required BattlerAbility selectedAbility,
    required RunRandomizer randomizer,
  }) {
    if (player.abilityById(selectedAbility.id) == null) {
      return PathEventVisitResult(
        player: player,
        outcomeText: 'Esa habilidad ya no esta disponible para intercambiar.',
      );
    }

    final replacementAbility = _rollSuBastaYaReplacementAbility(
      selectedAbility: selectedAbility,
      player: player,
      randomizer: randomizer,
    );
    final updatedPlayer = player.replaceAbility(
      currentAbility: selectedAbility,
      replacementAbility: replacementAbility,
    );

    return PathEventVisitResult(
      player: updatedPlayer,
      outcomeText:
          'Cambias ${selectedAbility.displayName} por ${replacementAbility.displayName}.',
      gainedAbility: replacementAbility,
    );
  }
}
