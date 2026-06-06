import '../_imports.dart';

class WeaponShopStockService {
  static const defaultStockSize = 3;

  final CatalogRuntimeService _runtimeService;

  const WeaponShopStockService({
    CatalogRuntimeService runtimeService = const CatalogRuntimeService(),
  }) : _runtimeService = runtimeService;

  bool hasAvailableStock({
    required ShopInventoryCriterion criterion,
    required RunHourPhase phase,
    Battler? player,
    int dayNumber = 1,
    List<Item> pool = itemPresets,
  }) {
    return availableStockCount(
          criterion: criterion,
          phase: phase,
          player: player,
          dayNumber: dayNumber,
          pool: pool,
        ) >
        0;
  }

  int availableStockCount({
    required ShopInventoryCriterion criterion,
    required RunHourPhase phase,
    Battler? player,
    int dayNumber = 1,
    List<Item> pool = itemPresets,
    Set<ItemId> excludedItemIds = const <ItemId>{},
  }) {
    final itemPool = _deduplicateByItemType(pool);
    final maximumRarity = _maximumItemRarityFor(
      phase: phase,
      dayNumber: dayNumber,
    );
    final availableItemIds = <ItemId>{};

    for (final rarity in RarityTier.values) {
      if (rarity.index > maximumRarity.index) continue;

      final candidates = _stockCandidatesForExactRarity(
        items: itemPool,
        criterion: criterion,
        player: player,
        targetRarity: rarity,
        excludedItemIds: excludedItemIds,
      );
      availableItemIds.addAll(candidates.map((item) => item.id));
    }

    return availableItemIds.length;
  }

  List<Item> buildInitialStock({
    required ShopInventoryCriterion criterion,
    required RunHourPhase phase,
    required RunRandomizer randomizer,
    Battler? player,
    int dayNumber = 1,
    List<Item> pool = itemPresets,
    Set<ItemId> excludedItemIds = const <ItemId>{},
    int stockSize = defaultStockSize,
  }) {
    if (stockSize <= 0) return const <Item>[];

    final itemPool = _deduplicateByItemType(pool);
    final maximumRarity = _maximumItemRarityFor(
      phase: phase,
      dayNumber: dayNumber,
    );
    final pickedItems = <Item>[];
    final pickedItemIds = <ItemId>{...excludedItemIds};

    while (pickedItems.length < stockSize) {
      final availableRarities = _availableStockRarities(
        items: itemPool,
        criterion: criterion,
        player: player,
        maximumRarity: maximumRarity,
        excludedItemIds: pickedItemIds,
      );
      if (availableRarities.isEmpty) break;

      final targetRarity = _pickWeightedRarity(
        rarities: availableRarities,
        randomizer: randomizer,
        dayNumber: dayNumber,
      );
      final candidates = _stockCandidatesForExactRarity(
        items: itemPool,
        criterion: criterion,
        player: player,
        targetRarity: targetRarity,
        excludedItemIds: pickedItemIds,
      );
      if (candidates.isEmpty) break;

      final pickedItem = candidates[randomizer.nextInt(candidates.length)];
      pickedItems.add(pickedItem);
      pickedItemIds.add(pickedItem.id);
    }

    return List<Item>.unmodifiable(pickedItems);
  }

  RarityTier _maximumItemRarityFor({
    required RunHourPhase phase,
    required int dayNumber,
  }) {
    final dayCap = switch (dayNumber) {
      1 => RarityTier.green,
      2 => RarityTier.blue,
      3 || 4 => RarityTier.purple,
      _ => RarityTier.yellow,
    };

    if (phase == RunHourPhase.day) return dayCap;
    if (dayNumber <= 1) return RarityTier.blue;

    return dayCap.advanceBy(1);
  }

  List<Item> _deduplicateByItemType(Iterable<Item> items) {
    final seenItemIds = <ItemId>{};
    final uniqueItems = <Item>[];

    for (final item in items) {
      if (!seenItemIds.add(item.id)) continue;
      uniqueItems.add(item);
    }

    return List<Item>.unmodifiable(uniqueItems);
  }

  List<RarityTier> _availableStockRarities({
    required List<Item> items,
    required ShopInventoryCriterion criterion,
    required Battler? player,
    required RarityTier maximumRarity,
    required Set<ItemId> excludedItemIds,
  }) {
    final availableRarities = <RarityTier>[];

    for (final rarity in RarityTier.values) {
      if (rarity.index > maximumRarity.index) continue;

      final candidates = _stockCandidatesForExactRarity(
        items: items,
        criterion: criterion,
        player: player,
        targetRarity: rarity,
        excludedItemIds: excludedItemIds,
      );
      if (candidates.isNotEmpty) {
        availableRarities.add(rarity);
      }
    }

    return List<RarityTier>.unmodifiable(availableRarities);
  }

  List<Item> _stockCandidatesForExactRarity({
    required List<Item> items,
    required ShopInventoryCriterion criterion,
    required Battler? player,
    required RarityTier targetRarity,
    required Set<ItemId> excludedItemIds,
  }) {
    final candidatesById = <ItemId, Item>{};

    for (final item in items) {
      if (excludedItemIds.contains(item.id)) continue;

      final promotedItem =
          _runtimeService.promoteItemToExactRarity(item, targetRarity);
      if (promotedItem == null) continue;
      if (!criterion.matches(promotedItem)) continue;
      if (!_canOfferItemForPlayer(player: player, item: promotedItem)) {
        continue;
      }

      candidatesById.putIfAbsent(promotedItem.id, () => promotedItem);
    }

    return List<Item>.unmodifiable(candidatesById.values);
  }

  bool _canOfferItemForPlayer({
    required Battler? player,
    required Item item,
  }) {
    if (player == null) return true;

    final ownedItems = [
      ...player.equippedItems,
      ...player.inventoryItems,
    ].where((ownedItem) => ownedItem.id == item.id);
    if (ownedItems.isEmpty) return true;

    return ownedItems.any(
      (ownedItem) => ownedItem.rarity == item.rarity && ownedItem.canUpgrade,
    );
  }

  RarityTier _pickWeightedRarity({
    required List<RarityTier> rarities,
    required RunRandomizer randomizer,
    required int dayNumber,
  }) {
    final totalWeight = rarities.fold<double>(
      0,
      (sum, rarity) => sum + _rarityWeight(rarity, dayNumber),
    );

    if (totalWeight <= 0) {
      return rarities[randomizer.nextInt(rarities.length)];
    }

    var roll = randomizer.nextDouble() * totalWeight;
    for (final rarity in rarities) {
      roll -= _rarityWeight(rarity, dayNumber);
      if (roll <= 0) return rarity;
    }

    return rarities.last;
  }

  double _rarityWeight(RarityTier rarity, int dayNumber) {
    final progressionWeight = switch (dayNumber) {
      1 => const {
          RarityTier.gray: 1.3,
          RarityTier.green: 0.55,
          RarityTier.blue: 0.16,
          RarityTier.purple: 0.04,
          RarityTier.yellow: 0.01,
        },
      2 => const {
          RarityTier.gray: 0.8,
          RarityTier.green: 1.05,
          RarityTier.blue: 0.38,
          RarityTier.purple: 0.08,
          RarityTier.yellow: 0.02,
        },
      3 => const {
          RarityTier.gray: 0.24,
          RarityTier.green: 0.92,
          RarityTier.blue: 0.78,
          RarityTier.purple: 0.28,
          RarityTier.yellow: 0.05,
        },
      4 => const {
          RarityTier.gray: 0.08,
          RarityTier.green: 0.4,
          RarityTier.blue: 1.02,
          RarityTier.purple: 0.65,
          RarityTier.yellow: 0.12,
        },
      _ => const {
          RarityTier.gray: 0.02,
          RarityTier.green: 0.12,
          RarityTier.blue: 0.72,
          RarityTier.purple: 1.08,
          RarityTier.yellow: 0.3,
        },
    };

    return rarity.rollWeight * (progressionWeight[rarity] ?? 0.01);
  }
}
