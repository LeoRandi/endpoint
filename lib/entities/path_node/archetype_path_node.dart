import '../_imports.dart';
import '../../services/run_randomizer.dart';

/// Describe un arquetipo inicial que altera stats, economia, items y habilidades del jugador.
class ArchetypePathNode extends PathNode {
  final String playerIconEmoji;
  final List<Item> startingItems;
  final List<Item> Function(RunRandomizer randomizer)? startingItemsBuilder;
  final List<BattlerAbility> startingAbilities;
  final Map<BattlerStat, int> baseStatModifiers;
  final int moneyModifier;
  final int incomeModifier;

  /// Crea un arquetipo inicial con sus bonus base y el loadout que entrega.
  ArchetypePathNode({
    String? nodeId,
    required String label,
    required String tooltip,
    required String iconEmoji,
    required Color accent,
    required RarityTier rarity,
    this.playerIconEmoji = '\u{1F916}',
    required List<Item> startingItems,
    this.startingItemsBuilder,
    List<BattlerAbility> startingAbilities = const [],
    this.baseStatModifiers = const {},
    this.moneyModifier = 0,
    this.incomeModifier = 0,
  })  : startingItems = List<Item>.unmodifiable(startingItems),
        startingAbilities =
            List<BattlerAbility>.unmodifiable(startingAbilities),
        super.base(
          type: PathNodeType.archetype,
          nodeId: nodeId ?? 'archetype:$label',
          label: label,
          tooltip: tooltip,
          iconEmoji: iconEmoji,
          rarity: rarity,
          accent: accent,
          badgeLabel: 'ARQUETIPO',
          hasSignatureBorder: true,
        );

  /// Aplica el arquetipo al jugador manteniendo su estado previo y sumando el loadout inicial.
  Battler applyTo(
    Battler player, {
    RunRandomizer? randomizer,
  }) {
    final updatedBaseStats = Map<BattlerStat, int>.from(player.baseStats);
    final resolvedStartingItems = startingItemsBuilder == null
        ? startingItems
        : List<Item>.unmodifiable(
            startingItemsBuilder!(
              randomizer ?? RunRandomizer(),
            ),
          );

    for (final entry in baseStatModifiers.entries) {
      updatedBaseStats[entry.key] = max(
        0,
        (updatedBaseStats[entry.key] ?? 0) + entry.value,
      );
    }

    var updatedPlayer = player.copyWith(
      iconEmoji: playerIconEmoji,
      money: player.money + moneyModifier,
      income: player.baseIncome + incomeModifier,
      baseStats: Map<BattlerStat, int>.unmodifiable(updatedBaseStats),
    );

    for (final item in resolvedStartingItems) {
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
