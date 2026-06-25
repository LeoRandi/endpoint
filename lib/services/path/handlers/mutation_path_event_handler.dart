part of '../path_event_service.dart';

/// Item and augment mutation use cases for Sobre Kar and Technosurgeon events.
extension MutationPathEventHandler on PathEventService {
  List<Item> buildSobreKarEligibleItems(Battler player) {
    final eligibleItems = [
      ...player.equippedItems,
      ...player.inventoryItems,
    ].where(_isSobreKarItemEligible).toList(growable: false);

    return List<Item>.unmodifiable(eligibleItems);
  }

  SobreKarUpgradeResolution? resolveSobreKarUpgrade({
    required Battler player,
    required Item selectedItem,
    required RunRandomizer randomizer,
  }) {
    if (!_isSobreKarItemEligible(selectedItem)) return null;

    final upgradedItemResolution = _upgradeOwnedItem(
      player: player,
      selectedItem: selectedItem,
    );
    if (upgradedItemResolution == null) return null;

    final debuffRoll = _rollSobreKarDebuff(randomizer);
    final updatedPlayer = upgradedItemResolution.updatedPlayer.applyStatus(
      debuffRoll.status,
      applyEquipmentModifiers: false,
    );
    final outcomeText =
        '${upgradedItemResolution.upgradedItem.displayName} se mejora a ${_rarityLabel(upgradedItemResolution.upgradedItem.rarity)}. Efecto secundario: ${debuffRoll.label}.';

    return SobreKarUpgradeResolution(
      visitResult: PathEventVisitResult(
        player: updatedPlayer,
        outcomeText: outcomeText,
      ),
      upgradedItem: upgradedItemResolution.upgradedItem,
      appliedDebuff: debuffRoll.status,
      appliedDebuffLabel: debuffRoll.label,
    );
  }

  PathEventVisitResult resolveTechnosurgeonMutation({
    required EventPathNode node,
    required Battler player,
    required Augment selectedAugment,
    required RunRandomizer randomizer,
  }) {
    final replacementAugment = _rollTechnosurgeonReplacement(
      node: node,
      selectedAugment: selectedAugment,
      player: player,
      randomizer: randomizer,
    );
    final updatedPlayer = player.replaceAugment(
      currentAugment: selectedAugment,
      replacementAugment: replacementAugment,
    );

    return PathEventVisitResult(
      player: updatedPlayer,
      outcomeText:
          '${selectedAugment.displayName} ha sido reemplazado por ${replacementAugment.displayName}.',
      gainedAugment: replacementAugment,
    );
  }
}
