part of '../path_event_service.dart';

/// Reward-table use cases for Hackathon and Tintoreria Fantasma.
extension RewardPathEventHandler on PathEventService {
  PathEventVisitResult resolveHackathonReward({
    required Battler player,
    required int score,
    required RunRandomizer randomizer,
  }) {
    final cappedScore = score.clamp(0, 6).toInt();
    if (cappedScore <= 1) {
      return PathEventVisitResult(
        player: player,
        outcomeText: 'Los cyber-nerds aplauden con educacion. No hay premio.',
      );
    }

    if (cappedScore <= 3) {
      final augment = _rollRewardAugment(
        player: player,
        rarity: RarityTier.green,
        randomizer: randomizer,
      );
      if (augment == null) {
        return PathEventVisitResult(
          player: player,
          outcomeText: 'El puesto no encuentra un aumento verde compatible.',
        );
      }
      final updatedPlayer =
          player.addAugment(_runtimeService.runtimeAugment(augment));
      return PathEventVisitResult(
        player: updatedPlayer,
        outcomeText: 'Recibes un aumento verde: ${augment.displayName}.',
        gainedAugment: updatedPlayer.augmentById(augment.id) ?? augment,
      );
    }

    if (cappedScore <= 5) {
      final augment = _rollRewardAugment(
        player: player,
        rarity: RarityTier.blue,
        randomizer: randomizer,
      );
      final item = _rollRewardItem(
        rarity: RarityTier.green,
        randomizer: randomizer,
      );
      var updatedPlayer = player;
      if (augment != null) {
        updatedPlayer =
            updatedPlayer.addAugment(_runtimeService.runtimeAugment(augment));
      }
      if (item != null) updatedPlayer = updatedPlayer.addItem(item);
      return PathEventVisitResult(
        player: updatedPlayer,
        outcomeText:
            'Recibes ${augment?.displayName ?? 'sin aumento'} y ${item?.displayName ?? 'sin objeto'}.',
        gainedAugment:
            augment == null ? null : updatedPlayer.augmentById(augment.id),
        gainedItem: item == null
            ? null
            : updatedPlayer.inventoryItemOfType(item.catalogKey) ??
                updatedPlayer.equippedItemOfType(item.catalogKey) ??
                item,
      );
    }

    final augment = _rollRewardAugment(
      player: player,
      rarity: RarityTier.yellow,
      randomizer: randomizer,
    );
    final item = _rollRewardItem(
      rarity: RarityTier.blue,
      randomizer: randomizer,
    );
    var updatedPlayer = player;
    if (augment != null) {
      updatedPlayer =
          updatedPlayer.addAugment(_runtimeService.runtimeAugment(augment));
    }
    if (item != null) updatedPlayer = updatedPlayer.addItem(item);
    return PathEventVisitResult(
      player: updatedPlayer,
      outcomeText:
          'Reclamas el premio completo: ${augment?.displayName ?? 'sin aumento'} y ${item?.displayName ?? 'sin objeto'}.',
      gainedAugment:
          augment == null ? null : updatedPlayer.augmentById(augment.id),
      gainedItem: item == null
          ? null
          : updatedPlayer.inventoryItemOfType(item.catalogKey) ??
              updatedPlayer.equippedItemOfType(item.catalogKey) ??
              item,
    );
  }

  List<Item> buildTintoreriaFantasmaOffers({
    required Battler player,
    required RunRandomizer randomizer,
    required int dayNumber,
    int count = 3,
  }) {
    if (count <= 0) return const <Item>[];

    final pool = itemPoolForArchetype(player.archetypeId);
    if (pool.isEmpty) return const <Item>[];

    final targetRarity = _rollEventItemRarityForDay(
      randomizer: randomizer,
      dayNumber: dayNumber + 1,
    );
    final selectedItems = <Item>[];
    final selectedItemIds = <String>{};
    for (final rarity in RarityProgressionService.fallbackTiersFrom(
      targetRarity,
    )) {
      final candidates = pool
          .where(
            (item) =>
                item.rarity == rarity &&
                !selectedItemIds.contains(item.catalogKey),
          )
          .toList(growable: false);
      if (candidates.isEmpty) continue;

      final pickedItems = randomizer.pickDistinct(
        candidates,
        min(count - selectedItems.length, candidates.length),
      );
      selectedItems.addAll(pickedItems);
      selectedItemIds.addAll(pickedItems.map((item) => item.catalogKey));
      if (selectedItems.length >= count) {
        return List<Item>.unmodifiable(selectedItems.take(count));
      }
    }

    return List<Item>.unmodifiable(selectedItems);
  }

  int tintoreriaFantasmaPriceFor(Item item) {
    return max(item.baseCost, item.tier.factor * 5);
  }

  PathEventVisitResult resolveTintoreriaFantasmaBorrow({
    required Battler player,
    required Item selectedItem,
  }) {
    if (!player.hasInventorySpace) {
      return PathEventVisitResult(
        player: player,
        outcomeText: 'No tienes espacio para llevarte una prenda prestada.',
      );
    }

    final ghostItem = _runtimeService.runtimeItem(
      selectedItem.copyWith(isGhostly: true),
      forceNewInstance: true,
    );
    final updatedPlayer = player.addItemAsNewInstance(ghostItem);
    final resolvedItem = updatedPlayer.inventoryItems.lastWhere(
      (item) => item.instanceId == ghostItem.instanceId,
      orElse: () => ghostItem,
    );

    return PathEventVisitResult(
      player: updatedPlayer,
      outcomeText:
          'Te llevas ${resolvedItem.displayName}. La bruma promete volver a reclamarlo tras dos combates.',
      gainedItem: resolvedItem,
      ghostItemLease: GhostItemLease(
        itemInstanceId: resolvedItem.instanceId ?? ghostItem.instanceId!,
        combatsRemaining: 2,
      ),
    );
  }
}
