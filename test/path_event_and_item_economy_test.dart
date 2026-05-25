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
        shopRarity: RarityTier.purple,
        priceMultiplier: 1.5,
      );

      expect(
        controller.sellPriceFor(item),
        (controller.purchasePriceFor(item) / 2).ceil(),
      );
    });

    test('shop reroll replaces stock once with different items for rarity cost',
        () {
      final controller = WeaponShopController(
        player: defaultPlayerBattler.copyWith(money: 20),
        stockCriterion: grayShopCriterion,
        phase: RunHourPhase.day,
        randomizer: RunRandomizer(seed: 4),
        shopRarity: RarityTier.gray,
      );
      final initialStock = controller.stock;

      expect(initialStock, hasLength(WeaponShopStockService.defaultStockSize));
      expect(controller.rerollCost, 2);
      expect(controller.rerollsRemaining, 1);
      expect(controller.canRerollStock, isTrue);
      expect(controller.rerollStock(), isTrue);

      final rerolledStock = controller.stock;
      expect(rerolledStock, hasLength(WeaponShopStockService.defaultStockSize));
      expect(
        rerolledStock.map((item) => item.id).toSet().intersection(
              initialStock.map((item) => item.id).toSet(),
            ),
        isEmpty,
      );
      expect(controller.player.money, 18);
      expect(controller.rerollsRemaining, 0);
      expect(controller.canRerollStock, isFalse);
      expect(controller.rerollStock(), isFalse);
    });

    test('shop reroll is unavailable when replacement stock is incomplete', () {
      final stockPool = itemPresets
          .where(grayShopCriterion.matches)
          .take(WeaponShopStockService.defaultStockSize)
          .toList(growable: false);
      final controller = WeaponShopController(
        player: defaultPlayerBattler.copyWith(money: 20),
        stockCriterion: grayShopCriterion,
        phase: RunHourPhase.day,
        randomizer: RunRandomizer(seed: 9),
        shopRarity: RarityTier.yellow,
        stockPool: stockPool,
      );

      expect(
          controller.stock, hasLength(WeaponShopStockService.defaultStockSize));
      expect(controller.rerollCost, 6);
      expect(controller.canRerollStock, isFalse);
      expect(controller.rerollStock(), isFalse);
      expect(controller.player.money, 20);
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

    test('virtual mailbox adds sourced item rewards after victory', () {
      final rewards = const BattleRewardService().buildVictoryRewards(
        enemy: defaultEnemyBattler.copyWith(equippedItems: const []),
        player: defaultPlayerBattler.copyWith(
          equippedItems: const [buzonVirtualRojoItem],
        ),
        victoryMoneyFactor: 0,
        randomizer: RunRandomizer(seed: 19),
      );

      expect(rewards.lootItem, isNull);
      expect(rewards.itemRewards, hasLength(1));
      expect(
          rewards.itemRewards.single.sourceItem?.id, ItemId.buzonVirtualRojo);
      expect(rewards.itemRewards.single.item.rarity, RarityTier.gray);
      expect(rewards.itemRewards.single.item.hasTag(EntityTag.ataque), isTrue);
    });

    test('mailbox rewards can use free equipment capacity if inventory is full',
        () {
      final fullInventory = List<Item>.generate(
        Battler.maxInventoryItems,
        (_) => woodenStickItem.toOwnedInstance(),
      );
      final player = defaultPlayerBattler.copyWith(
        equipmentCapacity: 2,
        equippedItems: const [buzonVirtualRojoItem],
        inventoryItems: fullInventory,
      );

      final updatedPlayer = player.addItemToInventoryOrEquipment(ironSwordItem);

      expect(
          updatedPlayer.inventoryItems, hasLength(Battler.maxInventoryItems));
      expect(updatedPlayer.equippedItems.map((item) => item.id),
          contains(ItemId.ironSword));
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
