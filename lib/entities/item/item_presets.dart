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

  /// S-Harp-Ener
  Item(
    affinity: ItemArchetypeAffinity.general,
    name: 'S-Harp-Ener',
    description:
        'An ancient harp relic, said to amplify nearby blades and blasts, now a household commodity to sharpen your kitchen knives!',
    tier: RarityTier.green,
    baseCost: 6,
    sellValue: 3,
    tags: <EntityTag>[EntityTag.accesorio],
    asset: 'assets/sprites/items/WoodenStick.png',
    effects: <Effect, int>{
      const ActionEffect(
        actionType: ItemActionType.none,
        description: 'Give +--value-- permanent attack to adjacent weapons.',
        customEffectKey: ItemEffectKeys.sHarpEner,
        value: 1,
      ): 1,
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

  /////////////////////////////---IMPARABLE---///////////////////////////////////////

  /// Rusted Cleaver
  Item(
    affinity: ItemArchetypeAffinity.imparable,
    name: 'Rusted Cleaver',
    description: 'A crude, heavy cleaver. It just cuts.',
    tier: RarityTier.gray,
    baseCost: 2,
    sellValue: 1,
    tags: <EntityTag>[
      EntityTag.arma,
      EntityTag.ataque,
    ],
    asset: 'assets/sprites/items/RustedCleaver.png',
    effects: <Effect, int>{
      ActionEffect.attack(value: 6): 6,
    },
  ),

  /// Kindling Axe
  Item(
    affinity: ItemArchetypeAffinity.imparable,
    name: 'Kindling Axe',
    description:
        'A brutal axe with a smoldering edge. It burns the enemy, burns the wielder, and solves most problems by making them worse first.',
    tier: RarityTier.green,
    baseCost: 4,
    sellValue: 2,
    tags: <EntityTag>[
      EntityTag.arma,
      EntityTag.ataque,
      EntityTag.quemadura,
      EntityTag.debuff
    ],
    asset: 'assets/sprites/items/KindlingAxe.png',
    effects: <Effect, int>{
      ActionEffect.attack(value: 10): 10,
      ActionEffect(
        actionType: ItemActionType.none,
        description:
            'Apply --value-- Burn to the enemy and 2 Burn to yourself.',
        customEffectKey: ItemEffectKeys.kindlingAxeBurnBoth,
        value: 2,
      ): 2,
    },
  ),

  /// Furnace Heart
  Item(
    affinity: ItemArchetypeAffinity.imparable,
    name: 'Furnace Heart',
    description:
        'A pulsing metal core that feeds every nearby weapon with heat. The longer you burn, the louder it beats.',
    tier: RarityTier.blue,
    baseCost: 6,
    sellValue: 3,
    tags: <EntityTag>[
      EntityTag.accesorio,
      EntityTag.quemadura,
      EntityTag.debuff,
      EntityTag.ataque,
    ],
    asset: 'assets/sprites/items/FurnaceHeart.png',
    effects: <Effect, int>{
      const PassiveEffect(
        effectKey: ItemEffectKeys.furnaceHeartAdjacentWeapons,
        description:
            'Adjacent weapons gain +--value-- attack. If you have Burn, they also apply 1 Burn to the enemy when used.',
        value: 2,
        hook: ItemEffectHook.combatStart,
      ): 1,
      PatternEffect(
        patternType: const OperativePatternRequirement.rightAngle(),
        actionEffect: const ActionEffect(
          actionType: ItemActionType.none,
          description:
              'Apply --value-- Burn to yourself, then use adjacent weapons on the pattern an additional time.',
          customEffectKey: ItemEffectKeys.furnaceHeartRightAngleTrigger,
          value: 1,
        ),
      ): 1,
    },
  ),

  /// Bloodflame Gauntlet
  Item(
    affinity: ItemArchetypeAffinity.imparable,
    name: 'Bloodflame Gauntlet',
    description:
        'A cursed gauntlet that absorbs pain and spits it back as fire. It is safe as long as it is killing something.',
    tier: RarityTier.purple,
    baseCost: 8,
    sellValue: 4,
    tags: <EntityTag>[
      EntityTag.arma,
      EntityTag.ataque,
      EntityTag.quemadura,
      EntityTag.debuff,
      EntityTag.vida,
    ],
    asset: 'assets/sprites/items/BloodflameGauntlet.png',
    effects: <Effect, int>{
      ActionEffect.attack(value: 12): 12,
      const PassiveEffect(
        effectKey: ItemEffectKeys.bloodflameGauntletLowHpDamage,
        description:
            'Your attacks deal +--value-- damage while you are below half HP. Double this bonus if you have Burn.',
        value: 3,
        hook: ItemEffectHook.outgoingDamageModifier,
      ): 3,
      const PassiveEffect(
        effectKey: ItemEffectKeys.bloodflameGauntletBurnRevenge,
        description:
            'Whenever you receive damage from Burn, your next attack applies --value-- Burn to the enemy.',
        value: 2,
        hook: ItemEffectHook.receiveDamageResolved,
      ): 2,
    },
  ),

  /// Crown of the Last Ember
  Item(
    affinity: ItemArchetypeAffinity.imparable,
    name: 'Crown of the Black Sun',
    description:
        'A cracked crown burning with the final flame of a dead king. It does not ask you to survive. It asks you to end the fight first.',
    tier: RarityTier.yellow,
    baseCost: 40,
    sellValue: 20,
    tags: <EntityTag>[
      EntityTag.accesorio,
      EntityTag.quemadura,
      EntityTag.buff,
      EntityTag.ataque,
      EntityTag.desafio,
    ],
    asset: 'assets/sprites/items/CrownOfTheBlackSun.png',
    effects: <Effect, int>{
      const PassiveEffect(
        effectKey: ItemEffectKeys.crownOfTheBlackSunBurnScaling,
        description:
            'Your attacks deal +--value-- damage for each Burn on you and on the enemy.',
        value: 1,
        hook: ItemEffectHook.outgoingDamageModifier,
      ): 1,
      const PassiveEffect(
        effectKey: ItemEffectKeys.crownOfTheBlackSunNoDeathOnce,
        description:
            'The first time you hurt an enemy each fight, apply --value-- Burn to both you and the enemy, then use all adjacent weapons once.',
        value: 2,
        hook: ItemEffectHook.attackResolved,
      ): 2,
      PatternEffect(
        patternType: const OperativePatternRequirement.last(),
        actionEffect: const ActionEffect(
          actionType: ItemActionType.none,
          description:
              'If this ends the pattern, consume half of your Burn to deal --value-- true damage per Burn consumed.',
          customEffectKey: ItemEffectKeys.crownOfTheBlackSunFinisher,
          value: 3,
        ),
      ): 3,
    },
  ),

  /////////////////////////////---INAMOVIBLE---///////////////////////////////////////

  /// Slate Buckler
  Item(
    affinity: ItemArchetypeAffinity.inamovible,
    name: 'Slate Buckler',
    description: 'A plain stone-reinforced buckler. Heavy, ugly, reliable.',
    tier: RarityTier.gray,
    baseCost: 2,
    sellValue: 1,
    tags: <EntityTag>[
      EntityTag.barrera,
    ],
    asset: 'assets/sprites/items/SlateBuckler.png',
    effects: <Effect, int>{
      ActionEffect.block(value: 7): 7,
    },
  ),

  /// Oathplate
  Item(
    affinity: ItemArchetypeAffinity.inamovible,
    name: 'Oathplate',
    description:
        'A heavy defensive plate engraved with an old promise: stand still, endure, and let the enemy break first.',
    tier: RarityTier.green,
    baseCost: 4,
    sellValue: 2,
    tags: <EntityTag>[
      EntityTag.barrera,
      EntityTag.accesorio,
    ],
    asset: 'assets/sprites/items/Oathplate.png',
    effects: <Effect, int>{
      ActionEffect.block(value: 8): 8,
      const PassiveEffect(
        effectKey: ItemEffectKeys.oathplateCleanse,
        description:
            'At the start of your turn, if you have Block, cleanse up to --value-- negative status.',
        value: 1,
        hook: ItemEffectHook.turnStart,
      ): 1,
    },
  ),

  /// Whitewall Standard
  Item(
    affinity: ItemArchetypeAffinity.inamovible,
    name: 'Whitewall Standard',
    description:
        'A battle standard carried by those who refused to move. Every raised shield makes your will harder to break.',
    tier: RarityTier.blue,
    baseCost: 6,
    sellValue: 3,
    tags: <EntityTag>[
      EntityTag.accesorio,
      EntityTag.barrera,
      EntityTag.buff,
    ],
    asset: 'assets/sprites/items/WhitewallStandard.png',
    effects: <Effect, int>{
      const PassiveEffect(
        effectKey: ItemEffectKeys.whitewallStandardBarrierBoost,
        description:
            'Adjacent Barrier items have +--value-- additional Barrier.',
        value: 2,
        hook: ItemEffectHook.combatStart,
      ): 2,
      const PassiveEffect(
        effectKey: ItemEffectKeys.whitewallStandardBuffStacking,
        description:
            'Whenever you use 2 or more Barrier items in the same pattern, gain --value-- Calentando.',
        value: 1,
        hook: ItemEffectHook.patternUsed,
      ): 1,
    },
  ),

  /// Rampart Ram
  Item(
    affinity: ItemArchetypeAffinity.inamovible,
    name: 'Rampart Ram',
    description:
        'A siege ram made from broken shields. It carries the full weight of everything you survived.',
    tier: RarityTier.purple,
    baseCost: 8,
    sellValue: 4,
    tags: <EntityTag>[
      EntityTag.arma,
      EntityTag.ataque,
      EntityTag.barrera,
    ],
    asset: 'assets/sprites/items/RampartRam.png',
    effects: <Effect, int>{
      ActionEffect.block(value: 10): 10,
      ActionEffect.attack(value: 8): 8,
      const PassiveEffect(
        effectKey: ItemEffectKeys.rampartRamBarrierDamage,
        description:
            'Your attacks deal +--value-- damage for every 10 Barrier you have.',
        value: 2,
        hook: ItemEffectHook.outgoingDamageModifier,
      ): 2,
      PatternEffect(
        patternType: const OperativePatternRequirement.last(),
        actionEffect: const ActionEffect(
          actionType: ItemActionType.none,
          description:
              'If this ends the pattern, deal damage equal to --value-- times your current Barrier divided by 10.',
          customEffectKey: ItemEffectKeys.rampartRamFinisher,
          value: 4,
        ),
      ): 4,
    },
  ),

  /// Citadel Core
  Item(
    affinity: ItemArchetypeAffinity.inamovible,
    name: 'Citadel Core',
    description:
        'A living fortress-heart. Each layer of defense becomes another law of the battlefield: endure, cleanse, grow, retaliate.',
    tier: RarityTier.yellow,
    baseCost: 42,
    sellValue: 21,
    tags: <EntityTag>[
      EntityTag.accesorio,
      EntityTag.barrera,
      EntityTag.buff,
      EntityTag.cura,
      EntityTag.muralla,
    ],
    asset: 'assets/sprites/items/CitadelCore.png',
    effects: <Effect, int>{
      const PassiveEffect(
        effectKey: ItemEffectKeys.citadelCoreCleanseHeal,
        description:
            'Whenever you cleanse a negative status, heal --value-- HP and gain 1 Potencia.',
        value: 2,
        hook: ItemEffectHook.passive,
      ): 2,
      const PassiveEffect(
        effectKey: ItemEffectKeys.citadelCoreFortressScaling,
        description:
            'At the start of your turn, if you have 20 or more Barrier, gain --value-- Calentando.',
        value: 1,
        hook: ItemEffectHook.turnStart,
      ): 1,
      const PassiveEffect(
        effectKey: ItemEffectKeys.citadelCoreUnbrokenRetaliation,
        description:
            'When you resolve a defense, deal --value-- damage to the enemy for every buff stack currently on you.',
        value: 2,
        hook: ItemEffectHook.defendResolved,
      ): 2,
      PatternEffect(
        patternType: const OperativePatternRequirement.middle(),
        actionEffect: const ActionEffect(
          actionType: ItemActionType.none,
          description:
              'If used as the core(center) of a pattern, gain --value-- Barrier, cleanse 1 negative status, and deal damage equal to 25% of your current Barrier.',
          customEffectKey: ItemEffectKeys.citadelCoreSquareFortress,
          value: 12,
        ),
      ): 12,
    },
  ),

  /////////////////////////////---VELOZ---///////////////////////////////////////

  /// Pocket Shiv
  Item(
    affinity: ItemArchetypeAffinity.veloz,
    name: 'Pocket Shiv',
    description:
        'A tiny blade made for quick hands. It does not hit hard, but it is always ready.',
    tier: RarityTier.gray,
    baseCost: 2,
    sellValue: 1,
    tags: <EntityTag>[
      EntityTag.arma,
      EntityTag.ataque,
    ],
    asset: 'assets/sprites/items/PocketShiv.png',
    effects: <Effect, int>{
      ActionEffect.attack(value: 2): 2,
      ActionEffect.attack(value: 2): 2,
    },
  ),

  /// Needlewheel
  Item(
    affinity: ItemArchetypeAffinity.veloz,
    name: 'Needlewheel',
    description:
        'A spinning ring of tiny blades. Weak on its own, deadly when paired with poison.',
    tier: RarityTier.green,
    baseCost: 4,
    sellValue: 2,
    tags: <EntityTag>[
      EntityTag.arma,
      EntityTag.ataque,
    ],
    asset: 'assets/sprites/items/Needlewheel.png',
    effects: <Effect, int>{
      ActionEffect.attack(value: 1): 1,
      ActionEffect.attack(value: 1): 1,
      const ActionEffect(
        actionType: ItemActionType.none,
        description:
            'If this is your third action this turn or later, use this item --value-- additional times.',
        customEffectKey: ItemEffectKeys.needlewheelComboRepeat,
        value: 1,
      ): 1,
    },
  ),

  /// Venom Metronome
  Item(
    affinity: ItemArchetypeAffinity.veloz,
    name: 'Venotronome',
    description: 'A ticking vial that releases poison in a rhythmic pattern.',
    tier: RarityTier.blue,
    baseCost: 6,
    sellValue: 3,
    tags: <EntityTag>[
      EntityTag.accesorio,
      EntityTag.debuff,
      EntityTag.intoxicacion,
    ],
    asset: 'assets/sprites/items/VenomMetronome.png',
    effects: <Effect, int>{
      const PassiveEffect(
        effectKey: ItemEffectKeys.venomMetronomeRepeatedActionPoison,
        description:
            'Every two attacking actions, apply --value-- Intoxicacion.',
        value: 1,
        hook: ItemEffectHook.actionResolved,
      ): 2,
      PatternEffect(
        patternType: const OperativePatternRequirement.exactShape(
          shapeKind: OperativePatternShapeKind.zigzag,
        ),
        actionEffect: const ActionEffect(
          actionType: ItemActionType.none,
          description:
              'If used in a zigzag pattern, apply --value-- Conmocion and use your first weapon on the pattern again.',
          customEffectKey: ItemEffectKeys.venomMetronomeZigzag,
          value: 5,
        ),
      ): 5,
    },
  ),

  /// Leechwire Coil
  Item(
    affinity: ItemArchetypeAffinity.veloz,
    name: 'Leechwire Coil',
    description:
        'A bundle of living wires. Specially akeen to exploiting weaknesses.',
    tier: RarityTier.purple,
    baseCost: 8,
    sellValue: 4,
    tags: <EntityTag>[
      EntityTag.accesorio,
      EntityTag.debuff,
      EntityTag.cura,
      EntityTag.contagio,
    ],
    asset: 'assets/sprites/items/LeechwireCoil.png',
    effects: <Effect, int>{
      const PassiveEffect(
        effectKey: ItemEffectKeys.leechwireCoilHealFromDebuffs,
        description:
            'Whenever you apply a debuff, heal --value-- HP. This can only trigger 3 times per turn.',
        value: 2,
        hook: ItemEffectHook.outgoingStatusModifier,
      ): 2,
      const PassiveEffect(
        effectKey: ItemEffectKeys.leechwireCoilDebuffDamage,
        description:
            'Your attacks deal +--value-- damage for each different debuff on the enemy.',
        value: 2,
        hook: ItemEffectHook.outgoingDamageModifier,
      ): 2,
      PatternEffect(
        patternType: const OperativePatternRequirement.middle(),
        actionEffect: const ActionEffect(
          actionType: ItemActionType.none,
          description:
              'If this item is used in the middle of a pattern, apply --value-- Contagio.',
          customEffectKey: ItemEffectKeys.leechwireCoilMiddleContagio,
          value: 2,
        ),
      ): 2,
    },
  ),

  /// Thousand-Cut Halo
  Item(
    affinity: ItemArchetypeAffinity.veloz,
    name: 'Thousand-Cut Halo',
    description:
        'A ring of impossible blades that appears only when the rhythm is perfect. One cut is harmless. One thousand is judgment.',
    tier: RarityTier.yellow,
    baseCost: 10,
    sellValue: 5,
    tags: <EntityTag>[
      EntityTag.accesorio,
      EntityTag.arma,
      EntityTag.ataque,
      EntityTag.debuff,
    ],
    asset: 'assets/sprites/items/ThousandCutHalo.png',
    effects: <Effect, int>{
      const PassiveEffect(
        effectKey: ItemEffectKeys.thousandCutHaloActionScaling,
        description:
            'After your fourth action each turn, every further attack action has +--value--  damage, barrier or heal',
        value: 3,
        hook: ItemEffectHook.actionResolved,
      ): 3,
      const PassiveEffect(
        effectKey: ItemEffectKeys.thousandCutHaloStatusEcho,
        description:
            'Whenever you apply a debuff to an enemy, apply 1 stack of another random debuff they already have.',
        value: 1,
        hook: ItemEffectHook.outgoingStatusModifier,
      ): 1,
      PatternEffect(
        patternType: const OperativePatternRequirement.last(),
        actionEffect: const ActionEffect(
          actionType: ItemActionType.none,
          description:
              'If this ends the pattern, repeat your weakest weapon once for each different debuff on the enemy.',
          customEffectKey: ItemEffectKeys.thousandCutHaloFinisher,
          value: 1,
        ),
      ): 1,
    },
  ),
];

/// Stable catalog lookup populated alongside [itemPresets].
final Map<String, Item> itemPresetRegistry = Map<String, Item>.unmodifiable({
  for (final item in itemPresets) item.catalogKey: item,
});
