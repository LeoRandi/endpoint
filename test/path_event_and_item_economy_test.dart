import 'package:endpoint/controllers/_exports.dart';
import 'package:endpoint/entities/_exports.dart';
import 'package:endpoint/services/_exports.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('item economy', () {
    test('item buy cost doubles by tier while quick sell is tier value', () {
      for (final rarity in RarityTier.values) {
        final item = itemPresets.firstWhere((item) => item.rarity == rarity);

        expect(item.cost, 1 << rarity.factor);
        expect(item.sellValue, rarity.factor);
      }
    });

    test('shop sell value is half of the shop buy price', () {
      final item = itemPresets.firstWhere(
        (item) => item.rarity == RarityTier.purple,
      );
      final controller = WeaponShopController(
        player: defaultPlayerBattler,
        stockCriterion: ShopInventoryCriterion(
          label: 'Test',
          description: 'Test stock',
        ),
        phase: RunHourPhase.day,
        randomizer: RunRandomizer(seed: 7),
        priceMultiplier: 1.5,
      );

      expect(
        controller.sellPriceFor(item),
        (controller.purchasePriceFor(item) / 2).ceil(),
      );
    });

    test('operatives quick sell removes inventory item for tier value', () {
      final item = itemPresets
          .firstWhere((item) => item.rarity == RarityTier.green)
          .toOwnedInstance();
      final controller = OperativesOverlayController(
        player: defaultPlayerBattler.copyWith(
          money: 3,
          inventoryItems: [item],
        ),
      );

      expect(controller.sellActionLabelFor(item), 'Sell (2)');
      expect(controller.sellInventoryItem(item), isTrue);
      expect(controller.player.money, 5);
      expect(controller.player.inventoryItems, isEmpty);
    });
  });

  group('basic item events', () {
    const service = PathEventService();

    test('stranded trash rewards a gray item from the current archetype pool',
        () {
      final player = defaultPlayerBattler.copyWith(
        archetypeId: ArchetypeId.veloz,
      );
      final result = service.visit(
        node: strandedTrashNode,
        player: player,
        randomizer: RunRandomizer(seed: 11),
      );
      final gainedItem = result.gainedItem!;

      expect(gainedItem.rarity, RarityTier.gray);
      expect(result.player.inventoryItems, contains(gainedItem));
      expect(
        itemPoolForArchetype(ArchetypeId.veloz).map((item) => item.id),
        contains(gainedItem.id),
      );
    });

    test('lost cache rewards a green item from the current archetype pool', () {
      final player = defaultPlayerBattler.copyWith(
        archetypeId: ArchetypeId.inamovible,
      );
      final result = service.visit(
        node: lostCacheNode,
        player: player,
        randomizer: RunRandomizer(seed: 13),
      );
      final gainedItem = result.gainedItem!;

      expect(gainedItem.rarity, RarityTier.green);
      expect(result.player.inventoryItems, contains(gainedItem));
      expect(
        itemPoolForArchetype(ArchetypeId.inamovible).map((item) => item.id),
        contains(gainedItem.id),
      );
    });
  });
}
