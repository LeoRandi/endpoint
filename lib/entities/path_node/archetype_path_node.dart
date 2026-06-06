import '../_imports.dart';
import '../../services/run/run_randomizer.dart';

/// Describe un arquetipo inicial que altera stats, economia, items y AUMENTOS del jugador.
class ArchetypePathNode extends PathNode {
  final ArchetypeId archetypeId;
  final String playerIconEmoji;
  final List<Item> startingItems;
  final List<Item> Function(RunRandomizer randomizer)? startingItemsBuilder;
  final List<BattlerAbility> startingAbilities;
  final Map<BattlerStat, int> baseStatModifiers;
  final int moneyModifier;
  final int incomeModifier;

  /// Crea un arquetipo inicial con sus bonus base y el loadout que entrega.
  ArchetypePathNode({
    required this.archetypeId,
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

  /// Clona el arquetipo con un loadout inicial ya materializado.
  ///
  /// Se usa cuando un builder aleatorio ya eligio items para esta run y la ruta
  /// necesita conservar exactamente esa seleccion en snapshots.
  ArchetypePathNode withStartingItems(List<Item> items) {
    return ArchetypePathNode(
      archetypeId: archetypeId,
      nodeId: nodeId,
      label: label,
      tooltip: tooltip,
      iconEmoji: iconEmoji,
      accent: accent,
      rarity: rarity,
      playerIconEmoji: playerIconEmoji,
      startingItems: List<Item>.unmodifiable(items),
      startingItemsBuilder: startingItemsBuilder,
      startingAbilities: startingAbilities,
      baseStatModifiers: baseStatModifiers,
      moneyModifier: moneyModifier,
      incomeModifier: incomeModifier,
    );
  }

  /// Genera el item verde propio y el item gris general para arquetipos sin builder propio.
  ///
  /// El metodo devuelve `this` si el arquetipo ya trae items fijos o un builder
  /// propio, evitando que la ruta vuelva a tirar loot cuando no corresponde.
  ArchetypePathNode materializeRunStartingItems(RunRandomizer randomizer) {
    if (startingItemsBuilder != null || startingItems.isNotEmpty) return this;

    final archetypeItem = _pickRandomStartingItem(
      _startingItemCandidatesForAffinity(
        archetypeId.itemAffinity,
        exactRarity: RarityTier.green,
      ),
      randomizer,
    );
    final generalItem = _pickRandomStartingItem(
      _startingItemCandidatesForAffinity(
        ItemArchetypeAffinity.general,
        exactRarity: RarityTier.gray,
        excludedItemIds: {
          if (archetypeItem != null) archetypeItem.id,
        },
      ),
      randomizer,
    );

    return withStartingItems([
      if (archetypeItem != null) archetypeItem.toRuntimeInstance(),
      if (generalItem != null) generalItem.toRuntimeInstance(),
    ]);
  }

  /// Aplica el arquetipo al jugador manteniendo su estado previo y sumando el loadout inicial.
  ///
  /// La vista de confirmacion puede desactivar [resolveDynamicStartingItems]
  /// para previsualizar stats sin consumir la tirada real de items aleatorios.
  Battler applyTo(
    Battler player, {
    RunRandomizer? randomizer,
    bool resolveDynamicStartingItems = true,
    bool suppressCodexDiscovery = false,
  }) {
    final updatedBaseStats = Map<BattlerStat, int>.from(player.baseStats);
    final resolvedStartingItems =
        startingItemsBuilder == null || !resolveDynamicStartingItems
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
      archetypeId: archetypeId,
      iconEmoji: playerIconEmoji,
      money: player.money + moneyModifier,
      income: player.baseIncome + incomeModifier,
      baseStats: Map<BattlerStat, int>.unmodifiable(updatedBaseStats),
    );

    final previousSuppression = CodexDiscoveryHook.isSuppressed;
    CodexDiscoveryHook.isSuppressed =
        previousSuppression || suppressCodexDiscovery;
    try {
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
    } finally {
      CodexDiscoveryHook.isSuppressed = previousSuppression;
    }

    return updatedPlayer.copyWith(health: updatedPlayer.maxHealth);
  }

  /// Devuelve candidatos iniciales por afinidad, rareza exacta y exclusiones.
  ///
  /// Esta busqueda mantiene las reglas de arquetipo cerca del nodo y deja los
  /// pools globales de items como fuente canonica de contenido.
  static List<Item> _startingItemCandidatesForAffinity(
    ItemArchetypeAffinity affinity, {
    required RarityTier exactRarity,
    Set<ItemId> excludedItemIds = const {},
  }) {
    return itemPresets
        .where(
          (item) =>
              item.hasArchetypeAffinity(affinity) &&
              item.rarity == exactRarity &&
              !excludedItemIds.contains(item.id),
        )
        .toList(growable: false);
  }

  /// Escoge un item inicial de [candidates] usando el randomizer de la run.
  ///
  /// Devuelve `null` si no hay candidatos para que los arquetipos degradados no
  /// rompan la construccion de la ruta.
  static Item? _pickRandomStartingItem(
    List<Item> candidates,
    RunRandomizer randomizer,
  ) {
    if (candidates.isEmpty) return null;

    return candidates[randomizer.nextInt(candidates.length)];
  }
}
