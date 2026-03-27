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
    final matchingItems = pool.where(criterion.matches).toList(growable: false);

    if (matchingItems.length <= stockSize) {
      return List<Item>.unmodifiable(matchingItems);
    }

    return randomizer.pickDistinct(matchingItems, stockSize);
  }
}
