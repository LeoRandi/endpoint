import '_imports.dart';

List<Item> itemPresets = <Item>[
  /// Wooden Stick
  Item(
    affinity: ItemArchetypeAffinity.general,
    name: 'Wooden Stick',
    description:
        'A simple wooden stick. Not very effective, but better than nothing.',
    tier: RarityTier.gray,
    tags: <EntityTag>[EntityTag.arma],
    asset: 'assets/sprites/items/WoodenStick.png',
    effects: <Effect, List<int>>{
      ActionEffect.attack(value: 5): const <int>[5, 10, 15, 20, 25],
    },
  ),

  /// Sunglasses
  Item(
    affinity: ItemArchetypeAffinity.general,
    name: 'Sunglasses',
    description:
        'A pair of stylish sunglasses. The cooler you look, the more stuff you do, its simple math.',
    tier: RarityTier.yellow,
    tags: <EntityTag>[EntityTag.accesorio],
    asset: 'assets/sprites/items/wooden_stick.png',
    effects: <Effect, List<int>>{
      const ActionEffect(
          actionType: ItemActionType.none,
          description:
              'Take every action before this item is used an additional time.',
          customEffectKey: ItemEffectKeys.sunglasses,
          value: 0): const <int>[0]
    },
  ),

  /// Nano-bandage
  Item(
    affinity: ItemArchetypeAffinity.general,
    name: 'Nano-bandage',
    description: 'A small medical device that can quickly heal wounds.',
    tier: RarityTier.green,
    tags: <EntityTag>[EntityTag.cura, EntityTag.accesorio],
    asset: 'assets/sprites/items/wooden_stick.png',
    effects: <Effect, List<int>>{
      ActionEffect.heal(value: 5): const <int>[5, 10, 15, 20],
      const PassiveEffect(
        effectKey: ItemEffectKeys.nanoBandageTurnStartHeal,
        description: 'Heal for --value-- at the start of your turn.',
        value: 2,
        hook: ItemEffectHook.turnStart,
      ): const <int>[2, 4, 6, 8]
    },
  ),

  /// S-Harp-Ener
  Item(
    affinity: ItemArchetypeAffinity.general,
    name: 'S-Harp-Ener',
    description:
        'An ancient harp relic, said to amplify nearby blades and blasts, now a household commodity to sharpen your kitchen knives!',
    tier: RarityTier.green,
    valueModifier: 1,
    tags: <EntityTag>[EntityTag.accesorio],
    asset: 'assets/sprites/items/WoodenStick.png',
    effects: <Effect, List<int>>{
      const ActionEffect(
        actionType: ItemActionType.none,
        description: 'Give +--value-- permanent attack to adjacent weapons.',
        customEffectKey: ItemEffectKeys.sHarpEner,
        value: 1,
      ): const <int>[1, 2, 3, 4],
    },
  ),

  /// Shield Lance
  Item(
    affinity: ItemArchetypeAffinity.general,
    name: 'Shield Lance',
    description:
        'A compact spear built through the guard of a small shield, made to catch a blow before driving forward.',
    tier: RarityTier.green,
    tags: <EntityTag>[
      EntityTag.arma,
      EntityTag.barrera,
      EntityTag.ataque,
    ],
    asset: 'assets/sprites/items/WoodenStick.png',
    effects: <Effect, List<int>>{
      ActionEffect.block(value: 5): const <int>[5, 10, 15, 20],
      PatternEffect(
        patternType: const OperativePatternRequirement.straightAngle(),
        actionEffect: ActionEffect.attack(value: 8),
      ): const <int>[8, 12, 16, 20],
    },
  ),

  /////////////////////////////---IMPARABLE---///////////////////////////////////////

  /// Rusted Cleaver
  Item(
    affinity: ItemArchetypeAffinity.imparable,
    name: 'Rusted Cleaver',
    description: 'A crude, heavy cleaver. It just cuts.',
    tier: RarityTier.gray,
    tags: <EntityTag>[
      EntityTag.arma,
      EntityTag.ataque,
    ],
    asset: 'assets/sprites/items/RustedCleaver.png',
    effects: <Effect, List<int>>{
      ActionEffect.attack(value: 6): const <int>[6, 12, 18, 24, 30],
    },
  ),

  /// Duelist Chalk
  Item(
    affinity: ItemArchetypeAffinity.imparable,
    name: 'Duelist Chalk',
    description:
        'A piece of red chalk used to draw ritualistic dueling circles. Cross it, and someone will bleed.',
    tier: RarityTier.gray,
    tags: <EntityTag>[
      EntityTag.desafio,
      EntityTag.buff,
    ],
    asset: 'assets/sprites/items/DuelistChalk.png',
    effects: <Effect, List<int>>{
      const ActionEffect(
        actionType: ItemActionType.none,
        description: 'Gain --value-- Desafio.',
        customEffectKey: ItemEffectKeys.duelistChalkGainDesafio,
        value: 4,
      ): const <int>[4, 8, 12, 16, 20],
    },
  ),

  /// Kindling Axe
  Item(
    affinity: ItemArchetypeAffinity.imparable,
    name: 'Kindling Axe',
    description:
        'A brutal axe with a smoldering edge. It burns the enemy, burns the wielder, and solves most problems by making them worse first.',
    tier: RarityTier.green,
    tags: <EntityTag>[
      EntityTag.arma,
      EntityTag.ataque,
      EntityTag.quemadura,
      EntityTag.debuff
    ],
    asset: 'assets/sprites/items/KindlingAxe.png',
    effects: <Effect, List<int>>{
      ActionEffect.attack(value: 10): const <int>[10, 20, 30, 40],
      const ActionEffect(
        actionType: ItemActionType.none,
        description:
            'Apply --value-- Burn to the enemy and 2 Burn to yourself.',
        customEffectKey: ItemEffectKeys.kindlingAxeBurnBoth,
        value: 2,
      ): const <int>[2, 4, 6, 8],
    },
  ),

  /// Spite Hook
  Item(
    affinity: ItemArchetypeAffinity.imparable,
    name: 'Spite Hook',
    description:
        'A hooked blade that bites deeper when its wielder is already bleeding.',
    tier: RarityTier.green,
    tags: <EntityTag>[
      EntityTag.arma,
      EntityTag.ataque,
      EntityTag.desafio,
      EntityTag.buff,
    ],
    asset: 'assets/sprites/items/SpiteHook.png',
    effects: <Effect, List<int>>{
      ActionEffect.attack(value: 8): const <int>[8, 16, 24, 32],
      const PassiveEffect(
        effectKey: ItemEffectKeys.spiteHookRevengeStrike,
        description:
            'If you received damage this turn before using this item, gain --value-- Desafio before your next action.',
        value: 4,
        hook: ItemEffectHook.actionResolved,
      ): const <int>[4, 8, 12, 16],
    },
  ),

  /// Ash-Eater Mask
  Item(
    affinity: ItemArchetypeAffinity.imparable,
    name: 'Ash-Eater Mask',
    description:
        'A scorched mask worn by fighters who breathe better when the air is full of smoke and pain.',
    tier: RarityTier.green,
    tags: <EntityTag>[
      EntityTag.accesorio,
      EntityTag.quemadura,
      EntityTag.buff,
      EntityTag.vida,
    ],
    asset: 'assets/sprites/items/AshEaterMask.png',
    effects: <Effect, List<int>>{
      const PassiveEffect(
        effectKey: ItemEffectKeys.ashEaterMaskBurnPotencia,
        description:
            'At the start of your turn, if you have Burn, gain --value-- Potencia.',
        value: 1,
        hook: ItemEffectHook.turnStart,
      ): const <int>[1, 2, 3, 4],
      const ActionEffect(
        actionType: ItemActionType.none,
        description:
            'Apply --value-- Burn to yourself. If you are below half HP, heal --value-- HP.',
        customEffectKey: ItemEffectKeys.ashEaterMaskSelfBurnHeal,
        value: 2,
      ): const <int>[2, 4, 6, 8],
    },
  ),

  /// Furnace Heart
  Item(
    affinity: ItemArchetypeAffinity.imparable,
    name: 'Furnace Heart',
    description:
        'A pulsing metal core that feeds every nearby weapon with heat. The longer you burn, the louder it beats.',
    tier: RarityTier.blue,
    tags: <EntityTag>[
      EntityTag.accesorio,
      EntityTag.quemadura,
      EntityTag.debuff,
      EntityTag.ataque,
    ],
    asset: 'assets/sprites/items/FurnaceHeart.png',
    effects: <Effect, List<int>>{
      const PassiveEffect(
        effectKey: ItemEffectKeys.furnaceHeartAdjacentWeapons,
        description:
            'Adjacent weapons gain +--value-- attack. If you have Burn, they also apply 1 Burn to the enemy when used.',
        value: 2,
        hook: ItemEffectHook.combatStart,
      ): const <int>[2, 3, 4],
      PatternEffect(
        patternType: const OperativePatternRequirement.middle(),
        actionEffect: const ActionEffect(
          actionType: ItemActionType.none,
          description:
              'If used in the middle of a pattern, apply --value-- Burn to yourself, then use adjacent weapons on the pattern an additional time.',
          customEffectKey: ItemEffectKeys.furnaceHeartRightAngleTrigger,
          value: 1,
        ),
      ): const <int>[1, 2, 3],
    },
  ),

  /// Challenge Brand
  Item(
    affinity: ItemArchetypeAffinity.imparable,
    name: 'Challenge Brand',
    description:
        'A burning iron seal pressed into your own armor, sizzling each time your anger flares.',
    tier: RarityTier.blue,
    tags: <EntityTag>[
      EntityTag.accesorio,
      EntityTag.desafio,
      EntityTag.quemadura,
      EntityTag.debuff,
      EntityTag.buff,
    ],
    asset: 'assets/sprites/items/ChallengeBrand.png',
    effects: <Effect, List<int>>{
      const PassiveEffect(
        effectKey: ItemEffectKeys.challengeBrandCounterBurn,
        description:
            'Whenever an enemy counters your Desafio attack, apply --value-- Burn to both you and the enemy.',
        value: 1,
        hook: ItemEffectHook.receiveDamageResolved,
      ): const <int>[1, 2, 3],
      PatternEffect(
        patternType: const OperativePatternRequirement.first(),
        actionEffect: const ActionEffect(
          actionType: ItemActionType.none,
          description:
              'If this starts the pattern, gain --value-- Desafio. If you have Burn, also heal --value-- HP.',
          customEffectKey: ItemEffectKeys.challengeBrandRightAngleDesafio,
          value: 3,
        ),
      ): const <int>[3, 6, 9],
    },
  ),

  /// Bloodflame Gauntlet
  Item(
    affinity: ItemArchetypeAffinity.imparable,
    name: 'Bloodflame Gauntlet',
    description:
        'A cursed gauntlet that absorbs pain and spits it back as fire. It is safe as long as it is killing something.',
    tier: RarityTier.purple,
    tags: <EntityTag>[
      EntityTag.arma,
      EntityTag.ataque,
      EntityTag.quemadura,
      EntityTag.debuff,
      EntityTag.vida,
    ],
    asset: 'assets/sprites/items/BloodflameGauntlet.png',
    effects: <Effect, List<int>>{
      ActionEffect.attack(value: 12): const <int>[12, 24],
      const PassiveEffect(
        effectKey: ItemEffectKeys.bloodflameGauntletLowHpDamage,
        description:
            'Your attacks deal +--value-- damage while you are below half HP. Double this bonus if you have Burn.',
        value: 3,
        hook: ItemEffectHook.outgoingDamageModifier,
      ): const <int>[3, 6],
      const PassiveEffect(
        effectKey: ItemEffectKeys.bloodflameGauntletBurnRevenge,
        description:
            'Whenever you receive damage from Burn, your next attack applies --value-- Burn to the enemy.',
        value: 2,
        hook: ItemEffectHook.receiveDamageResolved,
      ): const <int>[2, 4],
    },
  ),

  /// Execution Bell
  Item(
    affinity: ItemArchetypeAffinity.imparable,
    name: 'Execution Bell',
    description:
        'A cracked iron bell, chained and used as a weapon. Dont let it toll for you.',
    tier: RarityTier.purple,
    tags: <EntityTag>[
      EntityTag.arma,
      EntityTag.ataque,
      EntityTag.desafio,
      EntityTag.buff,
      EntityTag.quemadura,
      EntityTag.debuff,
    ],
    asset: 'assets/sprites/items/ExecutionBell.png',
    effects: <Effect, List<int>>{
      ActionEffect.attack(value: 10): const <int>[10, 20],
      const PassiveEffect(
        effectKey: ItemEffectKeys.executionBellDesafioDamage,
        description:
            'Your attacks deal 2 extra damage for every --value-- Desafio you gained this combat.',
        value: 5,
        hook: ItemEffectHook.outgoingDamageModifier,
      ): const <int>[5, 3],
      const PassiveEffect(
        effectKey: ItemEffectKeys.executionBellCounterRevenge,
        description:
            'Your first --value-- Desafio attacks each combat apply 5 burn to the enemy.',
        value: 2,
        hook: ItemEffectHook.receiveDamageResolved,
      ): const <int>[2, 4],
    },
  ),

  /// Crown of the Last Ember
  Item(
    affinity: ItemArchetypeAffinity.imparable,
    name: 'Crown of the Black Sun',
    description:
        'A cracked crown burning with the final flame of a dead king. It does not ask you to survive. It asks you to end the fight first.',
    tier: RarityTier.yellow,
    valueModifier: 15,
    tags: <EntityTag>[
      EntityTag.accesorio,
      EntityTag.quemadura,
      EntityTag.buff,
      EntityTag.ataque,
      EntityTag.desafio,
    ],
    asset: 'assets/sprites/items/CrownOfTheBlackSun.png',
    effects: <Effect, List<int>>{
      const PassiveEffect(
        effectKey: ItemEffectKeys.crownOfTheBlackSunBurnScaling,
        description:
            'Your attacks deal +--value-- damage for each Burn on you and on the enemy.',
        value: 1,
        hook: ItemEffectHook.outgoingDamageModifier,
      ): const <int>[1],
      const PassiveEffect(
        effectKey: ItemEffectKeys.crownOfTheBlackSunNoDeathOnce,
        description:
            'The first time you hurt an enemy each fight, apply --value-- Burn to both you and the enemy, then use all adjacent weapons once.',
        value: 2,
        hook: ItemEffectHook.attackResolved,
      ): const <int>[2],
      PatternEffect(
        patternType: const OperativePatternRequirement.last(),
        actionEffect: const ActionEffect(
          actionType: ItemActionType.none,
          description:
              'If this ends the pattern, consume half of your Burn to deal --value-- true damage per Burn consumed.',
          customEffectKey: ItemEffectKeys.crownOfTheBlackSunFinisher,
          value: 3,
        ),
      ): const <int>[3],
    },
  ),

  /////////////////////////////---INAMOVIBLE---///////////////////////////////////////

  /// Slate Buckler
  Item(
    affinity: ItemArchetypeAffinity.inamovible,
    name: 'Slate Buckler',
    description: 'A plain stone-reinforced buckler. Heavy, ugly, reliable.',
    tier: RarityTier.gray,
    tags: <EntityTag>[
      EntityTag.barrera,
    ],
    asset: 'assets/sprites/items/SlateBuckler.png',
    effects: <Effect, List<int>>{
      ActionEffect.block(value: 7): const <int>[7, 14, 21, 28, 35],
    },
  ),

  /// Oathplate
  Item(
    affinity: ItemArchetypeAffinity.inamovible,
    name: 'Oathplate',
    description:
        'A heavy defensive plate engraved with an old promise: stand still, endure, and let the enemy break first.',
    tier: RarityTier.green,
    tags: <EntityTag>[
      EntityTag.barrera,
      EntityTag.accesorio,
    ],
    asset: 'assets/sprites/items/Oathplate.png',
    effects: <Effect, List<int>>{
      ActionEffect.block(value: 8): const <int>[8, 16, 24, 32],
      const PassiveEffect(
        effectKey: ItemEffectKeys.oathplateCleanse,
        description:
            'At the start of your turn, if you have Block, cleanse up to --value-- negative status.',
        value: 1,
        hook: ItemEffectHook.turnStart,
      ): const <int>[1, 2, 3, 4],
    },
  ),

  /// Whitewall Standard
  Item(
    affinity: ItemArchetypeAffinity.inamovible,
    name: 'Whitewall Standard',
    description:
        'A battle standard carried by those who refused to move. Every raised shield makes your will harder to break.',
    tier: RarityTier.blue,
    tags: <EntityTag>[
      EntityTag.accesorio,
      EntityTag.barrera,
      EntityTag.buff,
    ],
    asset: 'assets/sprites/items/WhitewallStandard.png',
    effects: <Effect, List<int>>{
      const PassiveEffect(
        effectKey: ItemEffectKeys.whitewallStandardBarrierBoost,
        description:
            'Adjacent Barrier items have +--value-- additional Barrier.',
        value: 2,
        hook: ItemEffectHook.combatStart,
      ): const <int>[2, 4, 6],
      const PassiveEffect(
        effectKey: ItemEffectKeys.whitewallStandardBuffStacking,
        description:
            'Whenever you use 2 or more Barrier items in the same pattern, gain --value-- Calentando.',
        value: 1,
        hook: ItemEffectHook.patternUsed,
      ): const <int>[1, 2, 3],
    },
  ),

  /// Rampart Ram
  Item(
    affinity: ItemArchetypeAffinity.inamovible,
    name: 'Rampart Ram',
    description:
        'A siege ram made from broken shields. It carries the full weight of everything you survived.',
    tier: RarityTier.purple,
    tags: <EntityTag>[
      EntityTag.arma,
      EntityTag.ataque,
      EntityTag.barrera,
    ],
    asset: 'assets/sprites/items/RampartRam.png',
    effects: <Effect, List<int>>{
      ActionEffect.block(value: 10): const <int>[10, 20],
      ActionEffect.attack(value: 8): const <int>[8, 16],
      const PassiveEffect(
        effectKey: ItemEffectKeys.rampartRamBarrierDamage,
        description:
            'Your attacks deal +--value-- damage for every 10 Barrier you have.',
        value: 2,
        hook: ItemEffectHook.outgoingDamageModifier,
      ): const <int>[2, 4],
      PatternEffect(
        patternType: const OperativePatternRequirement.last(),
        actionEffect: const ActionEffect(
          actionType: ItemActionType.none,
          description:
              'If this ends the pattern, deal damage equal to --value-- times your current Barrier divided by 10.',
          customEffectKey: ItemEffectKeys.rampartRamFinisher,
          value: 4,
        ),
      ): const <int>[4, 8],
    },
  ),

  /// Citadel Core
  Item(
    affinity: ItemArchetypeAffinity.inamovible,
    name: 'Citadel Core',
    description:
        'A living fortress-heart. Each layer of defense becomes another law of the battlefield: endure, cleanse, grow, retaliate.',
    tier: RarityTier.yellow,
    valueModifier: 16,
    tags: <EntityTag>[
      EntityTag.accesorio,
      EntityTag.barrera,
      EntityTag.buff,
      EntityTag.cura,
      EntityTag.muralla,
    ],
    asset: 'assets/sprites/items/CitadelCore.png',
    effects: <Effect, List<int>>{
      const PassiveEffect(
        effectKey: ItemEffectKeys.citadelCoreCleanseHeal,
        description:
            'Whenever you cleanse a negative status, heal --value-- HP and gain 1 Potencia.',
        value: 2,
        hook: ItemEffectHook.passive,
      ): const <int>[2],
      const PassiveEffect(
        effectKey: ItemEffectKeys.citadelCoreFortressScaling,
        description:
            'At the start of your turn, if you have 20 or more Barrier, gain --value-- Calentando.',
        value: 1,
        hook: ItemEffectHook.turnStart,
      ): const <int>[1],
      const PassiveEffect(
        effectKey: ItemEffectKeys.citadelCoreUnbrokenRetaliation,
        description:
            'When you resolve a defense, deal --value-- damage to the enemy for every buff stack currently on you.',
        value: 2,
        hook: ItemEffectHook.defendResolved,
      ): const <int>[2],
      PatternEffect(
        patternType: const OperativePatternRequirement.middle(),
        actionEffect: const ActionEffect(
          actionType: ItemActionType.none,
          description:
              'If used as the core(center) of a pattern, gain --value-- Barrier, cleanse 1 negative status, and deal damage equal to 25% of your current Barrier.',
          customEffectKey: ItemEffectKeys.citadelCoreSquareFortress,
          value: 12,
        ),
      ): const <int>[12],
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
    tags: <EntityTag>[
      EntityTag.arma,
      EntityTag.ataque,
    ],
    asset: 'assets/sprites/items/PocketShiv.png',
    effects: <Effect, List<int>>{
      ActionEffect.attack(value: 2): const <int>[2, 4, 6, 8, 10],
      ActionEffect.attack(value: 2): const <int>[2, 4, 6, 8, 10],
    },
  ),

  /// Needlewheel
  Item(
    affinity: ItemArchetypeAffinity.veloz,
    name: 'Needlewheel',
    description:
        'A spinning ring of tiny blades. Weak on its own, deadly when paired with poison.',
    tier: RarityTier.green,
    tags: <EntityTag>[
      EntityTag.arma,
      EntityTag.ataque,
    ],
    asset: 'assets/sprites/items/Needlewheel.png',
    effects: <Effect, List<int>>{
      ActionEffect.attack(value: 1): const <int>[1, 2, 3, 4],
      ActionEffect.attack(value: 1): const <int>[1, 2, 3, 4],
      const ActionEffect(
        actionType: ItemActionType.none,
        description:
            'If this is exactly your third action this turn, use this item --value-- additional times.',
        customEffectKey: ItemEffectKeys.needlewheelComboRepeat,
        value: 1,
      ): const <int>[1, 2, 3, 4],
    },
  ),

  /// Venotronome
  Item(
    affinity: ItemArchetypeAffinity.veloz,
    name: 'Venotronome',
    description: 'A ticking vial that releases poison in a rhythmic pattern.',
    tier: RarityTier.blue,
    tags: <EntityTag>[
      EntityTag.accesorio,
      EntityTag.debuff,
      EntityTag.intoxicacion,
    ],
    asset: 'assets/sprites/items/Venotronome.png',
    effects: <Effect, List<int>>{
      const PassiveEffect(
        effectKey: ItemEffectKeys.venotronomeRepeatedActionPoison,
        description:
            'Every two attacking actions, apply --value-- Intoxicacion.',
        value: 1,
        hook: ItemEffectHook.attackResolved,
      ): const <int>[1, 1, 1],
      PatternEffect(
        patternType: const OperativePatternRequirement.rightAngle(),
        actionEffect: const ActionEffect(
          actionType: ItemActionType.none,
          description: 'If used in a 90 degree turn, apply --value-- Conmocion',
          customEffectKey: ItemEffectKeys.venotronomeZigzag,
          value: 3,
        ),
      ): const <int>[3, 6, 9],
    },
  ),

  /// Leechwire Coil
  Item(
    affinity: ItemArchetypeAffinity.veloz,
    name: 'Leechwire Coil',
    description:
        'A bundle of living wires. Specially akeen to exploiting weaknesses.',
    tier: RarityTier.purple,
    tags: <EntityTag>[
      EntityTag.accesorio,
      EntityTag.debuff,
      EntityTag.cura,
      EntityTag.contagio,
    ],
    asset: 'assets/sprites/items/LeechwireCoil.png',
    effects: <Effect, List<int>>{
      const PassiveEffect(
        effectKey: ItemEffectKeys.leechwireCoilHealFromDebuffs,
        description:
            'Whenever you apply a debuff, heal --value-- HP. This can only trigger 3 times per turn.',
        value: 2,
        hook: ItemEffectHook.outgoingStatusModifier,
      ): const <int>[2, 4],
      const PassiveEffect(
        effectKey: ItemEffectKeys.leechwireCoilDebuffDamage,
        description:
            'Your attacks deal +--value-- damage for each different debuff on the enemy.',
        value: 2,
        hook: ItemEffectHook.outgoingDamageModifier,
      ): const <int>[2, 4],
      PatternEffect(
        patternType: const OperativePatternRequirement.middle(),
        actionEffect: const ActionEffect(
          actionType: ItemActionType.none,
          description:
              'If this item is used in the middle of a pattern, apply --value-- Contagio.',
          customEffectKey: ItemEffectKeys.leechwireCoilMiddleContagio,
          value: 2,
        ),
      ): const <int>[2, 4],
    },
  ),

  /// Thousand-Cut Halo
  Item(
    affinity: ItemArchetypeAffinity.veloz,
    name: 'Thousand-Cut Halo',
    description:
        'A ring of impossible blades that appears only when the rhythm is perfect. One cut is harmless. One thousand is judgment.',
    tier: RarityTier.yellow,
    tags: <EntityTag>[
      EntityTag.accesorio,
      EntityTag.arma,
      EntityTag.ataque,
      EntityTag.debuff,
    ],
    asset: 'assets/sprites/items/ThousandCutHalo.png',
    effects: <Effect, List<int>>{
      const PassiveEffect(
        effectKey: ItemEffectKeys.thousandCutHaloActionScaling,
        description:
            'After your fourth action each turn, every further attack action has +--value--  damage, barrier or heal',
        value: 3,
        hook: ItemEffectHook.actionResolved,
      ): const <int>[3],
      const PassiveEffect(
        effectKey: ItemEffectKeys.thousandCutHaloStatusEcho,
        description:
            'Whenever you apply a debuff to an enemy, apply 1 stack of another random debuff they already have.',
        value: 1,
        hook: ItemEffectHook.outgoingStatusModifier,
      ): const <int>[1],
      PatternEffect(
        patternType: const OperativePatternRequirement.last(),
        actionEffect: const ActionEffect(
          actionType: ItemActionType.none,
          description:
              'If this ends the pattern, repeat your weakest weapon once for each different debuff on the enemy.',
          customEffectKey: ItemEffectKeys.thousandCutHaloFinisher,
          value: 1,
        ),
      ): const <int>[1],
    },
  ),

  /////////////////////////////---Mercante---///////////////////////////////////////

  /// Brass Multitool
  Item(
    affinity: ItemArchetypeAffinity.mercante,
    name: 'Brass Multitool',
    description:
        'A cheap folding tool with too many functions and none of them impressive. Still, it always has the right attachment.',
    tier: RarityTier.gray,
    tags: <EntityTag>[
      EntityTag.ataque,
      EntityTag.barrera,
      EntityTag.cura,
      EntityTag.accesorio,
      EntityTag.arma,
    ],
    asset: 'assets/sprites/items/BrassMultitool.png',
    effects: <Effect, List<int>>{
      ActionEffect.attack(value: 2): const <int>[2, 4, 6, 8, 10],
      ActionEffect.block(value: 2): const <int>[2, 4, 6, 8, 10],
      ActionEffect.heal(value: 2): const <int>[2, 4, 6, 8, 10],
    },
  ),

  /// Lanzamonedas
  Item(
    affinity: ItemArchetypeAffinity.mercante,
    name: 'Lanzamonedas',
    description:
        'A ridiculous rocket launcher with a cartoonish bag of coins strapped on top. It turns bad financial decisions into direct violence.',
    tier: RarityTier.green,
    tags: <EntityTag>[
      EntityTag.arma,
      EntityTag.ataque,
      EntityTag.economia,
    ],
    asset: 'assets/sprites/items/Lanzamonedas.png',
    effects: <Effect, List<int>>{
      ActionEffect.attack(value: 5): const <int>[5, 10, 15, 20],
      const ActionEffect(
        actionType: ItemActionType.none,
        description:
            'Spend 2 Gold to deal --value-- extra true damage. If you cannot pay, this effect does nothing.',
        customEffectKey: ItemEffectKeys.lanzamonedasSpendGoldDamage,
        value: 5,
      ): const <int>[5, 10, 15, 20],
    },
  ),

  /// Cashback Badge
  Item(
    affinity: ItemArchetypeAffinity.mercante,
    name: 'Cashback Badge',
    description:
        'A polished badge awarded to reckless spenders. Somehow, every purchase feels like profit.',
    tier: RarityTier.blue,
    tags: <EntityTag>[
      EntityTag.accesorio,
      EntityTag.economia,
      EntityTag.buff,
    ],
    asset: 'assets/sprites/items/CashbackBadge.png',
    effects: <Effect, List<int>>{
      const PassiveEffect(
        effectKey: ItemEffectKeys.cashbackBadgeRefund,
        description:
            'The first time each turn you spend Gold through an item effect, recover --value-- Gold.',
        value: 1,
        hook: ItemEffectHook.passive,
      ): const <int>[1, 2, 3],
      const PassiveEffect(
        effectKey: ItemEffectKeys.cashbackBadgeSpendPotencia,
        description:
            'Whenever you gain Gold through an item effect, gain --value-- Potencia.',
        value: 1,
        hook: ItemEffectHook.passive,
      ): const <int>[1, 2, 3],
      PatternEffect(
        patternType: const OperativePatternRequirement.first(),
        actionEffect: const ActionEffect(
          actionType: ItemActionType.none,
          description: 'If this starts the pattern, gain --value-- Gold.',
          customEffectKey: ItemEffectKeys.cashbackBadgeOpeningDiscount,
          value: 1,
        ),
      ): const <int>[1, 2, 3],
    },
  ),

  /// Contraband Catalogue
  Item(
    affinity: ItemArchetypeAffinity.mercante,
    name: 'Contraband Catalogue',
    description:
        'A forbidden catalogue full of things no honest shop should sell. Perfect for someone with flexible morals and enough money.',
    tier: RarityTier.purple,
    tags: <EntityTag>[
      EntityTag.accesorio,
      EntityTag.economia,
      EntityTag.buff,
    ],
    asset: 'assets/sprites/items/ContrabandCatalogue.png',
    effects: <Effect, List<int>>{
      const PassiveEffect(
        effectKey: ItemEffectKeys.contrabandCatalogueMixedArchetypeScaling,
        description:
            'At combat start, gain --value-- Potencia for each different non-Mercante item affinity equipped.',
        value: 1,
        hook: ItemEffectHook.combatStart,
      ): const <int>[1, 2],
      const PassiveEffect(
        effectKey: ItemEffectKeys.contrabandCatalogueGoldSpendEcho,
        description:
            'Whenever you spend Gold through an item effect, repeat the weakest non-Mercante item used this pattern --value-- times.',
        value: 1,
        hook: ItemEffectHook.patternUsed,
      ): const <int>[1, 2],
      PatternEffect(
        patternType: const OperativePatternRequirement.middle(),
        actionEffect: const ActionEffect(
          actionType: ItemActionType.none,
          description:
              'If this is used in the middle of a pattern, gain --value-- Gold for each different item affinity used in this pattern.',
          customEffectKey: ItemEffectKeys.contrabandCatalogueMiddleProfit,
          value: 1,
        ),
      ): const <int>[1, 2],
    },
  ),

  /// Golden Godfather
  Item(
    affinity: ItemArchetypeAffinity.mercante,
    name: 'Golden Godfather',
    description:
        'A grinning golden idol of impossible wealth. It does not fight for you. It simply pays reality to lose.',
    tier: RarityTier.yellow,
    tags: <EntityTag>[
      EntityTag.accesorio,
      EntityTag.economia,
      EntityTag.ataque,
    ],
    asset: 'assets/sprites/items/GoldenGodfather.png',
    effects: <Effect, List<int>>{
      ActionEffect.attack(value: 10): const <int>[10],
      ActionEffect.block(value: 10): const <int>[10],
      ActionEffect.heal(value: 10): const <int>[10],
      const PassiveEffect(
        effectKey: ItemEffectKeys.goldenGodfatherRichScaling,
        description:
            'Your attack, Barrier and healing effects have +--value-- power for every 10 Gold you have.',
        value: 1,
        hook: ItemEffectHook.actionResolved,
      ): const <int>[1],
      PatternEffect(
        patternType: const OperativePatternRequirement.last(),
        actionEffect: const ActionEffect(
          actionType: ItemActionType.none,
          description:
              'If this ends the pattern, gain --value-- Gold for each different action type used in this pattern.',
          customEffectKey: ItemEffectKeys.goldenGodfatherFinisher,
          value: 5,
        ),
      ): const <int>[5],
    },
  ),
];

/// Stable catalog lookup populated alongside [itemPresets].
final Map<String, Item> itemPresetRegistry = Map<String, Item>.unmodifiable({
  for (final item in itemPresets) item.catalogKey: item,
});
