import '_imports.dart';

class WeaponShopStockService {
  static const defaultStockSize = 3;

  const WeaponShopStockService();

  List<Item> buildInitialStock({
    required ShopInventoryCriterion criterion,
    required RunRandomizer randomizer,
    List<Item> pool = itemPresets,
    int stockSize = defaultStockSize,
  }) {
    final matchingItems = _deduplicateByItemType(
      pool.where(criterion.matches),
    );

    if (matchingItems.length <= stockSize) {
      return List<Item>.unmodifiable(matchingItems);
    }

    return randomizer.pickDistinct(matchingItems, stockSize);
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
}
