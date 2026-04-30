import '_imports.dart';

class WeaponShopStockService {
  static const defaultStockSize = 3;

  const WeaponShopStockService();

  List<Item> buildInitialStock({
    required ShopInventoryCriterion criterion,
    required RunHourPhase phase,
    required RunRandomizer randomizer,
    int dayNumber = 1,
    List<Item> pool = itemPresets,
    int stockSize = defaultStockSize,
  }) {
    final allMatchingItems = _deduplicateByItemType(
      pool.where(
        criterion.matches,
      ),
    );
    final matchingItems = _filteredByDayRarity(
      items: allMatchingItems,
      phase: phase,
      dayNumber: dayNumber,
    );
    final stockCandidates =
        matchingItems.isEmpty ? allMatchingItems : matchingItems;

    if (stockCandidates.length <= stockSize) {
      return List<Item>.unmodifiable(stockCandidates);
    }

    return _pickDistinctWeightedByRarity(
      items: stockCandidates,
      randomizer: randomizer,
      count: stockSize,
      dayNumber: dayNumber,
    );
  }

  List<Item> _filteredByDayRarity({
    required List<Item> items,
    required RunHourPhase phase,
    required int dayNumber,
  }) {
    final maximumRarity = _maximumItemRarityFor(
      phase: phase,
      dayNumber: dayNumber,
    );

    return items
        .where((item) => item.rarity.index <= maximumRarity.index)
        .toList(growable: false);
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

  List<Item> _pickDistinctWeightedByRarity({
    required List<Item> items,
    required RunRandomizer randomizer,
    required int count,
    required int dayNumber,
  }) {
    final remainingItems = List<Item>.from(items);
    final pickedItems = <Item>[];

    while (pickedItems.length < count && remainingItems.isNotEmpty) {
      final totalWeight = remainingItems.fold<double>(
        0,
        (sum, item) => sum + _rarityWeight(item.rarity, dayNumber),
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
        roll -= _rarityWeight(remainingItems[index].rarity, dayNumber);
        if (roll > 0) continue;

        pickedIndex = index;
        break;
      }

      pickedItems.add(remainingItems.removeAt(pickedIndex));
    }

    return List<Item>.unmodifiable(pickedItems);
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
