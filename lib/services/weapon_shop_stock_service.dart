import '_imports.dart';

class WeaponShopStockService {
  static const defaultStockSize = 3;
  static const _dayMaximumItemRarity = RarityTier.blue;

  const WeaponShopStockService();

  List<Item> buildInitialStock({
    required ShopInventoryCriterion criterion,
    required RunHourPhase phase,
    required RunRandomizer randomizer,
    List<Item> pool = itemPresets,
    int stockSize = defaultStockSize,
  }) {
    final matchingItems = _deduplicateByItemType(
      pool.where(
        (item) => criterion.matches(item) && _canAppearInPhase(item, phase),
      ),
    );

    if (matchingItems.length <= stockSize) {
      return List<Item>.unmodifiable(matchingItems);
    }

    if (phase == RunHourPhase.day) {
      return _pickDistinctWeightedByRarity(
        items: matchingItems,
        randomizer: randomizer,
        count: stockSize,
      );
    }

    return randomizer.pickDistinct(matchingItems, stockSize);
  }

  bool _canAppearInPhase(Item item, RunHourPhase phase) {
    if (phase != RunHourPhase.day) return true;

    return item.rarity.index <= _dayMaximumItemRarity.index;
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

  List<Item> _pickDistinctWeightedByRarity({
    required List<Item> items,
    required RunRandomizer randomizer,
    required int count,
  }) {
    final remainingItems = List<Item>.from(items);
    final pickedItems = <Item>[];

    while (pickedItems.length < count && remainingItems.isNotEmpty) {
      final totalWeight = remainingItems.fold<double>(
        0,
        (sum, item) => sum + item.rarity.rollWeight,
      );

      if (totalWeight <= 0) {
        pickedItems.add(
          remainingItems.removeAt(randomizer.nextInt(remainingItems.length)),
        );
        continue;
      }

      var roll = randomizer.nextDouble() * totalWeight;
      var pickedIndex = remainingItems.length - 1;

      for (var index = 0; index < remainingItems.length; index++) {
        roll -= remainingItems[index].rarity.rollWeight;
        if (roll > 0) continue;

        pickedIndex = index;
        break;
      }

      pickedItems.add(remainingItems.removeAt(pickedIndex));
    }

    return List<Item>.unmodifiable(pickedItems);
  }
}
