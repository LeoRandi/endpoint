import '_imports.dart';

List<Item> itemPresets = <Item>[
  /// Wooden Stick
  Item(
    affinity: ItemArchetypeAffinity.general,
    name: 'Wooden Stick',
    description:
        'A simple wooden stick. Not very effective, but better than nothing.',
    tier: RarityTier.gray,
    baseCost: 2,
    sellValue: 1,
    tags: <EntityTag>[EntityTag.arma],
    asset: 'assets/sprites/items/WoodenStick.png',
    effects: <Effect, int>{
      ActionEffect.attack(value: 5): 5,
    },
  ),

  /// Sunglasses
  Item(
    affinity: ItemArchetypeAffinity.general,
    name: 'Sunglasses',
    description:
        'A pair of stylish sunglasses. The cooler you look, the more stuff you do, its simple math.',
    tier: RarityTier.yellow,
    baseCost: 10,
    sellValue: 5,
    tags: <EntityTag>[EntityTag.accesorio],
    asset: 'assets/sprites/items/wooden_stick.png',
    effects: <Effect, int>{
      const ActionEffect(
          actionType: ItemActionType.none,
          description:
              'Take every action before this item is used an additional time.',
          customEffectKey: ItemEffectKeys.sunglasses,
          value: 0): 0
    },
  ),

  /// Nano-bandage
  Item(
    affinity: ItemArchetypeAffinity.general,
    name: 'Nano-bandage',
    description: 'A small medical device that can quickly heal wounds.',
    tier: RarityTier.green,
    baseCost: 4,
    sellValue: 2,
    tags: <EntityTag>[EntityTag.cura, EntityTag.accesorio],
    asset: 'assets/sprites/items/wooden_stick.png',
    effects: <Effect, int>{
      ActionEffect.heal(value: 5): 5,
      const PassiveEffect(
        effectKey: ItemEffectKeys.nanoBandageTurnStartHeal,
        description: 'Heal for --value-- at the start of your turn.',
        value: 2,
        hook: ItemEffectHook.turnStart,
      ): 2
    },
  ),

  /// Shield Lance
  Item(
    affinity: ItemArchetypeAffinity.general,
    name: 'Shield Lance',
    description:
        'A compact spear built through the guard of a small shield, made to catch a blow before driving forward.',
    tier: RarityTier.green,
    baseCost: 4,
    sellValue: 2,
    tags: <EntityTag>[
      EntityTag.arma,
      EntityTag.barrera,
      EntityTag.ataque,
    ],
    asset: 'assets/sprites/items/WoodenStick.png',
    effects: <Effect, int>{
      ActionEffect.block(value: 5): 5,
      PatternEffect(
        patternType: const OperativePatternRequirement.rightAngle(),
        actionEffect: ActionEffect.attack(value: 8),
      ): 4,
    },
  ),
];

/// Stable catalog lookup populated alongside [itemPresets].
final Map<String, Item> itemPresetRegistry = Map<String, Item>.unmodifiable({
  for (final item in itemPresets) item.catalogKey: item,
});
