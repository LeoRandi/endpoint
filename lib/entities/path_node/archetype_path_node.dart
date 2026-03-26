import '_imports.dart';

class ArchetypePathNode extends PathNode {
  final String playerIconEmoji;
  final List<Item> startingItems;
  final List<BattlerAbility> startingAbilities;
  final Map<BattlerStat, int> baseStatModifiers;
  final int moneyModifier;
  final int incomeModifier;

  ArchetypePathNode({
    required String label,
    required String tooltip,
    required String iconEmoji,
    required Color accent,
    required RarityTier rarity,
    this.playerIconEmoji = '\u{1F916}',
    required List<Item> startingItems,
    List<BattlerAbility> startingAbilities = const [],
    this.baseStatModifiers = const {},
    this.moneyModifier = 0,
    this.incomeModifier = 0,
  })  : startingItems = List<Item>.unmodifiable(startingItems),
        startingAbilities =
            List<BattlerAbility>.unmodifiable(startingAbilities),
        super.base(
          type: PathNodeType.archetype,
          label: label,
          tooltip: tooltip,
          iconEmoji: iconEmoji,
          rarity: rarity,
          accent: accent,
          badgeLabel: 'ARQUETIPO',
          hasSignatureBorder: true,
        );

  Battler applyTo(Battler player) {
    final updatedBaseStats = Map<BattlerStat, int>.from(player.baseStats);

    for (final entry in baseStatModifiers.entries) {
      updatedBaseStats[entry.key] = max(
        0,
        (updatedBaseStats[entry.key] ?? 0) + entry.value,
      );
    }

    var updatedPlayer = player.copyWith(
      iconEmoji: playerIconEmoji,
      money: player.money + moneyModifier,
      income: player.income + incomeModifier,
      baseStats: Map<BattlerStat, int>.unmodifiable(updatedBaseStats),
      inventoryItems: const [],
      equippedItems: const [],
    );

    for (final item in startingItems) {
      updatedPlayer = updatedPlayer.addItem(item);
      final inventoryItem = updatedPlayer.inventoryItemOfType(item.id);
      if (item.isEquippable && inventoryItem != null) {
        updatedPlayer = updatedPlayer.equipItem(inventoryItem);
      }
    }

    for (final ability in startingAbilities) {
      updatedPlayer = updatedPlayer.addAbility(ability);
    }

    return updatedPlayer.copyWith(health: updatedPlayer.maxHealth);
  }
}
