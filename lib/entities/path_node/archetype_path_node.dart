import '_imports.dart';

class ArchetypePathNode extends PathNode {
  final String playerIconEmoji;
  final List<Item> startingItems;
  final Map<BattlerStat, int> baseStatModifiers;

  ArchetypePathNode({
    required String label,
    required String tooltip,
    required String iconEmoji,
    required Color accent,
    required RarityTier rarity,
    this.playerIconEmoji = '\u{1F916}',
    required List<Item> startingItems,
    this.baseStatModifiers = const {},
  })  : startingItems = List<Item>.unmodifiable(startingItems),
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

    return updatedPlayer.copyWith(health: updatedPlayer.maxHealth);
  }
}
