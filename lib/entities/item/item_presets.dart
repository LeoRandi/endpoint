import '../_imports.dart';

const _ataqueTags = <EntityTag>[
  EntityTag.ataque,
];
const _barreraTags = <EntityTag>[
  EntityTag.barrera,
];
const _ataqueBarreraTags = <EntityTag>[
  EntityTag.ataque,
  EntityTag.barrera,
];
const _vidaTags = <EntityTag>[
  EntityTag.vida,
];
const _vidaBarreraTags = <EntityTag>[
  EntityTag.vida,
  EntityTag.barrera,
];
const _economiaVidaTags = <EntityTag>[
  EntityTag.economia,
  EntityTag.vida,
];
const _economiaBarreraTags = <EntityTag>[
  EntityTag.economia,
  EntityTag.barrera,
];
const _economiaAtaqueTags = <EntityTag>[
  EntityTag.economia,
  EntityTag.ataque,
];
const _economiaTags = <EntityTag>[
  EntityTag.economia,
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
const _ataqueBuffVidaTags = <EntityTag>[
  EntityTag.ataque,
  EntityTag.buff,
  EntityTag.vida,
];
const _ataqueDebuffTags = <EntityTag>[
  EntityTag.ataque,
  EntityTag.debuff,
];
const _ataqueDebuffQuemaduraTags = <EntityTag>[
  EntityTag.ataque,
  EntityTag.debuff,
  EntityTag.quemadura,
];
const _barreraDebuffTags = <EntityTag>[
  EntityTag.barrera,
  EntityTag.debuff,
];
const _ataqueBarreraDebuffTags = <EntityTag>[
  EntityTag.ataque,
  EntityTag.barrera,
  EntityTag.debuff,
];
const _barreraBuffTags = <EntityTag>[
  EntityTag.barrera,
  EntityTag.buff,
];
const _ataqueBarreraBuffTags = <EntityTag>[
  EntityTag.ataque,
  EntityTag.barrera,
  EntityTag.buff,
];
const _economiaBarreraDebuffTags = <EntityTag>[
  EntityTag.economia,
  EntityTag.barrera,
  EntityTag.debuff,
];
const _generalAffinities = <ItemArchetypeAffinity>[
  ItemArchetypeAffinity.general,
];
const _velozAffinities = <ItemArchetypeAffinity>[
  ItemArchetypeAffinity.veloz,
];
const _inamovibleAffinities = <ItemArchetypeAffinity>[
  ItemArchetypeAffinity.inamovible,
];
const _imparableAffinities = <ItemArchetypeAffinity>[
  ItemArchetypeAffinity.imparable,
];
const _mercanteAffinities = <ItemArchetypeAffinity>[
  ItemArchetypeAffinity.mercante,
];
const _velozImparableAffinities = <ItemArchetypeAffinity>[
  ItemArchetypeAffinity.veloz,
  ItemArchetypeAffinity.imparable,
];
const _velozInamovibleAffinities = <ItemArchetypeAffinity>[
  ItemArchetypeAffinity.veloz,
  ItemArchetypeAffinity.inamovible,
];
const _inamovibleImparableAffinities = <ItemArchetypeAffinity>[
  ItemArchetypeAffinity.inamovible,
  ItemArchetypeAffinity.imparable,
];
const _inamovibleMercanteAffinities = <ItemArchetypeAffinity>[
  ItemArchetypeAffinity.inamovible,
  ItemArchetypeAffinity.mercante,
];
const _velozInamovibleMercanteAffinities = <ItemArchetypeAffinity>[
  ItemArchetypeAffinity.veloz,
  ItemArchetypeAffinity.inamovible,
  ItemArchetypeAffinity.mercante,
];

/// Arma gris sencilla para encuentros y tiendas de bajo nivel.
const woodenStickItem = Item(
  id: ItemId.woodenStick,
  archetypeAffinities: _generalAffinities,
  tags: _ataqueTags,
  name: 'Palo',
  description: '+1 ATK mientras este equipado.',
  iconEmoji: '\u{1FAB5}',
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
  archetypeAffinities: _velozAffinities,
  tags: _ataqueDebuffIntoxicacionTags,
  name: 'Cyber Latigos',
  description:
      '+1 ATK. Al atacar: aplica o aumenta Intoxicacion en el enemigo.',
  iconEmoji: '\u{26D3}',
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
  archetypeAffinities: _velozAffinities,
  tags: _ataqueBarreraTags,
  name: 'Gafas de Sol',
  description:
      '+1 Barrera. Mitad de ATK, pero cada ataque basico golpea dos veces.',
  iconEmoji: '\u{1F453}',
  rarity: RarityTier.gray,
  baseCost: 2,
  value: 1,
  upgradeValue: 1,
  statModifiers: {
    BattlerStat.barrier: 1,
  },
  upgradeStatModifiers: {
    BattlerStat.barrier: 1,
  },
  effect: SunglassesItemEffect(),
);

/// Soporte defensivo verde para builds de aguante.
const shieldItem = Item(
  id: ItemId.shield,
  archetypeAffinities: _inamovibleMercanteAffinities,
  tags: _vidaBarreraTags,
  name: 'Escudo',
  description: '+2 Barrera. Al inicio de tu turno, recuperas 5 HP.',
  iconEmoji: '\u{1F6E1}',
  rarity: RarityTier.green,
  baseCost: 4,
  value: 5,
  upgradeValue: 5,
  statModifiers: {
    BattlerStat.barrier: 2,
  },
  upgradeStatModifiers: {
    BattlerStat.barrier: 2,
  },
  effect: RegenerativeShieldItemEffect(),
);

/// Accesorio verde que sube vida maxima y barrera a la vez.
const bulwarkAmuletItem = Item(
  id: ItemId.bulwarkAmulet,
  archetypeAffinities: _inamovibleMercanteAffinities,
  tags: _vidaBarreraTags,
  name: 'Amuleto de Bastion',
  description: '+6 HP y +1 Barrera mientras este equipado.',
  iconEmoji: '\u{1F9FF}',
  rarity: RarityTier.green,
  baseCost: 4,
  value: 6,
  upgradeValue: 6,
  statModifiers: {
    BattlerStat.health: 6,
    BattlerStat.barrier: 1,
  },
  upgradeStatModifiers: {
    BattlerStat.health: 6,
    BattlerStat.barrier: 1,
  },
);

/// Accesorio gris que acelera la primera habilidad manual de cada combate.
const crackedBatteryItem = Item(
  id: ItemId.crackedBattery,
  archetypeAffinities: _generalAffinities,
  name: 'Bateria Rajada',
  description: 'Accesorio inestable que exprime la primera habilidad manual.',
  iconEmoji: '\u{1F50B}',
  rarity: RarityTier.gray,
  baseCost: 2,
  value: 1,
  upgradeValue: 1,
  effect: CrackedBatteryItemEffect(),
);

/// Arma gris que castiga a objetivos sin buffs activos.
const impactGlovesItem = Item(
  id: ItemId.impactGloves,
  archetypeAffinities: _imparableAffinities,
  tags: _ataqueBuffTags,
  name: 'Guantes de Impacto',
  description: '+1 ATK y castigo extra contra objetivos sin buffs.',
  iconEmoji: '\u{1F9E4}',
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
  archetypeAffinities: _velozAffinities,
  tags: _debuffIntoxicacionTags,
  name: 'Catalizador Toxico',
  description: 'Accesorio quimico que contamina cada impacto.',
  iconEmoji: '\u2623',
  rarity: RarityTier.green,
  baseCost: 4,
  value: 1,
  upgradeValue: 1,
  effect: IntoxicarOnAttackItemEffect(),
);

/// Accesorio verde ofensivo que aplica Quemadura al atacar.
const emberCharmItem = Item(
  id: ItemId.emberCharm,
  archetypeAffinities: _imparableAffinities,
  tags: _debuffQuemaduraTags,
  name: 'Amuleto de Ascuas',
  description: 'Accesorio ofensivo que prende fuego en cada impacto.',
  iconEmoji: '\u{1F525}',
  rarity: RarityTier.green,
  baseCost: 4,
  value: 3,
  upgradeValue: 1,
  effect: QuemaduraOnAttackItemEffect(),
);

/// Accesorio verde defensivo contra Quemadura e Intoxicacion.
const chemicalFilterItem = Item(
  id: ItemId.chemicalFilter,
  archetypeAffinities: _velozInamovibleMercanteAffinities,
  tags: _debuffQuemaduraIntoxicacionTags,
  name: 'Filtro Quimico',
  description: 'Reduce la Quemadura y la Intoxicacion que recibes.',
  iconEmoji: '\u{1F637}',
  rarity: RarityTier.green,
  baseCost: 4,
  value: 1,
  upgradeValue: 1,
  effect: ChemicalFilterItemEffect(),
);

/// Soporte verde que cambia vida maxima por income adicional.
const billingModuleItem = Item(
  id: ItemId.billingModule,
  archetypeAffinities: _mercanteAffinities,
  tags: _economiaVidaTags,
  name: 'Modulo de Cobro',
  description: 'Convierte soporte vital en ingresos operativos.',
  iconEmoji: '\u{1F4B3}',
  rarity: RarityTier.green,
  baseCost: 4,
  value: 2,
  upgradeValue: 1,
  incomePerValueUnit: 1,
  maxHealthPercentPerValueUnit: -5,
  effect: BillingModuleItemEffect(),
);

/// Soporte gris economico que convierte caja liquida en una pequena reserva defensiva.
const mochilaStronkboxItem = Item(
  id: ItemId.mochilaStronkbox,
  archetypeAffinities: _mercanteAffinities,
  tags: _economiaBarreraTags,
  name: 'Mochila Stronkbox',
  description:
      '+1 Barrera. Al inicio de tu turno, si tienes al menos 10C, recuperas 1 de Barrera.',
  iconEmoji: '\u{1F392}',
  rarity: RarityTier.gray,
  baseCost: 2,
  value: 1,
  upgradeValue: 1,
  statModifiers: {
    BattlerStat.barrier: 1,
  },
  upgradeStatModifiers: {
    BattlerStat.barrier: 1,
  },
  effect: MochilaStronkboxItemEffect(),
);

/// Accesorio azul que cura al portar mercancia ajena sin equipar.
const muestrarioContrabandoItem = Item(
  id: ItemId.muestrarioContrabando,
  archetypeAffinities: _mercanteAffinities,
  tags: _economiaVidaTags,
  name: 'Muestrario de Contrabando',
  description:
      '+3 HP. Al atacar, te curas por cada item de otro arquetipo en tu inventario.',
  iconEmoji: '\u{1F9F3}',
  rarity: RarityTier.blue,
  baseCost: 6,
  value: 1,
  upgradeValue: 1,
  statModifiers: {
    BattlerStat.health: 3,
  },
  effect: MuestrarioContrabandoItemEffect(),
);

/// Arma morada que convierte el catalogo ajeno acumulado en ataque estable.
const roperaUnidaItem = Item(
  id: ItemId.roperaUnida,
  archetypeAffinities: _mercanteAffinities,
  tags: _economiaAtaqueTags,
  name: 'Ropera Unida',
  description:
      'Otorga un bonus de ATK igual a su value mas tus items de otro arquetipo.',
  iconEmoji: '\u{1F455}',
  rarity: RarityTier.purple,
  baseCost: 8,
  value: 2,
  upgradeValue: 3,
  effect: RoperaUnidaItemEffect(),
);

/// Soporte gris que va drenando turnos de debuff de forma dispersa.
const mamparaPortatilItem = Item(
  id: ItemId.mamparaPortatil,
  archetypeAffinities: _inamovibleAffinities,
  tags: _barreraDebuffTags,
  name: 'Mampara Portatil',
  description:
      '+2 Barrera. Al inicio de tu turno, reduce 1 turno de un debuff aleatorio tantas veces como su value.',
  iconEmoji: '\u{1F6AA}',
  rarity: RarityTier.gray,
  baseCost: 2,
  value: 1,
  upgradeValue: 1,
  statModifiers: {
    BattlerStat.barrier: 2,
  },
  effect: MamparaPortatilItemEffect(),
);

/// Arma azul que convierte tu defensa en un boost explosivo para el siguiente golpe.
const magnetiCHammerItem = Item(
  id: ItemId.magnetiCHammer,
  archetypeAffinities: _inamovibleAffinities,
  tags: _ataqueBarreraTags,
  name: 'M(agneti)C Hammer',
  description:
      '+1 ATK. Al defender, ganas Potencia para el siguiente golpe igual a tu Barrera total actual.',
  iconEmoji: '\u{1F528}',
  rarity: RarityTier.blue,
  baseCost: 6,
  value: 2,
  upgradeValue: 1,
  statModifiers: {
    BattlerStat.attack: 1,
  },
  upgradeStatModifiers: {
    BattlerStat.attack: 1,
  },
  effect: MagnetiCHammerItemEffect(),
);

/// Accesorio amarillo que purga con fuerza cualquier debuff purgable.
const ceramicaPurgadoraItem = Item(
  id: ItemId.ceramicaPurgadora,
  archetypeAffinities: _inamovibleAffinities,
  tags: _barreraDebuffTags,
  name: 'Ceramica Purgadora',
  description:
      '+3 Barrera. Al inicio de tu turno, reduces turnos de todos tus debuffs purgables.',
  iconEmoji: '\u{1F3FA}',
  rarity: RarityTier.yellow,
  baseCost: 10,
  value: 2,
  upgradeValue: 1,
  statModifiers: {
    BattlerStat.barrier: 3,
  },
  effect: CeramicaPurgadoraItemEffect(),
);

/// Accesorio gris sin impacto directo que solo se revaloriza al sobrevivir equipado.
const pagareRevalorizableItem = Item(
  id: ItemId.pagareRevalorizable,
  archetypeAffinities: _generalAffinities,
  tags: _economiaTags,
  name: 'Pagare Revalorizable',
  description: 'No hace nada mientras este equipado.',
  iconEmoji: '\u{1F4DC}',
  rarity: RarityTier.gray,
  baseCost: 2,
  value: 1,
  upgradeValue: 1,
  effect: PagareRevalorizableItemEffect(),
);

/// Arma verde equilibrada que aporta un poco de ataque y barrera a la vez.
const placaBisagraItem = Item(
  id: ItemId.placaBisagra,
  archetypeAffinities: _generalAffinities,
  tags: _ataqueBarreraTags,
  name: 'Placa Bisagra',
  description: '+1 ATK y +1 Barrera mientras este equipada.',
  iconEmoji: '\u{2699}',
  rarity: RarityTier.green,
  baseCost: 4,
  statModifiers: {
    BattlerStat.attack: 1,
    BattlerStat.barrier: 1,
  },
  upgradeStatModifiers: {
    BattlerStat.attack: 1,
    BattlerStat.barrier: 1,
  },
);

/// Accesorio azul de control defensivo que interfiere al agresor.
const silbatoMudoItem = Item(
  id: ItemId.silbatoMudo,
  archetypeAffinities: _generalAffinities,
  tags: _barreraDebuffTags,
  name: 'Silbato Mudo',
  description: '+1 Barrera. Al recibir dano: aplica Interferencia al agresor.',
  iconEmoji: '\u{1F507}',
  rarity: RarityTier.blue,
  baseCost: 6,
  value: 1,
  upgradeValue: 1,
  statModifiers: {
    BattlerStat.barrier: 1,
  },
  effect: StatusItemEffect(
    kind: ItemStatusEffectKind.interferencia,
    trigger: ItemStatusEffectTrigger.receiveDamageSource,
  ),
);

/// Accesorio gris de curacion menor y constante.
const botiquinCompactoItem = Item(
  id: ItemId.botiquinCompacto,
  archetypeAffinities: _generalAffinities,
  tags: _vidaTags,
  name: 'Botiquin Compacto',
  description: 'Al inicio de tu turno, recuperas 1 HP.',
  iconEmoji: '\u{1FA79}',
  rarity: RarityTier.gray,
  baseCost: 2,
  value: 1,
  upgradeValue: 1,
  effect: RegenerativeShieldItemEffect(),
);

/// Accesorio verde defensivo simple que mezcla un poco de vida y barrera.
const fundaAislanteItem = Item(
  id: ItemId.fundaAislante,
  archetypeAffinities: _generalAffinities,
  tags: _vidaBarreraTags,
  name: 'Funda Aislante',
  description: '+2 HP y +1 Barrera mientras este equipada.',
  iconEmoji: '\u{1F9E4}',
  rarity: RarityTier.green,
  baseCost: 4,
  statModifiers: {
    BattlerStat.health: 2,
    BattlerStat.barrier: 1,
  },
  upgradeStatModifiers: {
    BattlerStat.health: 2,
    BattlerStat.barrier: 1,
  },
);

/// Arma verde suicida que sobrecarga el primer golpe del turno a cambio de autodebuff.
const clavoReactorItem = Item(
  id: ItemId.clavoReactor,
  archetypeAffinities: _imparableAffinities,
  tags: _ataqueDebuffQuemaduraTags,
  name: 'Clavo Reactor',
  description:
      '+2 ATK. La primera vez por turno que atacas, infliges dano directo extra y te aplicas Quemadura.',
  iconEmoji: '\u{1F529}',
  rarity: RarityTier.green,
  baseCost: 4,
  value: 2,
  upgradeValue: 1,
  statModifiers: {
    BattlerStat.attack: 2,
  },
  effect: ClavoReactorItemEffect(),
);

/// Accesorio azul que sacrifica vida real para cargar una reserva enorme de ataque.
const bombaMiocardicaItem = Item(
  id: ItemId.bombaMiocardica,
  archetypeAffinities: _imparableAffinities,
  tags: _ataqueBuffVidaTags,
  name: 'Bomba Miocardica',
  description:
      'Al inicio de tu turno, pierdes vida y ganas una gran Reserva de Inercia: ATK.',
  iconEmoji: '\u2764',
  rarity: RarityTier.blue,
  baseCost: 6,
  value: 2,
  upgradeValue: 1,
  effect: BombaMiocardicaItemEffect(),
);

/// Accesorio morado que convierte la vida faltante en dano explosivo para el primer ataque del turno.
const ultimaMarchaItem = Item(
  id: ItemId.ultimaMarcha,
  archetypeAffinities: _imparableAffinities,
  tags: _ataqueVidaTags,
  name: 'Ultima Marcha',
  description:
      '+1 ATK. La primera vez por turno que atacas, infliges dano extra segun la vida que te falta.',
  iconEmoji: '\u{1FA78}',
  rarity: RarityTier.purple,
  baseCost: 8,
  value: 2,
  upgradeValue: 1,
  statModifiers: {
    BattlerStat.attack: 1,
  },
  effect: UltimaMarchaItemEffect(),
);

/// Arma verde de ataque alto para la progresion temprana.
const ironSwordItem = Item(
  id: ItemId.ironSword,
  archetypeAffinities: _generalAffinities,
  tags: _ataqueTags,
  name: 'Espada de Hierro',
  description: '+3 ATK mientras este equipada.',
  iconEmoji: '\u2694',
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
  archetypeAffinities: _generalAffinities,
  tags: _barreraTags,
  name: 'Escudo de Guardia',
  description: '+2 Barrera mientras este equipado.',
  iconEmoji: '\u{1F6E1}',
  rarity: RarityTier.green,
  baseCost: 4,
  value: 2,
  upgradeValue: 2,
  statModifiers: {
    BattlerStat.barrier: 2,
  },
  upgradeStatModifiers: {
    BattlerStat.barrier: 2,
  },
);

/// Soporte azul reactivo que devuelve Quemadura al recibir golpes.
const reactiveCasingItem = Item(
  id: ItemId.reactiveCasing,
  archetypeAffinities: _imparableAffinities,
  tags: _debuffQuemaduraTags,
  name: 'Coraza Reactiva',
  description: 'Blindaje inestable que devuelve fuego al agresor.',
  iconEmoji: '\u{1F9F1}',
  rarity: RarityTier.blue,
  baseCost: 6,
  value: 4,
  upgradeValue: 1,
  effect: QuemaduraOnHitReceivedItemEffect(),
);

/// Arma gris de control ligero que debilita el siguiente golpe enemigo.
const stunBatonItem = Item(
  id: ItemId.stunBaton,
  archetypeAffinities: _velozAffinities,
  tags: _ataqueDebuffTags,
  name: 'Porra de Aturdimiento',
  description: '+1 ATK. Al atacar: aplica Conmocion al enemigo.',
  iconEmoji: '\u{1F50C}',
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

/// Armadura gris basica que asegura un minimo de barrera al iniciar turno.
const emergencyPlatingItem = Item(
  id: ItemId.emergencyPlating,
  archetypeAffinities: _inamovibleMercanteAffinities,
  tags: _barreraBuffTags,
  name: 'Placa de Emergencia',
  description:
      '+1 Barrera. Al inicio de tu turno, si tienes menos de 2 de Barrera, la subes hasta 2.',
  iconEmoji: '\u{1F6E1}',
  rarity: RarityTier.gray,
  baseCost: 2,
  value: 2,
  upgradeValue: 1,
  statModifiers: {
    BattlerStat.barrier: 1,
  },
  upgradeStatModifiers: {
    BattlerStat.barrier: 1,
  },
  effect: RefreshMinimumBarrierOnTurnStartItemEffect(),
);

/// Accesorio gris reactivo que silencia al agresor.
const pocketJammerItem = Item(
  id: ItemId.pocketJammer,
  archetypeAffinities: _velozAffinities,
  tags: _barreraDebuffTags,
  name: 'Interferidor de Bolsillo',
  description: 'Al recibir dano: aplica Interferencia al agresor.',
  iconEmoji: '\u{1F4F6}',
  rarity: RarityTier.gray,
  baseCost: 2,
  value: 1,
  upgradeValue: 1,
  effect: StatusItemEffect(
    kind: ItemStatusEffectKind.interferencia,
    trigger: ItemStatusEffectTrigger.receiveDamageSource,
  ),
);

/// Arma azul oportunista que protege al portador al defender contra rivales ya tocados.
const kunaiAnchoItem = Item(
  id: ItemId.kunaiAncho,
  archetypeAffinities: _velozAffinities,
  tags: _ataqueBarreraDebuffTags,
  name: 'Kunai Ancho',
  description:
      '+1 ATK. Al defender, si el enemigo tiene un debuff, recuperas Barrera.',
  iconEmoji: '\u{1F52A}',
  rarity: RarityTier.blue,
  baseCost: 6,
  value: 2,
  upgradeValue: 1,
  statModifiers: {
    BattlerStat.attack: 1,
  },
  effect: KunaiAnchoItemEffect(),
);

/// Arma verde orientada a abrir ventanas de dano de forma estable.
const serratedEdgeItem = Item(
  id: ItemId.serratedEdge,
  archetypeAffinities: _velozImparableAffinities,
  tags: _ataqueDebuffTags,
  name: 'Sierra Dentada',
  description: '+1 ATK. Al atacar: aplica Fragilidad al enemigo.',
  iconEmoji: '\u2692',
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

/// Armadura verde que recompone una pequena porcion de barrera al defender.
const containmentCoilItem = Item(
  id: ItemId.containmentCoil,
  archetypeAffinities: _inamovibleMercanteAffinities,
  tags: _barreraBuffTags,
  name: 'Bobina de Contencion',
  description: '+1 Barrera. Al defender, recuperas 1 de Barrera.',
  iconEmoji: '\u26A1',
  rarity: RarityTier.green,
  baseCost: 4,
  value: 1,
  upgradeValue: 1,
  statModifiers: {
    BattlerStat.barrier: 1,
  },
  upgradeStatModifiers: {
    BattlerStat.barrier: 1,
  },
  effect: ContainmentCoilItemEffect(),
);

/// Accesorio verde que acelera el escalado ofensivo golpe a golpe.
const thermalTurbineItem = Item(
  id: ItemId.thermalTurbine,
  archetypeAffinities: _imparableAffinities,
  tags: _ataqueBuffTags,
  name: 'Turbina Termica',
  description: 'Al atacar: genera o aumenta Calentando.',
  iconEmoji: '\u{1F525}',
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
  archetypeAffinities: _velozImparableAffinities,
  tags: _ataqueDebuffTags,
  name: 'Carabina de Pulsos',
  description: '+2 ATK. Al atacar: aplica Interferencia al enemigo.',
  iconEmoji: '\u{1F52B}',
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

/// Armadura azul que recompone una buena porcion de barrera cada turno.
const phaseVeilItem = Item(
  id: ItemId.phaseVeil,
  archetypeAffinities: _inamovibleMercanteAffinities,
  tags: _barreraBuffTags,
  name: 'Velo de Fase',
  description: '+2 Barrera. Al inicio de tu turno, recuperas 2 de Barrera.',
  iconEmoji: '\u{1F300}',
  rarity: RarityTier.blue,
  baseCost: 6,
  value: 2,
  upgradeValue: 1,
  statModifiers: {
    BattlerStat.barrier: 2,
  },
  upgradeStatModifiers: {
    BattlerStat.barrier: 1,
  },
  effect: RecoverBarrierOnTurnStartItemEffect(amount: 2),
);

/// Accesorio azul que garantiza acceso continuo al motor de Inercia.
const inertialCoreItem = Item(
  id: ItemId.inertialCore,
  archetypeAffinities: _imparableAffinities,
  tags: _ataqueBarreraBuffTags,
  name: 'Nucleo Inercial',
  description: 'Al inicio de tu turno, si no lo tienes, ganas Inercia.',
  iconEmoji: '\u{1F9F2}',
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
  archetypeAffinities: _imparableAffinities,
  tags: _ataqueBuffTags,
  name: 'Lanza de Impulso',
  description: '+2 ATK. Al atacar: ganas Reserva de Inercia: ATK.',
  iconEmoji: '\u{1F5E1}',
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
  archetypeAffinities: _inamovibleAffinities,
  tags: _barreraBuffTags,
  name: 'Arnes de Rebote',
  description:
      '+2 Barrera. Al recibir dano: ganas Reserva de Inercia: Barrera.',
  iconEmoji: '\u{1F9E5}',
  rarity: RarityTier.purple,
  baseCost: 8,
  value: 2,
  upgradeValue: 1,
  statModifiers: {
    BattlerStat.barrier: 2,
  },
  upgradeStatModifiers: {
    BattlerStat.barrier: 1,
  },
  effect: StatusItemEffect(
    kind: ItemStatusEffectKind.inerciaBarrera,
    trigger: ItemStatusEffectTrigger.receiveDamageOwner,
  ),
);

/// Accesorio morado que devuelve una conmocion potente al agresor.
const concussionPrismItem = Item(
  id: ItemId.concussionPrism,
  archetypeAffinities: _velozInamovibleAffinities,
  tags: _barreraDebuffTags,
  name: 'Prisma Concusivo',
  description: 'Al recibir dano: aplica Conmocion al agresor.',
  iconEmoji: '\u{1F48E}',
  rarity: RarityTier.purple,
  baseCost: 8,
  value: 3,
  upgradeValue: 1,
  effect: StatusItemEffect(
    kind: ItemStatusEffectKind.conmocion,
    trigger: ItemStatusEffectTrigger.receiveDamageSource,
  ),
);

/// Blindaje azul de barrera plana alta.
const platedJacketItem = Item(
  id: ItemId.platedJacket,
  archetypeAffinities: _generalAffinities,
  tags: _barreraTags,
  name: 'Chaqueta Blindada',
  description: '+4 Barrera mientras este equipada.',
  iconEmoji: '\u{1F9E5}',
  rarity: RarityTier.blue,
  baseCost: 6,
  value: 4,
  upgradeValue: 4,
  statModifiers: {
    BattlerStat.barrier: 4,
  },
  upgradeStatModifiers: {
    BattlerStat.barrier: 4,
  },
);

/// Arma amarilla que acelera de verdad las cadenas de Calentando.
const overloadInjectorItem = Item(
  id: ItemId.overloadInjector,
  archetypeAffinities: _imparableAffinities,
  tags: _ataqueBuffTags,
  name: 'Inyector de Sobrecarga',
  description: '+3 ATK. Al atacar: genera o aumenta Calentando.',
  iconEmoji: '\u{1F489}',
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
  archetypeAffinities: _inamovibleImparableAffinities,
  tags: _ataqueBarreraBuffTags,
  name: 'Bastion Vectorial',
  description:
      '+3 Barrera. Al inicio de tu turno, si no lo tienes, ganas Inercia.',
  iconEmoji: '\u{1F9FF}',
  rarity: RarityTier.yellow,
  baseCost: 10,
  value: 2,
  upgradeValue: 1,
  statModifiers: {
    BattlerStat.barrier: 3,
  },
  upgradeStatModifiers: {
    BattlerStat.barrier: 1,
  },
  effect: StatusItemEffect(
    kind: ItemStatusEffectKind.inercia,
    trigger: ItemStatusEffectTrigger.turnStartOwnerIfMissing,
  ),
);

/// Accesorio amarillo que asegura un suelo de barrera alto al arrancar turno.
const contingencySealItem = Item(
  id: ItemId.contingencySeal,
  archetypeAffinities: _inamovibleMercanteAffinities,
  tags: _barreraBuffTags,
  name: 'Sello de Contingencia',
  description:
      'Al inicio de tu turno, si tienes menos de 4 de Barrera, la subes hasta 4.',
  iconEmoji: '\u2726',
  rarity: RarityTier.yellow,
  baseCost: 10,
  value: 4,
  upgradeValue: 1,
  effect: RefreshMinimumBarrierOnTurnStartItemEffect(),
);

/// Arma amarilla de dano alto para el tramo final.
const sunsteelBladeItem = Item(
  id: ItemId.sunsteelBlade,
  archetypeAffinities: _generalAffinities,
  tags: _ataqueTags,
  name: 'Filo Solar',
  description: '+8 ATK mientras este equipado.',
  iconEmoji: '\u{1F5E1}',
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
  archetypeAffinities: _generalAffinities,
  tags: _vidaTags,
  name: 'Amuleto del Alba',
  description: '+16 HP mientras este equipado.',
  iconEmoji: '\u2600',
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
  archetypeAffinities: _generalAffinities,
  tags: _barreraTags,
  name: 'Capa de Medianoche',
  description: '+5 Barrera mientras este equipada.',
  iconEmoji: '\u{1F576}',
  rarity: RarityTier.purple,
  baseCost: 8,
  value: 5,
  upgradeValue: 5,
  statModifiers: {
    BattlerStat.barrier: 5,
  },
  upgradeStatModifiers: {
    BattlerStat.barrier: 5,
  },
);

/// Soporte morado que potencia Quemaduras y las devuelve al portador cada turno.
const portableOvenItem = Item(
  id: ItemId.portableOven,
  archetypeAffinities: _imparableAffinities,
  tags: _debuffQuemaduraTags,
  name: 'Horno Portatil',
  description: 'Amplifica tus Quemaduras, pero siempre deja rescoldos.',
  iconEmoji: '\u{1F525}',
  rarity: RarityTier.purple,
  baseCost: 8,
  value: 1,
  upgradeValue: 1,
  effect: PortableOvenItemEffect(),
);

/// Accesorio morado que cura al entrar habilidades en cooldown.
const parasiticCapacitorItem = Item(
  id: ItemId.parasiticCapacitor,
  archetypeAffinities: _inamovibleMercanteAffinities,
  tags: _vidaTags,
  name: 'Capacitador Parasitario',
  description:
      '+5 HP y drenaje energetico cada vez que una habilidad entra en cooldown.',
  iconEmoji: '\u26A1',
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

/// Accesorio morado oportunista que roba liquidez y la convierte en aguante.
const succionaCreditosItem = Item(
  id: ItemId.succionaCreditos,
  archetypeAffinities: _velozAffinities,
  tags: _economiaBarreraDebuffTags,
  name: 'SuccionaCreditos',
  description:
      '+1 Barrera. La primera vez por turno que atacas a un objetivo con un debuff, ganas creditos y recuperas Barrera.',
  iconEmoji: '\u{1F4B8}',
  rarity: RarityTier.purple,
  baseCost: 8,
  value: 3,
  upgradeValue: 1,
  statModifiers: {
    BattlerStat.barrier: 1,
  },
  effect: SuccionaCreditosItemEffect(),
  bonusShapeOverride: ItemBonusShape.circle,
);

/// Accesorio morado mixto de ataque y vida maxima.
const voidInjectorItem = Item(
  id: ItemId.voidInjector,
  archetypeAffinities: _generalAffinities,
  tags: _ataqueVidaTags,
  name: 'Inyector del Vacio',
  description: '+4 ATK y +8 HP mientras este equipado.',
  iconEmoji: '\u{1F489}',
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
  archetypeAffinities: _inamovibleMercanteAffinities,
  tags: _barreraTags,
  name: 'Manto de Eclipse',
  description:
      '+4 Barrera y un pulso de potencia en la primera activacion manual del combate.',
  iconEmoji: '\u{1F318}',
  rarity: RarityTier.yellow,
  baseCost: 10,
  value: 3,
  upgradeValue: 1,
  statModifiers: {
    BattlerStat.barrier: 4,
  },
  upgradeStatModifiers: {
    BattlerStat.barrier: 1,
  },
  effect: EclipseMantleItemEffect(),
);

/// Accesorio amarillo que evita una muerte por combate y reinicia habilidades.
const operativeBlackBoxItem = Item(
  id: ItemId.operativeBlackBox,
  archetypeAffinities: _generalAffinities,
  tags: _vidaTags,
  name: 'Caja Negra del Operativo',
  description:
      'Failsafe de emergencia que rehusa dejar caer la unidad a la primera.',
  iconEmoji: '\u{1F4E6}',
  rarity: RarityTier.yellow,
  baseCost: 10,
  value: 1,
  upgradeValue: 1,
  effect: OperativeBlackBoxItemEffect(),
);

/// Arma gris oportunista que ayuda a sostenerse durante remates.
const rescueBladeItem = Item(
  id: ItemId.rescueBlade,
  archetypeAffinities: _generalAffinities,
  tags: _ataqueVidaTags,
  name: 'Cuchilla de Rescate',
  description:
      '+1 ATK. Si el objetivo queda al 50% de HP o menos, recuperas 1 HP.',
  iconEmoji: '\u{1F5E1}',
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
  effect: RescueBladeItemEffect(),
);

/// Armadura gris que devuelve una pequena penalizacion ofensiva si resiste el golpe.
const shockMeshItem = Item(
  id: ItemId.shockMesh,
  archetypeAffinities: _inamovibleMercanteAffinities,
  tags: _barreraDebuffTags,
  name: 'Malla de Choque',
  description:
      '+1 Barrera. Al recibir dano mientras conservas Barrera, aplicas Conmocion al agresor.',
  iconEmoji: '\u26A1',
  rarity: RarityTier.gray,
  baseCost: 2,
  value: 1,
  upgradeValue: 1,
  statModifiers: {
    BattlerStat.barrier: 1,
  },
  upgradeStatModifiers: {
    BattlerStat.barrier: 1,
  },
  effect: ShockMeshItemEffect(),
);

/// Arma verde de veneno progresivo con remate directo sobre objetivos ya expuestos.
const toxicScalpelItem = Item(
  id: ItemId.toxicScalpel,
  archetypeAffinities: _velozAffinities,
  tags: _ataqueDebuffIntoxicacionTags,
  name: 'Bisturi Toxico',
  description:
      '+1 ATK. Al atacar: aplica o aumenta Intoxicacion. Si ya la tenia, infliges 1 dano directo extra.',
  iconEmoji: '\u2694',
  rarity: RarityTier.green,
  baseCost: 4,
  value: 1,
  upgradeValue: 1,
  statModifiers: {
    BattlerStat.attack: 1,
  },
  upgradeStatModifiers: {
    BattlerStat.attack: 1,
  },
  effect: ToxicScalpelItemEffect(),
);

/// Accesorio verde de seguridad que convierte turnos sin barrera en recarga minima.
const deflectiveCapacitorItem = Item(
  id: ItemId.deflectiveCapacitor,
  archetypeAffinities: _velozInamovibleMercanteAffinities,
  tags: _barreraBuffTags,
  name: 'Condensador Deflectivo',
  description:
      '+1 Barrera. Al inicio de tu turno, si estas a 0 de Barrera, subes tu Barrera hasta 2.',
  iconEmoji: '\u{1F50B}',
  rarity: RarityTier.green,
  baseCost: 4,
  value: 2,
  upgradeValue: 1,
  statModifiers: {
    BattlerStat.barrier: 1,
  },
  upgradeStatModifiers: {
    BattlerStat.barrier: 1,
  },
  effect: DeflectiveCapacitorItemEffect(),
  bonusShapeOverride: ItemBonusShape.circle,
);

/// Arma azul de control que castiga las barreras de objetivos ya interferidos.
const interferenceCannonItem = Item(
  id: ItemId.interferenceCannon,
  archetypeAffinities: _velozAffinities,
  tags: _ataqueDebuffTags,
  name: 'Canon de Interferencia',
  description:
      '+2 ATK. Al atacar: aplica Interferencia. Si el objetivo ya la tenia, pierde 1 de Barrera.',
  iconEmoji: '\u{1F4E1}',
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
  effect: InterferenceCannonItemEffect(),
);

/// Armadura azul de respuesta que recompone barrera solo si no la castigan.
const responseFrameItem = Item(
  id: ItemId.responseFrame,
  archetypeAffinities: _inamovibleMercanteAffinities,
  tags: _barreraBuffTags,
  name: 'Bastidor de Respuesta',
  description:
      '+2 Barrera. Al final de tu turno, si no has recibido dano, recuperas 2 de Barrera.',
  iconEmoji: '\u{1F6E1}',
  rarity: RarityTier.blue,
  baseCost: 6,
  value: 2,
  upgradeValue: 1,
  statModifiers: {
    BattlerStat.barrier: 2,
  },
  upgradeStatModifiers: {
    BattlerStat.barrier: 1,
  },
  effect: ResponseFrameItemEffect(),
);

/// Armadura azul hibrida de economia ligera y recuperacion defensiva condicionada.
const capaDelContrabandistaItem = Item(
  id: ItemId.capaDelContrabandista,
  archetypeAffinities: _velozAffinities,
  tags: _economiaBarreraDebuffTags,
  name: 'Capa del Contrabandista',
  description:
      '+3 Barrera y +1 INCOME mientras este equipada. Al inicio de tu turno, si el enemigo tiene un debuff, recuperas Barrera segun tu INCOME actual.',
  iconEmoji: '\u{1F977}',
  rarity: RarityTier.blue,
  baseCost: 6,
  value: 1,
  upgradeValue: 1,
  incomePerValueUnit: 1,
  statModifiers: {
    BattlerStat.barrier: 3,
  },
  effect: CapaDelContrabandistaItemEffect(),
);

/// Accesorio morado que traduce el sobrecalentamiento en defensa inmediata.
const overloadAnchorItem = Item(
  id: ItemId.overloadAnchor,
  archetypeAffinities: _imparableAffinities,
  tags: _ataqueBarreraBuffTags,
  name: 'Ancla de Sobrecarga',
  description:
      '+1 Barrera. Al defender, si tienes Calentando, recuperas Barrera.',
  iconEmoji: '\u2693',
  rarity: RarityTier.purple,
  baseCost: 8,
  value: 2,
  upgradeValue: 1,
  statModifiers: {
    BattlerStat.barrier: 1,
  },
  upgradeStatModifiers: {
    BattlerStat.barrier: 1,
  },
  effect: OverloadAnchorItemEffect(),
  bonusShapeOverride: ItemBonusShape.circle,
);

/// Accesorio morado reactivo que solo devuelve una penalizacion por turno.
const reboundLensItem = Item(
  id: ItemId.reboundLens,
  archetypeAffinities: _velozInamovibleMercanteAffinities,
  tags: _barreraDebuffTags,
  name: 'Lente de Rebote',
  description:
      '+1 Barrera. La primera vez que recibes dano cada turno, aplicas Fragilidad al agresor.',
  iconEmoji: '\u{1F52E}',
  rarity: RarityTier.purple,
  baseCost: 8,
  value: 2,
  upgradeValue: 1,
  statModifiers: {
    BattlerStat.barrier: 1,
  },
  upgradeStatModifiers: {
    BattlerStat.barrier: 1,
  },
  effect: ReboundLensItemEffect(),
  bonusShapeOverride: ItemBonusShape.circle,
);

/// Accesorio amarillo que duplica el rendimiento del motor de Inercia.
const inertiaCrownItem = Item(
  id: ItemId.inertiaCrown,
  archetypeAffinities: _imparableAffinities,
  tags: _ataqueBarreraBuffTags,
  name: 'Corona de Inercia',
  description:
      'Si tienes Inercia al inicio de tu turno, ganas ambas reservas de Inercia.',
  iconEmoji: '\u{1F451}',
  rarity: RarityTier.yellow,
  baseCost: 10,
  value: 2,
  upgradeValue: 1,
  effect: InertiaCrownItemEffect(),
  bonusShapeOverride: ItemBonusShape.circle,
);

/// Arma amarilla de remate que convierte la Quemadura acumulada en dano inmediato.
const sunExecutionBladeItem = Item(
  id: ItemId.sunExecutionBlade,
  archetypeAffinities: _imparableAffinities,
  tags: _ataqueDebuffQuemaduraTags,
  name: 'Hoja de Ejecucion Solar',
  description:
      '+4 ATK. Si el objetivo tiene Quemadura, la consume y anade dano directo extra.',
  iconEmoji: '\u2600',
  rarity: RarityTier.yellow,
  baseCost: 10,
  value: 3,
  upgradeValue: 1,
  statModifiers: {
    BattlerStat.attack: 4,
  },
  upgradeStatModifiers: {
    BattlerStat.attack: 1,
  },
  effect: SunExecutionBladeItemEffect(),
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
  mochilaStronkboxItem,
  muestrarioContrabandoItem,
  roperaUnidaItem,
  mamparaPortatilItem,
  magnetiCHammerItem,
  ceramicaPurgadoraItem,
  pagareRevalorizableItem,
  placaBisagraItem,
  silbatoMudoItem,
  botiquinCompactoItem,
  fundaAislanteItem,
  clavoReactorItem,
  bombaMiocardicaItem,
  ultimaMarchaItem,
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
  succionaCreditosItem,
  sunsteelBladeItem,
  dawnCharmItem,
  eclipseMantleItem,
  operativeBlackBoxItem,
  midnightCloakItem,
  voidInjectorItem,
  rescueBladeItem,
  shockMeshItem,
  kunaiAnchoItem,
  toxicScalpelItem,
  deflectiveCapacitorItem,
  interferenceCannonItem,
  responseFrameItem,
  capaDelContrabandistaItem,
  overloadAnchorItem,
  reboundLensItem,
  inertiaCrownItem,
  sunExecutionBladeItem,
];

/// Registro canonico por id para resolver presets sin recorrer toda la lista.
final Map<ItemId, Item> itemPresetRegistry = Map<ItemId, Item>.unmodifiable({
  for (final item in itemPresets) item.id: item,
});
