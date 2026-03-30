import '../_imports.dart';

const _ataqueTags = <EntityTag>[
  EntityTag.ataque,
];
const _defensaTags = <EntityTag>[
  EntityTag.defensa,
];
const _ataqueDefensaTags = <EntityTag>[
  EntityTag.ataque,
  EntityTag.defensa,
];
const _vidaTags = <EntityTag>[
  EntityTag.vida,
];
const _vidaDefensaTags = <EntityTag>[
  EntityTag.vida,
  EntityTag.defensa,
];
const _economiaVidaTags = <EntityTag>[
  EntityTag.economia,
  EntityTag.vida,
];
const _ataqueBuffTags = <EntityTag>[
  EntityTag.ataque,
  EntityTag.buff,
];
const _ataqueDebuffIntoxicacionTags = <EntityTag>[
  EntityTag.ataque,
  EntityTag.debuff,
  EntityTag.intoxicacion,
];
const _debuffQuemaduraTags = <EntityTag>[
  EntityTag.debuff,
  EntityTag.quemadura,
];
const _debuffIntoxicacionTags = <EntityTag>[
  EntityTag.debuff,
  EntityTag.intoxicacion,
];
const _debuffQuemaduraIntoxicacionTags = <EntityTag>[
  EntityTag.debuff,
  EntityTag.quemadura,
  EntityTag.intoxicacion,
];
const _ataqueVidaTags = <EntityTag>[
  EntityTag.ataque,
  EntityTag.vida,
];
const _ataqueDebuffTags = <EntityTag>[
  EntityTag.ataque,
  EntityTag.debuff,
];
const _ataqueDebuffDefensaTags = <EntityTag>[
  EntityTag.ataque,
  EntityTag.debuff,
  EntityTag.defensa,
];
const _defensaDebuffTags = <EntityTag>[
  EntityTag.defensa,
  EntityTag.debuff,
];
const _defensaBuffTags = <EntityTag>[
  EntityTag.defensa,
  EntityTag.buff,
];
const _ataqueDefensaBuffTags = <EntityTag>[
  EntityTag.ataque,
  EntityTag.defensa,
  EntityTag.buff,
];

/// Arma gris sencilla para encuentros y tiendas de bajo nivel.
const woodenStickItem = Item(
  id: ItemId.woodenStick,
  tags: _ataqueTags,
  name: 'Palo',
  description: '+1 ATK mientras este equipado.',
  iconEmoji: '\u{1FAB5}',
  slot: ItemSlot.weapon,
  rarity: RarityTier.gray,
  baseCost: 2,
  value: 1,
  upgradeValue: 1,
  statModifiers: {
    BattlerStat.attack: 1,
  },
  upgradeStatModifiers: {
    BattlerStat.attack: 1,
  },
);

/// Variante agil del arma basica usada por el arquetipo Veloz.
const cyberWhipsItem = Item(
  id: ItemId.cyberWhips,
  tags: _ataqueDebuffIntoxicacionTags,
  name: 'Cyber Latigos',
  description:
      '+1 ATK. Al atacar: aplica o aumenta Intoxicacion en el enemigo.',
  iconEmoji: '\u{26D3}',
  slot: ItemSlot.weapon,
  rarity: RarityTier.green,
  baseCost: 4,
  value: 1,
  upgradeValue: 1,
  statModifiers: {
    BattlerStat.attack: 1,
  },
  effect: IntoxicarOnAttackItemEffect(),
);

/// Accesorio agil que reduce el ATK total para convertir cada ataque en doble golpe.
const sunglassesItem = Item(
  id: ItemId.sunglasses,
  tags: _ataqueDefensaTags,
  name: 'Gafas de Sol',
  description:
      '+1 DEF. Mitad de ATK, pero cada ataque basico golpea dos veces.',
  iconEmoji: '\u{1F453}',
  slot: ItemSlot.accessory,
  rarity: RarityTier.gray,
  baseCost: 2,
  value: 1,
  upgradeValue: 1,
  statModifiers: {
    BattlerStat.defense: 1,
  },
  upgradeStatModifiers: {
    BattlerStat.defense: 1,
  },
  effect: SunglassesItemEffect(),
);

/// Soporte defensivo verde para builds de aguante.
const shieldItem = Item(
  id: ItemId.shield,
  tags: _vidaDefensaTags,
  name: 'Escudo',
  description: '+2 DEF. Al inicio de tu turno, recuperas 5 HP.',
  iconEmoji: '\u{1F6E1}',
  slot: ItemSlot.offHand,
  rarity: RarityTier.green,
  baseCost: 4,
  value: 5,
  upgradeValue: 5,
  statModifiers: {
    BattlerStat.defense: 2,
  },
  upgradeStatModifiers: {
    BattlerStat.defense: 2,
  },
  effect: RegenerativeShieldItemEffect(),
);

/// Accesorio verde que sube vida maxima y defensa a la vez.
const bulwarkAmuletItem = Item(
  id: ItemId.bulwarkAmulet,
  tags: _vidaDefensaTags,
  name: 'Amuleto de Bastion',
  description: '+6 HP y +1 DEF mientras este equipado.',
  iconEmoji: '\u{1F9FF}',
  slot: ItemSlot.accessory,
  rarity: RarityTier.green,
  baseCost: 4,
  value: 6,
  upgradeValue: 6,
  statModifiers: {
    BattlerStat.health: 6,
    BattlerStat.defense: 1,
  },
  upgradeStatModifiers: {
    BattlerStat.health: 6,
    BattlerStat.defense: 1,
  },
);

/// Accesorio gris que acelera la primera habilidad manual de cada combate.
const crackedBatteryItem = Item(
  id: ItemId.crackedBattery,
  name: 'Bateria Rajada',
  description: 'Accesorio inestable que exprime la primera habilidad manual.',
  iconEmoji: '\u{1F50B}',
  slot: ItemSlot.accessory,
  rarity: RarityTier.gray,
  baseCost: 2,
  value: 1,
  upgradeValue: 1,
  effect: CrackedBatteryItemEffect(),
);

/// Arma gris que castiga a objetivos sin buffs activos.
const impactGlovesItem = Item(
  id: ItemId.impactGloves,
  tags: _ataqueBuffTags,
  name: 'Guantes de Impacto',
  description: '+1 ATK y castigo extra contra objetivos sin buffs.',
  iconEmoji: '\u{1F9E4}',
  slot: ItemSlot.weapon,
  rarity: RarityTier.gray,
  baseCost: 2,
  value: 2,
  upgradeValue: 2,
  statModifiers: {
    BattlerStat.attack: 1,
  },
  upgradeStatModifiers: {
    BattlerStat.attack: 1,
  },
  effect: ImpactGlovesItemEffect(),
);

/// Accesorio verde ofensivo que aplica Intoxicacion al atacar.
const toxicCatalystItem = Item(
  id: ItemId.toxicCatalyst,
  tags: _debuffIntoxicacionTags,
  name: 'Catalizador Toxico',
  description: 'Accesorio quimico que contamina cada impacto.',
  iconEmoji: '\u2623',
  slot: ItemSlot.accessory,
  rarity: RarityTier.green,
  baseCost: 4,
  value: 1,
  upgradeValue: 1,
  effect: IntoxicarOnAttackItemEffect(),
);

/// Accesorio verde ofensivo que aplica Quemadura al atacar.
const emberCharmItem = Item(
  id: ItemId.emberCharm,
  tags: _debuffQuemaduraTags,
  name: 'Amuleto de Ascuas',
  description: 'Accesorio ofensivo que prende fuego en cada impacto.',
  iconEmoji: '\u{1F525}',
  slot: ItemSlot.accessory,
  rarity: RarityTier.green,
  baseCost: 4,
  value: 3,
  upgradeValue: 1,
  effect: QuemaduraOnAttackItemEffect(),
);

/// Accesorio verde defensivo contra Quemadura e Intoxicacion.
const chemicalFilterItem = Item(
  id: ItemId.chemicalFilter,
  tags: _debuffQuemaduraIntoxicacionTags,
  name: 'Filtro Quimico',
  description: 'Reduce la Quemadura y la Intoxicacion que recibes.',
  iconEmoji: '\u{1F637}',
  slot: ItemSlot.accessory,
  rarity: RarityTier.green,
  baseCost: 4,
  value: 1,
  upgradeValue: 1,
  effect: ChemicalFilterItemEffect(),
);

/// Soporte verde que cambia vida maxima por income adicional.
const billingModuleItem = Item(
  id: ItemId.billingModule,
  tags: _economiaVidaTags,
  name: 'Modulo de Cobro',
  description: 'Convierte soporte vital en ingresos operativos.',
  iconEmoji: '\u{1F4B3}',
  slot: ItemSlot.offHand,
  rarity: RarityTier.green,
  baseCost: 4,
  value: 2,
  upgradeValue: 1,
  incomePerValueUnit: 1,
  maxHealthPercentPerValueUnit: -5,
  effect: BillingModuleItemEffect(),
);

/// Arma verde de ataque alto para la progresion temprana.
const ironSwordItem = Item(
  id: ItemId.ironSword,
  tags: _ataqueTags,
  name: 'Espada de Hierro',
  description: '+3 ATK mientras este equipada.',
  iconEmoji: '\u2694',
  slot: ItemSlot.weapon,
  rarity: RarityTier.green,
  baseCost: 4,
  value: 3,
  upgradeValue: 3,
  statModifiers: {
    BattlerStat.attack: 3,
  },
  upgradeStatModifiers: {
    BattlerStat.attack: 3,
  },
);

/// Soporte verde defensivo para enemigos y tienda.
const guardShieldItem = Item(
  id: ItemId.guardShield,
  tags: _defensaTags,
  name: 'Escudo de Guardia',
  description: '+2 DEF mientras este equipado.',
  iconEmoji: '\u{1F6E1}',
  slot: ItemSlot.offHand,
  rarity: RarityTier.green,
  baseCost: 4,
  value: 2,
  upgradeValue: 2,
  statModifiers: {
    BattlerStat.defense: 2,
  },
  upgradeStatModifiers: {
    BattlerStat.defense: 2,
  },
);

/// Soporte azul reactivo que devuelve Quemadura al recibir golpes.
const reactiveCasingItem = Item(
  id: ItemId.reactiveCasing,
  tags: _debuffQuemaduraTags,
  name: 'Coraza Reactiva',
  description: 'Blindaje inestable que devuelve fuego al agresor.',
  iconEmoji: '\u{1F9F1}',
  slot: ItemSlot.offHand,
  rarity: RarityTier.blue,
  baseCost: 6,
  value: 4,
  upgradeValue: 1,
  effect: QuemaduraOnHitReceivedItemEffect(),
);

/// Arma gris de control ligero que debilita el siguiente golpe enemigo.
const stunBatonItem = Item(
  id: ItemId.stunBaton,
  tags: _ataqueDebuffTags,
  name: 'Porra de Aturdimiento',
  description: '+1 ATK. Al atacar: aplica Conmocion al enemigo.',
  iconEmoji: '\u{1F50C}',
  slot: ItemSlot.weapon,
  rarity: RarityTier.gray,
  baseCost: 2,
  value: 1,
  upgradeValue: 1,
  statModifiers: {
    BattlerStat.attack: 1,
  },
  upgradeStatModifiers: {
    BattlerStat.attack: 1,
  },
  effect: StatusItemEffect(
    kind: ItemStatusEffectKind.conmocion,
    trigger: ItemStatusEffectTrigger.attackTarget,
  ),
);

/// Armadura gris basica que refresca un pequeno escudo temporal cada turno.
const emergencyPlatingItem = Item(
  id: ItemId.emergencyPlating,
  tags: _defensaBuffTags,
  name: 'Placa de Emergencia',
  description: '+1 DEF. Al inicio de tu turno, recuperas Blindaje Temporal.',
  iconEmoji: '\u{1F6E1}',
  slot: ItemSlot.offHand,
  rarity: RarityTier.gray,
  baseCost: 2,
  value: 2,
  upgradeValue: 1,
  statModifiers: {
    BattlerStat.defense: 1,
  },
  upgradeStatModifiers: {
    BattlerStat.defense: 1,
  },
  effect: StatusItemEffect(
    kind: ItemStatusEffectKind.blindajeTemporal,
    trigger: ItemStatusEffectTrigger.turnStartOwnerRefreshMinimum,
  ),
);

/// Accesorio gris reactivo que silencia al agresor.
const pocketJammerItem = Item(
  id: ItemId.pocketJammer,
  tags: _defensaDebuffTags,
  name: 'Interferidor de Bolsillo',
  description: 'Al recibir dano: aplica Interferencia al agresor.',
  iconEmoji: '\u{1F4F6}',
  slot: ItemSlot.accessory,
  rarity: RarityTier.gray,
  baseCost: 2,
  value: 1,
  upgradeValue: 1,
  effect: StatusItemEffect(
    kind: ItemStatusEffectKind.interferencia,
    trigger: ItemStatusEffectTrigger.receiveDamageSource,
  ),
);

/// Arma verde orientada a romper defensas de forma estable.
const serratedEdgeItem = Item(
  id: ItemId.serratedEdge,
  tags: _ataqueDebuffDefensaTags,
  name: 'Sierra Dentada',
  description: '+1 ATK. Al atacar: aplica Fragilidad al enemigo.',
  iconEmoji: '\u2692',
  slot: ItemSlot.weapon,
  rarity: RarityTier.green,
  baseCost: 4,
  value: 2,
  upgradeValue: 1,
  statModifiers: {
    BattlerStat.attack: 1,
  },
  upgradeStatModifiers: {
    BattlerStat.attack: 1,
  },
  effect: StatusItemEffect(
    kind: ItemStatusEffectKind.fragilidad,
    trigger: ItemStatusEffectTrigger.attackTarget,
  ),
);

/// Armadura verde que estabiliza un Escudo de Energia constante.
const containmentCoilItem = Item(
  id: ItemId.containmentCoil,
  tags: _defensaBuffTags,
  name: 'Bobina de Contencion',
  description: '+1 DEF. Al inicio de tu turno, recuperas Escudo de Energia.',
  iconEmoji: '\u26A1',
  slot: ItemSlot.offHand,
  rarity: RarityTier.green,
  baseCost: 4,
  value: 1,
  upgradeValue: 1,
  statModifiers: {
    BattlerStat.defense: 1,
  },
  upgradeStatModifiers: {
    BattlerStat.defense: 1,
  },
  effect: StatusItemEffect(
    kind: ItemStatusEffectKind.escudoDeEnergia,
    trigger: ItemStatusEffectTrigger.turnStartOwnerRefreshMinimum,
  ),
);

/// Accesorio verde que acelera el escalado ofensivo golpe a golpe.
const thermalTurbineItem = Item(
  id: ItemId.thermalTurbine,
  tags: _ataqueBuffTags,
  name: 'Turbina Termica',
  description: 'Al atacar: genera o aumenta Calentando.',
  iconEmoji: '\u{1F525}',
  slot: ItemSlot.accessory,
  rarity: RarityTier.green,
  baseCost: 4,
  value: 1,
  upgradeValue: 1,
  effect: StatusItemEffect(
    kind: ItemStatusEffectKind.calentando,
    trigger: ItemStatusEffectTrigger.attackOwnerReinforce,
  ),
);

/// Arma azul que castiga el uso de habilidades del rival.
const pulseCarbineItem = Item(
  id: ItemId.pulseCarbine,
  tags: _ataqueDebuffTags,
  name: 'Carabina de Pulsos',
  description: '+2 ATK. Al atacar: aplica Interferencia al enemigo.',
  iconEmoji: '\u{1F52B}',
  slot: ItemSlot.weapon,
  rarity: RarityTier.blue,
  baseCost: 6,
  value: 2,
  upgradeValue: 1,
  statModifiers: {
    BattlerStat.attack: 2,
  },
  upgradeStatModifiers: {
    BattlerStat.attack: 1,
  },
  effect: StatusItemEffect(
    kind: ItemStatusEffectKind.interferencia,
    trigger: ItemStatusEffectTrigger.attackTarget,
  ),
);

/// Armadura azul que transforma dano de estado en margen contra golpes directos.
const phaseVeilItem = Item(
  id: ItemId.phaseVeil,
  tags: _defensaBuffTags,
  name: 'Velo de Fase',
  description: '+2 DEF. Al inicio de tu turno, recuperas Escudo de Fase.',
  iconEmoji: '\u{1F300}',
  slot: ItemSlot.offHand,
  rarity: RarityTier.blue,
  baseCost: 6,
  value: 2,
  upgradeValue: 1,
  statModifiers: {
    BattlerStat.defense: 2,
  },
  upgradeStatModifiers: {
    BattlerStat.defense: 1,
  },
  effect: StatusItemEffect(
    kind: ItemStatusEffectKind.escudoDeFase,
    trigger: ItemStatusEffectTrigger.turnStartOwnerRefreshMinimum,
  ),
);

/// Accesorio azul que garantiza acceso continuo al motor de Inercia.
const inertialCoreItem = Item(
  id: ItemId.inertialCore,
  tags: _ataqueDefensaBuffTags,
  name: 'Nucleo Inercial',
  description: 'Al inicio de tu turno, si no lo tienes, ganas Inercia.',
  iconEmoji: '\u{1F9F2}',
  slot: ItemSlot.accessory,
  rarity: RarityTier.blue,
  baseCost: 6,
  value: 1,
  upgradeValue: 1,
  effect: StatusItemEffect(
    kind: ItemStatusEffectKind.inercia,
    trigger: ItemStatusEffectTrigger.turnStartOwnerIfMissing,
  ),
);

/// Arma morada que convierte cada impacto en reserva de ataque acumulable.
const impulseSpearItem = Item(
  id: ItemId.impulseSpear,
  tags: _ataqueBuffTags,
  name: 'Lanza de Impulso',
  description: '+2 ATK. Al atacar: ganas Reserva de Inercia: ATK.',
  iconEmoji: '\u{1F5E1}',
  slot: ItemSlot.weapon,
  rarity: RarityTier.purple,
  baseCost: 8,
  value: 2,
  upgradeValue: 1,
  statModifiers: {
    BattlerStat.attack: 2,
  },
  upgradeStatModifiers: {
    BattlerStat.attack: 1,
  },
  effect: StatusItemEffect(
    kind: ItemStatusEffectKind.inerciaAtaque,
    trigger: ItemStatusEffectTrigger.attackOwner,
  ),
);

/// Armadura morada que convierte castigo en una reserva defensiva creciente.
const reboundHarnessItem = Item(
  id: ItemId.reboundHarness,
  tags: _defensaBuffTags,
  name: 'Arnes de Rebote',
  description: '+2 DEF. Al recibir dano: ganas Reserva de Inercia: DEF.',
  iconEmoji: '\u{1F9E5}',
  slot: ItemSlot.offHand,
  rarity: RarityTier.purple,
  baseCost: 8,
  value: 2,
  upgradeValue: 1,
  statModifiers: {
    BattlerStat.defense: 2,
  },
  upgradeStatModifiers: {
    BattlerStat.defense: 1,
  },
  effect: StatusItemEffect(
    kind: ItemStatusEffectKind.inerciaDefensa,
    trigger: ItemStatusEffectTrigger.receiveDamageOwner,
  ),
);

/// Accesorio morado que devuelve una conmocion potente al agresor.
const concussionPrismItem = Item(
  id: ItemId.concussionPrism,
  tags: _defensaDebuffTags,
  name: 'Prisma Concusivo',
  description: 'Al recibir dano: aplica Conmocion al agresor.',
  iconEmoji: '\u{1F48E}',
  slot: ItemSlot.accessory,
  rarity: RarityTier.purple,
  baseCost: 8,
  value: 3,
  upgradeValue: 1,
  effect: StatusItemEffect(
    kind: ItemStatusEffectKind.conmocion,
    trigger: ItemStatusEffectTrigger.receiveDamageSource,
  ),
);

/// Blindaje azul de defensa plana alta.
const platedJacketItem = Item(
  id: ItemId.platedJacket,
  tags: _defensaTags,
  name: 'Chaqueta Blindada',
  description: '+4 DEF mientras este equipada.',
  iconEmoji: '\u{1F9E5}',
  slot: ItemSlot.offHand,
  rarity: RarityTier.blue,
  baseCost: 6,
  value: 4,
  upgradeValue: 4,
  statModifiers: {
    BattlerStat.defense: 4,
  },
  upgradeStatModifiers: {
    BattlerStat.defense: 4,
  },
);

/// Arma amarilla que acelera de verdad las cadenas de Calentando.
const overloadInjectorItem = Item(
  id: ItemId.overloadInjector,
  tags: _ataqueBuffTags,
  name: 'Inyector de Sobrecarga',
  description: '+3 ATK. Al atacar: genera o aumenta Calentando.',
  iconEmoji: '\u{1F489}',
  slot: ItemSlot.weapon,
  rarity: RarityTier.yellow,
  baseCost: 10,
  value: 2,
  upgradeValue: 1,
  statModifiers: {
    BattlerStat.attack: 3,
  },
  upgradeStatModifiers: {
    BattlerStat.attack: 1,
  },
  effect: StatusItemEffect(
    kind: ItemStatusEffectKind.calentando,
    trigger: ItemStatusEffectTrigger.attackOwnerReinforce,
  ),
);

/// Armadura amarilla que garantiza una Inercia de alto valor si se pierde.
const vectorBulwarkItem = Item(
  id: ItemId.vectorBulwark,
  tags: _ataqueDefensaBuffTags,
  name: 'Bastion Vectorial',
  description: '+3 DEF. Al inicio de tu turno, si no lo tienes, ganas Inercia.',
  iconEmoji: '\u{1F9FF}',
  slot: ItemSlot.offHand,
  rarity: RarityTier.yellow,
  baseCost: 10,
  value: 2,
  upgradeValue: 1,
  statModifiers: {
    BattlerStat.defense: 3,
  },
  upgradeStatModifiers: {
    BattlerStat.defense: 1,
  },
  effect: StatusItemEffect(
    kind: ItemStatusEffectKind.inercia,
    trigger: ItemStatusEffectTrigger.turnStartOwnerIfMissing,
  ),
);

/// Accesorio amarillo que rellena un Blindaje Temporal grande al arrancar turno.
const contingencySealItem = Item(
  id: ItemId.contingencySeal,
  tags: _defensaBuffTags,
  name: 'Sello de Contingencia',
  description: 'Al inicio de tu turno, recuperas Blindaje Temporal.',
  iconEmoji: '\u2726',
  slot: ItemSlot.accessory,
  rarity: RarityTier.yellow,
  baseCost: 10,
  value: 4,
  upgradeValue: 1,
  effect: StatusItemEffect(
    kind: ItemStatusEffectKind.blindajeTemporal,
    trigger: ItemStatusEffectTrigger.turnStartOwnerRefreshMinimum,
  ),
);

/// Arma amarilla de dano alto para el tramo final.
const sunsteelBladeItem = Item(
  id: ItemId.sunsteelBlade,
  tags: _ataqueTags,
  name: 'Filo Solar',
  description: '+8 ATK mientras este equipado.',
  iconEmoji: '\u{1F5E1}',
  slot: ItemSlot.weapon,
  rarity: RarityTier.yellow,
  baseCost: 10,
  value: 8,
  upgradeValue: 8,
  statModifiers: {
    BattlerStat.attack: 8,
  },
  upgradeStatModifiers: {
    BattlerStat.attack: 8,
  },
);

/// Accesorio amarillo centrado en vida maxima.
const dawnCharmItem = Item(
  id: ItemId.dawnCharm,
  tags: _vidaTags,
  name: 'Amuleto del Alba',
  description: '+16 HP mientras este equipado.',
  iconEmoji: '\u2600',
  slot: ItemSlot.accessory,
  rarity: RarityTier.yellow,
  baseCost: 10,
  value: 16,
  upgradeValue: 16,
  statModifiers: {
    BattlerStat.health: 16,
  },
  upgradeStatModifiers: {
    BattlerStat.health: 16,
  },
);

/// Soporte morado defensivo simple y consistente.
const midnightCloakItem = Item(
  id: ItemId.midnightCloak,
  tags: _defensaTags,
  name: 'Capa de Medianoche',
  description: '+5 DEF mientras este equipada.',
  iconEmoji: '\u{1F576}',
  slot: ItemSlot.offHand,
  rarity: RarityTier.purple,
  baseCost: 8,
  value: 5,
  upgradeValue: 5,
  statModifiers: {
    BattlerStat.defense: 5,
  },
  upgradeStatModifiers: {
    BattlerStat.defense: 5,
  },
);

/// Soporte morado que potencia Quemaduras y las devuelve al portador cada turno.
const portableOvenItem = Item(
  id: ItemId.portableOven,
  tags: _debuffQuemaduraTags,
  name: 'Horno Portatil',
  description: 'Amplifica tus Quemaduras, pero siempre deja rescoldos.',
  iconEmoji: '\u{1F525}',
  slot: ItemSlot.offHand,
  rarity: RarityTier.purple,
  baseCost: 8,
  value: 1,
  upgradeValue: 1,
  effect: PortableOvenItemEffect(),
);

/// Accesorio morado que cura al entrar habilidades en cooldown.
const parasiticCapacitorItem = Item(
  id: ItemId.parasiticCapacitor,
  tags: _vidaTags,
  name: 'Capacitador Parasitario',
  description:
      '+5 HP y drenaje energetico cada vez que una habilidad entra en cooldown.',
  iconEmoji: '\u26A1',
  slot: ItemSlot.accessory,
  rarity: RarityTier.purple,
  baseCost: 8,
  value: 5,
  upgradeValue: 5,
  statModifiers: {
    BattlerStat.health: 5,
  },
  upgradeStatModifiers: {
    BattlerStat.health: 5,
  },
  effect: ParasiticCapacitorItemEffect(),
);

/// Accesorio morado mixto de ataque y vida maxima.
const voidInjectorItem = Item(
  id: ItemId.voidInjector,
  tags: _ataqueVidaTags,
  name: 'Inyector del Vacio',
  description: '+4 ATK y +8 HP mientras este equipado.',
  iconEmoji: '\u{1F489}',
  slot: ItemSlot.accessory,
  rarity: RarityTier.purple,
  baseCost: 8,
  value: 4,
  upgradeValue: 4,
  statModifiers: {
    BattlerStat.attack: 4,
    BattlerStat.health: 8,
  },
  upgradeStatModifiers: {
    BattlerStat.attack: 4,
    BattlerStat.health: 8,
  },
);

/// Soporte amarillo que potencia la primera activacion manual del combate.
const eclipseMantleItem = Item(
  id: ItemId.eclipseMantle,
  tags: _defensaTags,
  name: 'Manto de Eclipse',
  description:
      '+4 DEF y un pulso de potencia en la primera activacion manual del combate.',
  iconEmoji: '\u{1F318}',
  slot: ItemSlot.offHand,
  rarity: RarityTier.yellow,
  baseCost: 10,
  value: 3,
  upgradeValue: 1,
  statModifiers: {
    BattlerStat.defense: 4,
  },
  upgradeStatModifiers: {
    BattlerStat.defense: 1,
  },
  effect: EclipseMantleItemEffect(),
);

/// Accesorio amarillo que evita una muerte por combate y reinicia habilidades.
const operativeBlackBoxItem = Item(
  id: ItemId.operativeBlackBox,
  tags: _vidaTags,
  name: 'Caja Negra del Operativo',
  description:
      'Failsafe de emergencia que rehusa dejar caer la unidad a la primera.',
  iconEmoji: '\u{1F4E6}',
  slot: ItemSlot.accessory,
  rarity: RarityTier.yellow,
  baseCost: 10,
  value: 1,
  upgradeValue: 1,
  effect: OperativeBlackBoxItemEffect(),
);

/// Pool maestro de objetos ofrecidos por tiendas y recompensas.
const itemPresets = <Item>[
  woodenStickItem,
  cyberWhipsItem,
  sunglassesItem,
  shieldItem,
  bulwarkAmuletItem,
  crackedBatteryItem,
  impactGlovesItem,
  toxicCatalystItem,
  emberCharmItem,
  chemicalFilterItem,
  billingModuleItem,
  stunBatonItem,
  emergencyPlatingItem,
  pocketJammerItem,
  serratedEdgeItem,
  containmentCoilItem,
  thermalTurbineItem,
  pulseCarbineItem,
  phaseVeilItem,
  inertialCoreItem,
  impulseSpearItem,
  reboundHarnessItem,
  concussionPrismItem,
  overloadInjectorItem,
  vectorBulwarkItem,
  contingencySealItem,
  ironSwordItem,
  guardShieldItem,
  platedJacketItem,
  reactiveCasingItem,
  portableOvenItem,
  parasiticCapacitorItem,
  sunsteelBladeItem,
  dawnCharmItem,
  eclipseMantleItem,
  operativeBlackBoxItem,
  midnightCloakItem,
  voidInjectorItem,
];

/// Registro canonico por id para resolver presets sin recorrer toda la lista.
final Map<ItemId, Item> itemPresetRegistry = Map<ItemId, Item>.unmodifiable({
  for (final item in itemPresets) item.id: item,
});
