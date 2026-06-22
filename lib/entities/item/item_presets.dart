import '../_imports.dart';

const _adjN = OperativePatternAdjacencyDirection.north;
const _adjE = OperativePatternAdjacencyDirection.east;
const _adjS = OperativePatternAdjacencyDirection.south;
const _adjW = OperativePatternAdjacencyDirection.west;
const _adjAttack = OperativePatternBonusKind.attack;
const _adjBarrier = OperativePatternBonusKind.barrier;
const _adjHealth = OperativePatternBonusKind.health;
const _patternFirst = OperativePatternRequirement.first();
const _patternMiddle = OperativePatternRequirement.middle();
const _patternLast = OperativePatternRequirement.last();
const _patternRightAngle = OperativePatternRequirement.rightAngle();
const _patternStraightAngle = OperativePatternRequirement.straightAngle();
const _patternSquare = OperativePatternRequirement.exactShape(
  labelOverride: 'Cuadrado',
  shapeKind: OperativePatternShapeKind.square,
  shapePoints: <OperativePatternPoint>[
    OperativePatternPoint(x: -1, y: 1),
    OperativePatternPoint(x: 1, y: 1),
    OperativePatternPoint(x: 1, y: -1),
    OperativePatternPoint(x: -1, y: -1),
  ],
);
const _patternHourglass = OperativePatternRequirement.exactShape(
  labelOverride: 'Reloj arena',
  shapeKind: OperativePatternShapeKind.hourglass,
  shapePoints: <OperativePatternPoint>[
    OperativePatternPoint(x: -1, y: 1),
    OperativePatternPoint(x: 1, y: 1),
    OperativePatternPoint(x: -1, y: -1),
    OperativePatternPoint(x: 1, y: -1),
  ],
);
const _patternZigzag = OperativePatternRequirement.exactShape(
  labelOverride: 'Zigzag',
  shapeKind: OperativePatternShapeKind.zigzag,
  shapePoints: <OperativePatternPoint>[
    OperativePatternPoint(x: -1, y: 1),
    OperativePatternPoint(x: 0, y: 0),
    OperativePatternPoint(x: 1, y: 1),
    OperativePatternPoint(x: 0, y: 0),
    OperativePatternPoint(x: -1, y: -1),
    OperativePatternPoint(x: 0, y: -1),
    OperativePatternPoint(x: 1, y: -1),
  ],
);

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
const _murallaTags = <EntityTag>[
  EntityTag.muralla,
];
const _economiaMurallaTags = <EntityTag>[
  EntityTag.muralla,
  EntityTag.economia,
];
const _ataqueMurallaTags = <EntityTag>[
  EntityTag.ataque,
  EntityTag.muralla,
];
const _barreraMurallaTags = <EntityTag>[
  EntityTag.barrera,
  EntityTag.muralla,
];
const _ataqueBarreraMurallaTags = <EntityTag>[
  EntityTag.ataque,
  EntityTag.barrera,
  EntityTag.muralla,
];
const _armaAtaqueBarreraMurallaTags = <EntityTag>[
  EntityTag.arma,
  EntityTag.ataque,
  EntityTag.barrera,
  EntityTag.muralla,
];
const _accesorioVidaTags = <EntityTag>[
  EntityTag.accesorio,
  EntityTag.vida,
];
const _ataqueBuffTags = <EntityTag>[
  EntityTag.ataque,
  EntityTag.buff,
];
const _cicloTags = <EntityTag>[
  EntityTag.ciclo,
];
const _cicloAtaqueBarreraTags = <EntityTag>[
  EntityTag.ciclo,
  EntityTag.ataque,
  EntityTag.barrera,
];
const _cicloBuffTags = <EntityTag>[
  EntityTag.ciclo,
  EntityTag.buff,
];
const _cicloAtaqueBarreraBuffTags = <EntityTag>[
  EntityTag.ciclo,
  EntityTag.ataque,
  EntityTag.barrera,
  EntityTag.buff,
];
const _cicloBarreraDebuffTags = <EntityTag>[
  EntityTag.ciclo,
  EntityTag.barrera,
  EntityTag.debuff,
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
const _debuffTags = <EntityTag>[
  EntityTag.debuff,
];
const _debuffContagioTags = <EntityTag>[
  EntityTag.debuff,
  EntityTag.contagio,
];
const _ataqueDebuffContagioTags = <EntityTag>[
  EntityTag.ataque,
  EntityTag.debuff,
  EntityTag.contagio,
];
const _barreraDebuffContagioTags = <EntityTag>[
  EntityTag.barrera,
  EntityTag.debuff,
  EntityTag.contagio,
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
const _desafioAtaqueBuffTags = <EntityTag>[
  EntityTag.desafio,
  EntityTag.ataque,
  EntityTag.buff,
];
const _desafioBuffTags = <EntityTag>[
  EntityTag.desafio,
  EntityTag.buff,
];
const _desafioVidaBuffTags = <EntityTag>[
  EntityTag.desafio,
  EntityTag.vida,
  EntityTag.buff,
];
const _desafioBarreraBuffTags = <EntityTag>[
  EntityTag.desafio,
  EntityTag.barrera,
  EntityTag.buff,
];
const _desafioQuemaduraBuffTags = <EntityTag>[
  EntityTag.desafio,
  EntityTag.quemadura,
  EntityTag.buff,
];
const _economiaBarreraDebuffTags = <EntityTag>[
  EntityTag.economia,
  EntityTag.barrera,
  EntityTag.debuff,
];
const _resonanciaBarreraBuffTags = <EntityTag>[
  EntityTag.resonancia,
  EntityTag.barrera,
  EntityTag.buff,
];
const _resonanciaAtaqueBarreraTags = <EntityTag>[
  EntityTag.resonancia,
  EntityTag.ataque,
  EntityTag.barrera,
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
// Item presets ordered by tier: gray -> green -> blue -> purple -> yellow

/// Arma gris sencilla para encuentros y tiendas de bajo nivel.
const woodenStickItem = Item(
  id: ItemId.woodenStick,
  actionType: ItemActionType.attack,
  actionValue: 4,
  archetypeAffinities: _generalAffinities,
  tags: _ataqueTags,
  name: 'Palo',
  description: '+1 ATK mientras este equipado.',
  iconEmoji: '\u{1FAB5}',
  rarity: RarityTier.gray,
  patternBonusAmountOverride: 0,
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

/// Accesorio amarillo que repite al final las acciones anteriores del Patron.
const sunglassesItem = Item(
  id: ItemId.sunglasses,
  archetypeAffinities: _velozAffinities,
  tags: _ataqueBarreraTags,
  name: 'Gafas de Sol',
  description:
      'Al completar el Patron, repite todas las acciones trazadas antes de este item.',
  iconEmoji: '\u{1F453}',
  rarity: RarityTier.yellow,
  actionType: ItemActionType.none,
  actionValue: 0,
  patternBonusAmountOverride: 0,
  baseCost: 10,
  value: 0,
  upgradeValue: 0,
  effect: SunglassesItemEffect(),
);

/// Accesorio gris que carga potencia al atacar.
const crackedBatteryItem = Item(
  id: ItemId.crackedBattery,
  archetypeAffinities: _generalAffinities,
  name: 'Bateria Rajada',
  description: 'Al inicio del combate, ganas una carga breve de Calentando.',
  iconEmoji: '\u{1F50B}',
  rarity: RarityTier.gray,
  patternBonusAmountOverride: 0,
  baseCost: 2,
  value: 4,
  upgradeValue: 4,
  effect: ThermalTurbineItemEffect(),
);

/// Accesorio gris de Ciclo que cambia entre barrera diurna y ataque nocturno.
const gafasFotocromaticasItem = Item(
  id: ItemId.gafasFotocromaticas,
  archetypeAffinities: _velozAffinities,
  tags: _cicloAtaqueBarreraTags,
  name: 'Gafas Fotocromaticas',
  description: 'Ciclo. De dia: +1 Barrera. De noche: +1 ATK.',
  iconEmoji: '\u{1F317}',
  rarity: RarityTier.gray,
  patternBonusAmountOverride: 0,
  baseCost: 2,
  value: 1,
  upgradeValue: 1,
  effect: GafasFotocromaticasItemEffect(),
);

/// Arma gris que castiga a objetivos sin buffs activos.
const impactGlovesItem = Item(
  id: ItemId.impactGloves,
  actionType: ItemActionType.attack,
  actionValue: 4,
  archetypeAffinities: _imparableAffinities,
  tags: _ataqueBuffTags,
  name: 'Guantes de Impacto',
  description: 'Castigo extra contra objetivos sin buffs.',
  iconEmoji: '\u{1F9E4}',
  rarity: RarityTier.gray,
  patternBonusAmountOverride: 0,
  baseCost: 2,
  value: 2,
  upgradeValue: 2,
  effect: ImpactGlovesItemEffect(),
);

/// Arma gris que abre el primer intercambio con Desafio.
const guanteRetoItem = Item(
  id: ItemId.guanteReto,
  actionType: ItemActionType.attack,
  actionValue: 4,
  archetypeAffinities: _imparableAffinities,
  tags: _desafioAtaqueBuffTags,
  name: 'Guante de Reto',
  description: 'La primera vez por combate que atacas, ganas Desafio.',
  iconEmoji: '\u{1F94A}',
  rarity: RarityTier.gray,
  patternBonusAmountOverride: 0,
  baseCost: 2,
  value: 4,
  upgradeValue: 2,
  effect: GuanteRetoItemEffect(),
);

const clavoDuelistaItem = Item(
  id: ItemId.clavoDuelista,
  actionType: ItemActionType.attack,
  actionValue: 3,
  archetypeAffinities: _imparableAffinities,
  tags: _desafioAtaqueBuffTags,
  name: 'Clavo de Duelista',
  description: 'Al usarse: si tienes mas HP que el enemigo, ganas 1 Desafio.',
  iconEmoji: '\u{1F5E1}',
  rarity: RarityTier.gray,
  patternBonusAmountOverride: 0,
  baseCost: 2,
  value: 1,
  upgradeValue: 1,
  effect: ClavoDuelistaItemEffect(),
);

const vendasApretadasItem = Item(
  id: ItemId.vendasApretadas,
  archetypeAffinities: _imparableAffinities,
  tags: _desafioVidaBuffTags,
  name: 'Vendas Apretadas',
  description:
      'Al recibir daño: si perdiste HP, ganas 2 Desafio. Una vez por turno.',
  iconEmoji: '\u{1FA79}',
  rarity: RarityTier.gray,
  patternBonusAmountOverride: 0,
  baseCost: 2,
  value: 2,
  upgradeValue: 1,
  effect: VendasApretadasItemEffect(),
);

const marcaRetadorItem = Item(
  id: ItemId.marcaRetador,
  archetypeAffinities: _imparableAffinities,
  tags: _desafioVidaBuffTags,
  name: 'Marca del Retador',
  description:
      'Al inicio de tu turno: si estas por debajo del 50% HP, ganas 3 Desafio.',
  iconEmoji: '\u{1F3F7}',
  rarity: RarityTier.gray,
  patternBonusAmountOverride: 0,
  baseCost: 2,
  value: 3,
  upgradeValue: 2,
  effect: MarcaRetadorItemEffect(),
);

const hemomedidorItem = Item(
  id: ItemId.hemomedidor,
  actionType: ItemActionType.heal,
  actionValue: 6,
  archetypeAffinities: _imparableAffinities,
  tags: _desafioVidaBuffTags,
  name: 'Hemomedidor',
  description: 'Al usarse: ganas 1 Desafio por cada 10 HP faltantes, maximo 3.',
  iconEmoji: '\u{1FA78}',
  rarity: RarityTier.green,
  patternBonusKindOverride: _adjBarrier,
  patternBonusAmountOverride: 2,
  patternRequirementOverride: _patternMiddle,
  baseCost: 4,
  value: 1,
  upgradeValue: 1,
  effect: HemomedidorItemEffect(),
);

const carbonParaHeridasItem = Item(
  id: ItemId.carbonParaHeridas,
  archetypeAffinities: _imparableAffinities,
  tags: _desafioQuemaduraBuffTags,
  name: 'Carbón para Heridas',
  description: 'Al recibir daño de Quemadura a tu HP: ganas 3 Desafio.',
  iconEmoji: '\u{1FAE7}',
  rarity: RarityTier.green,
  patternBonusKindOverride: _adjAttack,
  patternBonusAmountOverride: 2,
  patternRequirementOverride: _patternRightAngle,
  baseCost: 4,
  value: 3,
  upgradeValue: 2,
  effect: CarbonParaHeridasItemEffect(),
);

const juegosucio101Item = Item(
  id: ItemId.juegosucio101,
  actionType: ItemActionType.attack,
  actionValue: 6,
  archetypeAffinities: _imparableAffinities,
  tags: _desafioAtaqueBuffTags,
  name: 'Juegosucio 101',
  description:
      'Al usarse: ganas 2 Desafio. Si el enemigo tiene un debuff, ganas doble Desafio.',
  iconEmoji: '\u{1F94A}',
  rarity: RarityTier.green,
  patternBonusKindOverride: _adjAttack,
  patternBonusAmountOverride: 2,
  patternRequirementOverride: _patternFirst,
  baseCost: 4,
  value: 2,
  upgradeValue: 1,
  statModifiers: {
    BattlerStat.attack: 1,
  },
  effect: Juegosucio101ItemEffect(),
);

const contratoDolorosoItem = Item(
  id: ItemId.contratoDoloroso,
  archetypeAffinities: _imparableAffinities,
  tags: _desafioBarreraBuffTags,
  name: 'Contrato Doloroso',
  description:
      'Al final de tu turno: si recibiste daño a tu HP este turno, ganas 2 Desafio y 1 Barrera.',
  iconEmoji: '\u{1F4DC}',
  rarity: RarityTier.blue,
  patternBonusKindOverride: _adjBarrier,
  patternBonusAmountOverride: 3,
  patternRequirementOverride: _patternSquare,
  baseCost: 6,
  value: 2,
  upgradeValue: 2,
  effect: ContratoDolorosoItemEffect(),
);

const yunqueCardiacoItem = Item(
  id: ItemId.yunqueCardiaco,
  actionType: ItemActionType.block,
  actionValue: 9,
  archetypeAffinities: _imparableAffinities,
  tags: _desafioBarreraBuffTags,
  name: 'Yunque Cardiaco',
  description:
      'Al recibir daño a HP: convierte hasta 2 de ese daño en Desafio, evitando ese daño hacia ti. Una vez por turno.',
  iconEmoji: '\u{1F528}',
  rarity: RarityTier.blue,
  patternBonusKindOverride: _adjBarrier,
  patternBonusAmountOverride: 3,
  patternRequirementOverride: _patternRightAngle,
  baseCost: 6,
  value: 2,
  upgradeValue: 3,
  statModifiers: {
    BattlerStat.barrier: 2,
  },
  effect: YunqueCardiacoItemEffect(),
);

const revanchadoraItem = Item(
  id: ItemId.revanchadora,
  archetypeAffinities: _imparableAffinities,
  tags: _desafioQuemaduraBuffTags,
  name: 'Revanchadora',
  description:
      'Cuando una Quemadura propia te hace daño, ganas Desafio igual a la mitad de esa Quemadura y te curas 2.',
  iconEmoji: '\u{1F52A}',
  rarity: RarityTier.blue,
  patternBonusKindOverride: _adjAttack,
  patternBonusAmountOverride: 3,
  patternRequirementOverride: _patternLast,
  baseCost: 6,
  value: 2,
  upgradeValue: 3,
  effect: RevanchadoraItemEffect(),
);

const embudoMejorasItem = Item(
  id: ItemId.embudoMejoras,
  archetypeAffinities: _imparableAffinities,
  tags: _desafioBuffTags,
  name: 'Embudo de Mejoras',
  description:
      'Al final de tu turno: elimina tus buffos y convierte su value en Desafio, en un ratio de 2 a 1.',
  iconEmoji: '\u{1F6E0}',
  rarity: RarityTier.purple,
  patternBonusKindOverride: _adjAttack,
  patternBonusAmountOverride: 4,
  patternRequirementOverride: _patternMiddle,
  baseCost: 8,
  value: 2,
  upgradeValue: -1,
  effect: EmbudoMejorasItemEffect(),
);

const arnesTacticoItem = Item(
  id: ItemId.arnesTactico,
  archetypeAffinities: _imparableAffinities,
  tags: _desafioQuemaduraBuffTags,
  name: 'Arnes Tactico',
  description:
      'Al recibir daño de Quemadura: ganas 1 Potencia. Una vez por turno, al purgar tu Potencia, recibes la mitad en Desafio.',
  iconEmoji: '\u{1F9BA}',
  rarity: RarityTier.purple,
  patternBonusKindOverride: _adjAttack,
  patternBonusAmountOverride: 4,
  patternRequirementOverride: _patternRightAngle,
  baseCost: 8,
  value: 1,
  upgradeValue: 1,
  effect: ArnesTacticoItemEffect(),
);

const mandibultimatumItem = Item(
  id: ItemId.mandibultimatum,
  actionType: ItemActionType.attack,
  actionValue: 13,
  archetypeAffinities: _imparableAffinities,
  tags: _desafioAtaqueBuffTags,
  name: 'Mandibultimatum',
  description:
      'Al usarse: consumes hasta 2 Quemadura propia para recibir ese daño a la HP, y ganar el doble en Desafio ANTES de resolver el ataque.',
  iconEmoji: '\u{1F9B7}',
  rarity: RarityTier.purple,
  patternBonusKindOverride: _adjAttack,
  patternBonusAmountOverride: 4,
  patternRequirementOverride: _patternStraightAngle,
  baseCost: 8,
  value: 2,
  upgradeValue: 3,
  statModifiers: {
    BattlerStat.attack: 2,
  },
  effect: MandibultimatumItemEffect(),
);

const estandarteUltimoSolItem = Item(
  id: ItemId.estandarteUltimoSol,
  archetypeAffinities: _imparableAffinities,
  tags: _desafioQuemaduraBuffTags,
  name: 'Estandarte del Ultimo Sol',
  description:
      'Al inicio de tu turno: ganas 2 Desafio por cada 5 HP faltantes. Si tienes Quemadura, ganas esa misma cantidad de Barrera.',
  iconEmoji: '\u{1F6A9}',
  rarity: RarityTier.yellow,
  patternBonusKindOverride: _adjAttack,
  patternBonusAmountOverride: 5,
  patternRequirementOverride: _patternLast,
  baseCost: 10,
  value: 2,
  upgradeValue: 2,
  effect: EstandarteUltimoSolItemEffect(),
);

const motorMartirioItem = Item(
  id: ItemId.motorMartirio,
  archetypeAffinities: _imparableAffinities,
  tags: _desafioVidaBuffTags,
  name: 'Motor de Martirio',
  description:
      'Al recibir daño a HP, o daño de Quemadura: ganas Desafio igual al daño recibido, max 8 por turno. Al final del turno, si tienes 8+ Desafio, te curas 8 HP.',
  iconEmoji: '\u{2699}',
  rarity: RarityTier.yellow,
  patternBonusKindOverride: _adjBarrier,
  patternBonusAmountOverride: 5,
  patternRequirementOverride: _patternMiddle,
  baseCost: 10,
  value: 8,
  upgradeValue: 2,
  effect: MotorMartirioItemEffect(),
);

/// Soporte gris economico que convierte caja liquida en una pequena reserva defensiva.
const mochilaStronkboxItem = Item(
  id: ItemId.mochilaStronkbox,
  archetypeAffinities: _mercanteAffinities,
  tags: _economiaBarreraTags,
  name: 'Mochila Stronkbox',
  description:
      'Al inicio de tu turno, si tienes al menos 10C, recuperas 1 de Barrera.',
  iconEmoji: '\u{1F392}',
  rarity: RarityTier.gray,
  patternBonusAmountOverride: 0,
  baseCost: 2,
  value: 1,
  upgradeValue: 1,
  effect: MochilaStronkboxItemEffect(),
);

/// Buzon gris de Veloz que trae accesorios y, al mejorar, piezas de Ciclo.
const buzonVirtualAzulItem = Item(
  id: ItemId.buzonVirtualAzul,
  archetypeAffinities: _mercanteAffinities,
  tags: _economiaTags,
  name: 'Buzon Virtual Azul',
  description:
      'Al terminar un combate, ofrece un item aleatorio de su categoria en la pantalla de recompensas.',
  iconEmoji: '\u{1F4EC}',
  rarity: RarityTier.gray,
  patternBonusAmountOverride: 0,
  baseCost: 2,
  value: 1,
  upgradeValue: 1,
  effect: VirtualMailboxItemEffect(),
);

/// Buzon gris de Imparable que trae ataque y, al mejorar, Quemadura.
const buzonVirtualRojoItem = Item(
  id: ItemId.buzonVirtualRojo,
  actionType: ItemActionType.attack,
  actionValue: 5,
  archetypeAffinities: _mercanteAffinities,
  tags: _economiaAtaqueTags,
  name: 'Buzon Virtual Rojo',
  description:
      'Al terminar un combate, ofrece un item aleatorio de su categoria en la pantalla de recompensas.',
  iconEmoji: '\u{1F4EA}',
  rarity: RarityTier.gray,
  patternBonusAmountOverride: 0,
  baseCost: 2,
  value: 1,
  upgradeValue: 1,
  statModifiers: {
    BattlerStat.attack: 2,
  },
  effect: VirtualMailboxItemEffect(),
);

/// Buzon gris de Inamovible que trae Barrera y, al mejorar, Resonancia.
const buzonVirtualVerdeItem = Item(
  id: ItemId.buzonVirtualVerde,
  actionType: ItemActionType.block,
  actionValue: 5,
  archetypeAffinities: _mercanteAffinities,
  tags: _economiaBarreraTags,
  name: 'Buzon Virtual Verde',
  description:
      'Al terminar un combate, ofrece un item aleatorio de su categoria en la pantalla de recompensas.',
  iconEmoji: '\u{1F4ED}',
  rarity: RarityTier.gray,
  patternBonusAmountOverride: 0,
  baseCost: 2,
  value: 1,
  upgradeValue: 1,
  statModifiers: {
    BattlerStat.barrier: 2,
  },
  effect: VirtualMailboxItemEffect(),
);

const taladronItem = Item(
  id: ItemId.taladron,
  actionType: ItemActionType.attack,
  actionValue: 7,
  archetypeAffinities: _imparableAffinities,
  tags: _ataqueMurallaTags,
  name: 'Taladron',
  description: 'Al usarse: destruye todas las Murallas de tu matriz.',
  iconEmoji: '\u{1FA9B}',
  rarity: RarityTier.green,
  patternBonusAmountOverride: 0,
  baseCost: 4,
  value: 2,
  upgradeValue: 2,
  statModifiers: {
    BattlerStat.attack: 2,
  },
  upgradeStatModifiers: {
    BattlerStat.attack: 2,
  },
  effect: TaladronItemEffect(),
);

const cuboDinamitalicoItem = Item(
  id: ItemId.cuboDinamitalico,
  actionType: ItemActionType.block,
  actionValue: 8,
  archetypeAffinities: _imparableAffinities,
  tags: _barreraMurallaTags,
  name: 'Cubo Dinamitalico',
  description:
      'Al comienzo del combate, destruye cualquier Muralla de tu matriz adyacente a su posicion.',
  iconEmoji: '\u{1F9F1}',
  rarity: RarityTier.blue,
  patternBonusKindOverride: _adjBarrier,
  patternBonusAmountOverride: 2,
  patternRequirementOverride: _patternSquare,
  baseCost: 6,
  value: 2,
  upgradeValue: 1,
  effect: CuboDinamitalicoItemEffect(),
);

const medidorRoturaItem = Item(
  id: ItemId.medidorRotura,
  actionType: ItemActionType.attack,
  actionValue: 8,
  archetypeAffinities: _imparableAffinities,
  tags: _ataqueMurallaTags,
  name: 'Medidor de Rotura',
  description: 'Ganas +1 ataque por cada Muralla destruida este combate.',
  iconEmoji: '\u{1F4DF}',
  rarity: RarityTier.blue,
  patternBonusAmountOverride: 0,
  baseCost: 6,
  value: 1,
  upgradeValue: 2,
  statModifiers: {
    BattlerStat.attack: 1,
  },
  upgradeStatModifiers: {
    BattlerStat.attack: 2,
  },
  effect: MedidorRoturaItemEffect(),
);

const murallaAutomaticaItem = Item(
  id: ItemId.murallaAutomatica,
  actionType: ItemActionType.block,
  actionValue: 6,
  archetypeAffinities: _inamovibleAffinities,
  tags: _barreraMurallaTags,
  name: 'Muralla automatica',
  description: 'Al comienzo del combate, crea 1 Murallas en la matriz enemiga.',
  iconEmoji: '\u{1F6E1}',
  rarity: RarityTier.green,
  patternBonusAmountOverride: 0,
  baseCost: 4,
  value: 1,
  upgradeValue: 1,
  statModifiers: {
    BattlerStat.barrier: 1,
  },
  upgradeStatModifiers: {
    BattlerStat.barrier: 1,
  },
  effect: MurallaAutomaticaItemEffect(),
);

const barbedShieldItem = Item(
  id: ItemId.barbedShield,
  actionType: ItemActionType.attack,
  actionValue: 8,
  archetypeAffinities: _inamovibleAffinities,
  tags: _ataqueBarreraMurallaTags,
  name: 'Barbed Shield',
  description:
      'Al usarse: Hace daño al enemigo al final del turno igual a 1 veces el numero de Murallas en tu matriz y en la del enemigo.',
  iconEmoji: '\u{1F6E1}',
  rarity: RarityTier.blue,
  patternBonusAmountOverride: 0,
  baseCost: 6,
  value: 1,
  upgradeValue: 1,
  statModifiers: {
    BattlerStat.attack: 1,
  },
  upgradeStatModifiers: {
    BattlerStat.attack: 1,
  },
  effect: BarbedShieldItemEffect(),
);

const literalPaywallItem = Item(
  id: ItemId.literalPaywall,
  actionType: ItemActionType.block,
  actionValue: 6,
  archetypeAffinities: _mercanteAffinities,
  tags: _economiaMurallaTags,
  name: 'Literal Paywall',
  description:
      'Al usarse: al final del turno, paga 8 creditos si es posible para crear una Muralla para el enemigo.',
  iconEmoji: '\u{1F9F1}',
  rarity: RarityTier.blue,
  patternBonusAmountOverride: 0,
  baseCost: 6,
  value: 8,
  upgradeValue: -3,
  effect: LiteralPaywallItemEffect(),
);

const passCardItem = Item(
  id: ItemId.passCard,
  actionType: ItemActionType.block,
  actionValue: 10,
  archetypeAffinities: _mercanteAffinities,
  tags: _economiaMurallaTags,
  name: 'Pass-card',
  description:
      '+1 BP. Al usarse: paga 5 creditos si es posible para desactivar todas las Murallas de tu matriz hasta el final del combate.',
  iconEmoji: '\u{1F3AB}',
  rarity: RarityTier.purple,
  patternBonusKindOverride: _adjBarrier,
  patternBonusAmountOverride: 4,
  patternRequirementOverride: _patternSquare,
  baseCost: 8,
  value: 5,
  upgradeValue: -4,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(
      _adjN,
      EntityTag.accesorio,
      _adjBarrier,
      2,
    ),
    OperativePatternAdjacencyBonus.match(
      _adjW,
      EntityTag.economia,
      _adjBarrier,
      2,
    ),
  ],
  effect: PassCardItemEffect(),
);

const tonfasEscudoItem = Item(
  id: ItemId.tonfasEscudo,
  archetypeAffinities: _velozAffinities,
  tags: _armaAtaqueBarreraMurallaTags,
  name: 'Tonfas Escudo',
  description:
      'Puedes poner o mover una Muralla mas por turno para bloquear a tu oponente, pero -1 BP maximo.',
  iconEmoji: '\u{1FA83}',
  rarity: RarityTier.blue,
  patternBonusAmountOverride: 0,
  baseCost: 6,
  value: 2,
  upgradeValue: 2,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(
      _adjE,
      EntityTag.barrera,
      _adjAttack,
      2,
    ),
    OperativePatternAdjacencyBonus.match(
      _adjW,
      EntityTag.arma,
      _adjBarrier,
      2,
    ),
  ],
  effect: TonfasEscudoItemEffect(),
);

const constructionSealItem = Item(
  id: ItemId.constructionSeal,
  actionType: ItemActionType.heal,
  actionValue: 12,
  archetypeAffinities: _inamovibleAffinities,
  tags: _accesorioVidaTags,
  name: 'Construction Seal',
  description:
      '+4 BP. Al principio de turno: te curas 2 veces tus BP restantes. Al usarse: destruye una Muralla en tu tablero o en el de tu enemigo.',
  iconEmoji: '\u{1F3D7}',
  rarity: RarityTier.yellow,
  patternBonusKindOverride: _adjAttack,
  patternBonusAmountOverride: 4,
  patternRequirementOverride: _patternHourglass,
  baseCost: 10,
  value: 2,
  upgradeValue: 0,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(
      _adjN,
      EntityTag.muralla,
      _adjHealth,
      5,
    ),
    OperativePatternAdjacencyBonus.match(
      _adjE,
      EntityTag.vida,
      _adjHealth,
      5,
    ),
    OperativePatternAdjacencyBonus.match(
      _adjW,
      EntityTag.barrera,
      _adjHealth,
      5,
    ),
    OperativePatternAdjacencyBonus.match(
      _adjS,
      EntityTag.accesorio,
      _adjHealth,
      5,
    ),
  ],
  effect: ConstructionSealItemEffect(),
);

const shoppingChecklistItem = Item(
  id: ItemId.shoppingChecklist,
  actionType: ItemActionType.block,
  actionValue: 4,
  archetypeAffinities: _mercanteAffinities,
  tags: _economiaBarreraTags,
  name: 'Shopping Checklist',
  description:
      'Al inicio de tu turno, si has gastado creditos este combate, recuperas Barrera.',
  iconEmoji: '\u{1F5D2}',
  rarity: RarityTier.gray,
  patternBonusAmountOverride: 0,
  baseCost: 2,
  value: 2,
  upgradeValue: 1,
  effect: ShoppingChecklistItemEffect(),
);

const laCuentaItem = Item(
  id: ItemId.laCuenta,
  actionType: ItemActionType.attack,
  actionValue: 4,
  archetypeAffinities: _mercanteAffinities,
  tags: _economiaAtaqueTags,
  name: 'La Cuenta',
  description:
      'Las primeras veces que gastas creditos, tu siguiente ataque gana daño.',
  iconEmoji: '\u{1F9FE}',
  rarity: RarityTier.gray,
  patternBonusAmountOverride: 0,
  baseCost: 2,
  value: 2,
  upgradeValue: 1,
  statModifiers: {
    BattlerStat.attack: 1,
  },
  effect: LaCuentaItemEffect(),
);

const coinLauncherItem = Item(
  id: ItemId.coinLauncher,
  archetypeAffinities: _mercanteAffinities,
  tags: _economiaAtaqueTags,
  name: 'Coin Launcher',
  description: 'Al usarse: paga creditos para dar bonus de ataque al Patron.',
  iconEmoji: '\u{1FA99}',
  rarity: RarityTier.gray,
  patternBonusAmountOverride: 0,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(
      _adjS,
      EntityTag.economia,
      _adjBarrier,
      1,
    ),
  ],
  baseCost: 2,
  value: 1,
  upgradeValue: 1,
  effect: CoinLauncherItemEffect(),
);

const seguroBolsilloItem = Item(
  id: ItemId.seguroBolsillo,
  actionType: ItemActionType.block,
  actionValue: 6,
  archetypeAffinities: _mercanteAffinities,
  tags: _economiaVidaTags,
  name: 'Seguro de Bolsillo',
  description:
      'Una vez por combate, cuando fueras a perder HP, paga creditos para prevenir daño.',
  iconEmoji: '\u{1F4DD}',
  rarity: RarityTier.green,
  patternBonusKindOverride: _adjBarrier,
  patternBonusAmountOverride: 2,
  patternRequirementOverride: _patternRightAngle,
  baseCost: 4,
  value: 2,
  upgradeValue: 1,
  effect: SeguroBolsilloItemEffect(),
);

const bolsoR33mItem = Item(
  id: ItemId.bolsoR33m,
  archetypeAffinities: _mercanteAffinities,
  tags: _economiaVidaTags,
  name: 'Bolso R33M',
  description:
      'Las primeras veces que gastas creditos durante combate, recuperas el gasto inmediatamente.',
  iconEmoji: '\u{1F45C}',
  rarity: RarityTier.green,
  patternBonusKindOverride: _adjBarrier,
  patternBonusAmountOverride: 2,
  patternRequirementOverride: _patternMiddle,
  baseCost: 4,
  value: 2,
  upgradeValue: 1,
  incomePerValueUnit: 1,
  effect: BolsoR33mItemEffect(),
);

const selloMercanteItem = Item(
  id: ItemId.selloMercante,
  actionType: ItemActionType.heal,
  actionValue: 6,
  archetypeAffinities: _mercanteAffinities,
  tags: _economiaVidaTags,
  name: 'Sello Mercante',
  description: 'Cuando ganas creditos, restauras HP.',
  iconEmoji: '\u{1F3F7}',
  rarity: RarityTier.blue,
  patternBonusAmountOverride: 0,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(
      _adjW,
      EntityTag.vida,
      _adjBarrier,
      1,
    ),
    OperativePatternAdjacencyBonus.match(
      _adjN,
      EntityTag.economia,
      _adjBarrier,
      1,
    ),
  ],
  baseCost: 6,
  value: 3,
  upgradeValue: 2,
  effect: SelloMercanteItemEffect(),
);

const compraAgresivaItem = Item(
  id: ItemId.compraAgresiva,
  actionType: ItemActionType.block,
  actionValue: 8,
  archetypeAffinities: _mercanteAffinities,
  tags: <EntityTag>[EntityTag.economia, EntityTag.barrera, EntityTag.muralla],
  name: 'Compra agresiva',
  description:
      'Al final de tu turno, paga creditos para ganar Barrera. Tras tres pagos, ganas BP.',
  iconEmoji: '\u{1F6D2}',
  rarity: RarityTier.blue,
  patternBonusKindOverride: _adjBarrier,
  patternBonusAmountOverride: 3,
  patternRequirementOverride: _patternSquare,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(
        _adjN, EntityTag.barrera, _adjBarrier, 1),
    OperativePatternAdjacencyBonus.match(
        _adjS, EntityTag.economia, _adjBarrier, 1),
    OperativePatternAdjacencyBonus.match(
        _adjW, EntityTag.muralla, _adjBarrier, 1),
  ],
  baseCost: 6,
  value: 4,
  upgradeValue: -1,
  statModifiers: {
    BattlerStat.barrier: 1,
  },
  effect: CompraAgresivaItemEffect(),
);

const subastaRelampagoItem = Item(
  id: ItemId.subastaRelampago,
  archetypeAffinities: _mercanteAffinities,
  tags: <EntityTag>[EntityTag.economia, EntityTag.buff],
  name: 'Subasta Relampago',
  description:
      'Permite activar el mismo punto dos veces en un Patron y cobra por el primer reuso de cada turno.',
  iconEmoji: '\u{1F528}',
  rarity: RarityTier.blue,
  patternBonusKindOverride: _adjBarrier,
  patternBonusAmountOverride: 3,
  patternRequirementOverride: _patternZigzag,
  baseCost: 6,
  value: 2,
  upgradeValue: 1,
  effect: SubastaRelampagoItemEffect(),
);

const bolsaRiesgoItem = Item(
  id: ItemId.bolsaRiesgo,
  actionType: ItemActionType.attack,
  actionValue: 10,
  archetypeAffinities: _mercanteAffinities,
  tags: _economiaAtaqueTags,
  name: 'Bolsa de Riesgo',
  description:
      'Al comienzo del combate ganas creditos y, al caer bajo media vida, los conviertes en daño.',
  iconEmoji: '\u{1F4BC}',
  rarity: RarityTier.purple,
  patternBonusKindOverride: _adjAttack,
  patternBonusAmountOverride: 2,
  patternRequirementOverride: _patternMiddle,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(
        _adjN, EntityTag.economia, _adjBarrier, 2),
    OperativePatternAdjacencyBonus.match(
        _adjE, EntityTag.ataque, _adjAttack, 2),
    OperativePatternAdjacencyBonus.match(_adjS, EntityTag.vida, _adjBarrier, 2),
    OperativePatternAdjacencyBonus.match(
        _adjW, EntityTag.accesorio, _adjBarrier, 2),
  ],
  baseCost: 8,
  value: 3,
  upgradeValue: 1,
  incomePerValueUnit: 1,
  maxHealthPercentPerValueUnit: -3,
  effect: BolsaRiesgoItemEffect(),
);

const camaraArbitrajeItem = Item(
  id: ItemId.camaraArbitraje,
  actionType: ItemActionType.block,
  actionValue: 10,
  archetypeAffinities: _mercanteAffinities,
  tags: _economiaBarreraDebuffTags,
  name: 'Camara de Arbitraje',
  description: 'Reduce un debuff entrante pagando creditos y recupera Barrera.',
  iconEmoji: '\u{2696}',
  rarity: RarityTier.purple,
  patternBonusKindOverride: _adjBarrier,
  patternBonusAmountOverride: 4,
  patternRequirementOverride: _patternRightAngle,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(
        _adjE, EntityTag.barrera, _adjBarrier, 2),
    OperativePatternAdjacencyBonus.match(
        _adjS, EntityTag.economia, _adjBarrier, 2),
  ],
  baseCost: 8,
  value: 2,
  upgradeValue: 1,
  effect: CamaraArbitrajeItemEffect(),
);

const bancoAmbulanteItem = Item(
  id: ItemId.bancoAmbulante,
  archetypeAffinities: _mercanteAffinities,
  tags: <EntityTag>[
    EntityTag.economia,
    EntityTag.ataque,
    EntityTag.barrera,
  ],
  name: 'Banco Ambulante',
  description:
      'Convierte caja alta en Barrera, invierte en Patrones grandes y genera creditos al final del turno.',
  iconEmoji: '\u{1F3E6}',
  rarity: RarityTier.yellow,
  patternBonusKindOverride: _adjBarrier,
  patternBonusAmountOverride: 5,
  patternRequirementOverride: _patternSquare,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(
        _adjN, EntityTag.economia, _adjBarrier, 2),
    OperativePatternAdjacencyBonus.match(
        _adjE, EntityTag.ataque, _adjAttack, 2),
    OperativePatternAdjacencyBonus.match(
        _adjS, EntityTag.barrera, _adjBarrier, 2),
    OperativePatternAdjacencyBonus.match(
        _adjW, EntityTag.accesorio, _adjBarrier, 2),
  ],
  baseCost: 10,
  value: 5,
  upgradeValue: 0,
  incomePerValueUnit: 1,
  statModifiers: {
    BattlerStat.barrier: 2,
  },
  effect: BancoAmbulanteItemEffect(),
);

const nivelPrecisionItem = Item(
  id: ItemId.nivelPrecision,
  archetypeAffinities: _generalAffinities,
  tags: _ataqueBarreraTags,
  name: 'Nivel de Precision',
  description:
      'Al usarse, si el bonus final de ATK y Barrera del Patron son iguales, suma valor a ambos antes del ataque.',
  iconEmoji: '\u{1F4CF}',
  rarity: RarityTier.blue,
  patternBonusKindOverride: _adjAttack,
  patternBonusAmountOverride: 3,
  patternRequirementOverride: _patternLast,
  baseCost: 6,
  value: 2,
  upgradeValue: 1,
  effect: NivelPrecisionItemEffect(),
);

const sonicaltropsItem = Item(
  id: ItemId.sonicaltrops,
  archetypeAffinities: _generalAffinities,
  tags: _debuffTags,
  name: 'Sonicaltrops',
  description:
      'Durante el primer turno del oponente, reduce el bonus de ATK y Barrera de su Patron.',
  iconEmoji: '\u{1F50A}',
  rarity: RarityTier.blue,
  patternBonusAmountOverride: 0,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(
      _adjN,
      EntityTag.debuff,
      _adjAttack,
      1,
    ),
    OperativePatternAdjacencyBonus.match(
      _adjS,
      EntityTag.debuff,
      _adjBarrier,
      1,
    ),
  ],
  baseCost: 6,
  value: 1,
  upgradeValue: 1,
  effect: SonicaltropsItemEffect(),
);

const mekaYunqueItem = Item(
  id: ItemId.mekaYunque,
  archetypeAffinities: _generalAffinities,
  tags: _ataqueBarreraTags,
  name: 'Meka-yunque',
  description:
      'La primera vez por combate que usas un Patron con 6+ puntos de item, mejora temporalmente el item General equipado de menor rareza.',
  iconEmoji: '\u{1F528}',
  rarity: RarityTier.yellow,
  patternBonusKindOverride: _adjAttack,
  patternBonusAmountOverride: 2,
  patternRequirementOverride: _patternMiddle,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(
      _adjN,
      EntityTag.ataque,
      _adjAttack,
      1,
    ),
    OperativePatternAdjacencyBonus.match(
      _adjE,
      EntityTag.barrera,
      _adjBarrier,
      1,
    ),
    OperativePatternAdjacencyBonus.match(
      _adjS,
      EntityTag.ataque,
      _adjAttack,
      1,
    ),
    OperativePatternAdjacencyBonus.match(
      _adjW,
      EntityTag.barrera,
      _adjBarrier,
      1,
    ),
  ],
  baseCost: 10,
  value: 1,
  upgradeValue: 1,
  statModifiers: {
    BattlerStat.attack: 1,
    BattlerStat.barrier: 1,
  },
  upgradeStatModifiers: {
    BattlerStat.attack: 1,
    BattlerStat.barrier: 1,
  },
  effect: MekaYunqueItemEffect(),
);

const pilarAceroItem = Item(
  id: ItemId.pilarAcero,
  actionType: ItemActionType.block,
  actionValue: 10,
  archetypeAffinities: _inamovibleAffinities,
  tags: _murallaTags,
  name: 'Pilar de Acero',
  description:
      'Al usarse: Crea Murallas al rededor de su punto al final del turno, que duran un turno, tanto en tu matriz como en la del enemigo.',
  iconEmoji: '\u{1F5FC}',
  rarity: RarityTier.purple,
  patternBonusKindOverride: _adjBarrier,
  patternBonusAmountOverride: 1,
  patternRequirementOverride: _patternStraightAngle,
  baseCost: 8,
  value: 1,
  upgradeValue: 1,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(
      _adjN,
      EntityTag.muralla,
      _adjBarrier,
      1,
    ),
    OperativePatternAdjacencyBonus.match(
      _adjS,
      EntityTag.muralla,
      _adjBarrier,
      1,
    ),
  ],
  effect: PilarAceroItemEffect(),
);

const duplicadorAtomosItem = Item(
  id: ItemId.duplicadorAtomos,
  actionType: ItemActionType.block,
  actionValue: 10,
  archetypeAffinities: _velozAffinities,
  tags: _murallaTags,
  name: 'Duplicador de atomos',
  description: 'Al usarse: Copia 1 Murallas en tu matriz a la de tu enemigo.',
  iconEmoji: '\u{269B}',
  rarity: RarityTier.purple,
  patternBonusKindOverride: _adjBarrier,
  patternBonusAmountOverride: 1,
  patternRequirementOverride: _patternSquare,
  baseCost: 8,
  value: 1,
  upgradeValue: 1,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(
      _adjN,
      EntityTag.muralla,
      _adjBarrier,
      1,
    ),
  ],
  effect: DuplicadorAtomosItemEffect(),
);

const cortinaHumoItem = Item(
  id: ItemId.cortinaHumo,
  actionType: ItemActionType.block,
  actionValue: 14,
  archetypeAffinities: _velozAffinities,
  tags: _barreraMurallaTags,
  name: 'Cortina de Humo',
  description: 'Al usarse: Mueve 1 Murallas de tu matriz a la del enemigo.',
  iconEmoji: '\u{1F32B}',
  rarity: RarityTier.yellow,
  patternBonusAmountOverride: 0,
  baseCost: 10,
  value: 1,
  upgradeValue: 0,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(
      _adjN,
      EntityTag.muralla,
      _adjBarrier,
      1,
    ),
    OperativePatternAdjacencyBonus.match(
      _adjS,
      EntityTag.muralla,
      _adjBarrier,
      1,
    ),
    OperativePatternAdjacencyBonus.match(
      _adjE,
      EntityTag.muralla,
      _adjBarrier,
      1,
    ),
    OperativePatternAdjacencyBonus.match(
      _adjW,
      EntityTag.muralla,
      _adjBarrier,
      1,
    ),
  ],
  effect: CortinaHumoItemEffect(),
);

/// Soporte gris que va drenando turnos de debuff de forma dispersa.
const mamparaPortatilItem = Item(
  id: ItemId.mamparaPortatil,
  archetypeAffinities: _inamovibleAffinities,
  tags: _barreraDebuffTags,
  name: 'Mampara Portatil',
  description: 'Al inicio de tu turno, reduce turnos de debuffs aleatorios.',
  iconEmoji: '\u{1F6AA}',
  rarity: RarityTier.gray,
  patternBonusAmountOverride: 0,
  baseCost: 2,
  value: 1,
  upgradeValue: 1,
  effect: MamparaPortatilItemEffect(),
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
  patternBonusAmountOverride: 0,
  baseCost: 2,
  value: 1,
  upgradeValue: 1,
  effect: PagareRevalorizableItemEffect(),
);

/// Accesorio gris de curacion menor y constante.
const botiquinCompactoItem = Item(
  id: ItemId.botiquinCompacto,
  actionType: ItemActionType.heal,
  actionValue: 5,
  archetypeAffinities: _generalAffinities,
  tags: _vidaTags,
  name: 'Botiquin Compacto',
  description: 'Cura 5 HP al usarse. Al inicio de tu turno, recuperas 1 HP.',
  iconEmoji: '\u{1FA79}',
  rarity: RarityTier.gray,
  patternBonusAmountOverride: 0,
  baseCost: 2,
  value: 1,
  upgradeValue: 1,
  effect: RegenerativeShieldItemEffect(),
);

/// Arma gris de control ligero que debilita el siguiente golpe enemigo.
const stunBatonItem = Item(
  id: ItemId.stunBaton,
  actionType: ItemActionType.attack,
  actionValue: 3,
  archetypeAffinities: _velozAffinities,
  tags: _ataqueDebuffTags,
  name: 'Porra de Aturdimiento',
  description: 'Al usarse: aplica Conmocion al enemigo.',
  iconEmoji: '\u{1F50C}',
  rarity: RarityTier.gray,
  patternBonusAmountOverride: 0,
  baseCost: 2,
  value: 1,
  upgradeValue: 1,
  effect: StatusItemEffect(
    kind: ItemStatusEffectKind.conmocion,
    trigger: ItemStatusEffectTrigger.attackTarget,
  ),
);

/// Accesorio gris reactivo que silencia al agresor.
const pocketJammerItem = Item(
  id: ItemId.pocketJammer,
  archetypeAffinities: _velozAffinities,
  tags: _barreraDebuffTags,
  name: 'Interferidor de Bolsillo',
  description: 'Al recibir daño: aplica Conmocion al agresor.',
  iconEmoji: '\u{1F4F6}',
  rarity: RarityTier.gray,
  patternBonusAmountOverride: 0,
  baseCost: 2,
  value: 1,
  upgradeValue: 1,
  effect: StatusItemEffect(
    kind: ItemStatusEffectKind.conmocion,
    trigger: ItemStatusEffectTrigger.receiveDamageSource,
  ),
);

/// Accesorio gris que premia turnos cerrados sin perder vida real.
const aislanteArmonicoItem = Item(
  id: ItemId.aislanteArmonico,
  archetypeAffinities: _inamovibleAffinities,
  tags: _resonanciaBarreraBuffTags,
  name: 'Aislante Armonico',
  description:
      'Si no pierdes vida durante tu turno, ganas Resonancia al final.',
  iconEmoji: '\u{1F9F1}',
  rarity: RarityTier.gray,
  patternBonusAmountOverride: 0,
  baseCost: 2,
  value: 1,
  upgradeValue: 1,
  effect: AislanteArmonicoItemEffect(),
);

/// Arma gris oportunista que ayuda a sostenerse durante remates.
const rescueBladeItem = Item(
  id: ItemId.rescueBlade,
  actionType: ItemActionType.attack,
  actionValue: 7,
  archetypeAffinities: _generalAffinities,
  tags: _ataqueVidaTags,
  name: 'Cuchilla de Rescate',
  description:
      '+3 ATK. Al usarse, si el objetivo queda al 50% de HP o menos, recuperas 3 HP.',
  iconEmoji: '\u{1F691}',
  rarity: RarityTier.green,
  patternBonusKindOverride: _adjAttack,
  patternBonusAmountOverride: 2,
  patternRequirementOverride: _patternLast,
  baseCost: 4,
  value: 3,
  upgradeValue: 1,
  statModifiers: {BattlerStat.attack: 3},
  upgradeStatModifiers: {BattlerStat.attack: 1},
  effect: RescueBladeItemEffect(),
);

/// Armadura gris que devuelve una pequena penalizacion ofensiva si resiste el golpe.
const shockMeshItem = Item(
  id: ItemId.shockMesh,
  archetypeAffinities: _inamovibleAffinities,
  tags: _barreraDebuffTags,
  name: 'Malla de Choque',
  description:
      'Al recibir daño mientras conservas Barrera, aplicas Conmocion al agresor.',
  iconEmoji: '\u{1F4A5}',
  rarity: RarityTier.gray,
  patternBonusAmountOverride: 0,
  baseCost: 2,
  value: 1,
  upgradeValue: 1,
  effect: ShockMeshItemEffect(),
);

/// Accesorio gris de seguridad que redirige los primeros debuffs recibidos.
const deflectiveCapacitorItem = Item(
  id: ItemId.deflectiveCapacitor,
  archetypeAffinities: _inamovibleAffinities,
  tags: _barreraBuffTags,
  name: 'Condensador Deflectivo',
  description:
      'La primera vez que fueras a recibir un debuff, se lo aplicas al enemigo.',
  iconEmoji: '\u{1F530}',
  rarity: RarityTier.gray,
  patternBonusAmountOverride: 0,
  baseCost: 2,
  value: 1,
  upgradeValue: 1,
  effect: DeflectiveCapacitorItemEffect(),
);

/// Accesorio gris que prepara al enemigo para amplificar otros debuffs.
const vialRotoItem = Item(
  id: ItemId.vialRoto,
  archetypeAffinities: _velozAffinities,
  tags: _debuffContagioTags,
  name: 'Vial Roto',
  description: 'Al principio del combate, aplica Contagio al enemigo.',
  iconEmoji: '\u{1F9EA}',
  rarity: RarityTier.gray,
  patternBonusAmountOverride: 0,
  baseCost: 2,
  value: 1,
  upgradeValue: 2,
  effect: VialRotoItemEffect(),
);

/// Arma gris de Veloz que siembra debuffs aleatorios en cada uso.
const plumaSepticaItem = Item(
  id: ItemId.plumaSeptica,
  actionType: ItemActionType.attack,
  actionValue: 3,
  archetypeAffinities: _velozAffinities,
  tags: _ataqueDebuffTags,
  name: 'Pluma Septica',
  description: 'Al usarse: aplica un debuff aleatorio al enemigo.',
  iconEmoji: '\u{1FAB6}',
  rarity: RarityTier.gray,
  patternBonusKindOverride: _adjAttack,
  patternBonusAmountOverride: 1,
  patternRequirementOverride: _patternStraightAngle,
  baseCost: 2,
  value: 1,
  upgradeValue: 1,
  effect: PlumaSepticaItemEffect(),
);

/// Arma gris que convierte enemigos ya debilitados en focos de Contagio.
const lanzaSuciaItem = Item(
  id: ItemId.lanzaSucia,
  actionType: ItemActionType.attack,
  actionValue: 3,
  archetypeAffinities: _velozAffinities,
  tags: _ataqueDebuffContagioTags,
  name: 'Lanza Sucia',
  description:
      'Al usarse contra un enemigo con debuff, aplica Contagio. Bonus de Patron en ataques.',
  iconEmoji: '\u{1F531}',
  rarity: RarityTier.gray,
  patternBonusKindOverride: _adjAttack,
  patternBonusAmountOverride: 1,
  patternRequirementOverride: _patternStraightAngle,
  baseCost: 2,
  value: 1,
  upgradeValue: 1,
  effect: LanzaSuciaItemEffect(),
);

// Green

/// Variante agil del arma basica usada por el arquetipo Veloz.
const cyberWhipsItem = Item(
  id: ItemId.cyberWhips,
  archetypeAffinities: _velozAffinities,
  tags: _ataqueDebuffIntoxicacionTags,
  name: 'Cyber Latigos',
  description:
      'Al usarse: aplica o aumenta Intoxicacion en el enemigo. Bonus de Patron en angulos de 180 grados.',
  iconEmoji: '\u{26D3}',
  rarity: RarityTier.green,
  patternBonusKindOverride: _adjAttack,
  patternBonusAmountOverride: 0,
  patternRequirementOverride: OperativePatternRequirement.straightAngle(),
  baseCost: 4,
  value: 1,
  upgradeValue: 1,
  actionType: ItemActionType.none,
  actionValue: 0,
  effect: CyberWhipsItemEffect(),
);

/// Accesorio verde que refuerza la Fragilidad cuando Contagio ya prendio.
const ampollaInestableItem = Item(
  id: ItemId.ampollaInestable,
  actionType: ItemActionType.attack,
  actionValue: 6,
  archetypeAffinities: _velozAffinities,
  tags: _debuffContagioTags,
  name: 'Ampolla Inestable',
  description:
      'Al usarse: aplica Contagio. Si el enemigo ya tenia Contagio, aplica el doble de Fragilidad.',
  iconEmoji: '\u{2697}',
  rarity: RarityTier.green,
  patternBonusKindOverride: _adjAttack,
  patternBonusAmountOverride: 2,
  patternRequirementOverride: _patternMiddle,
  baseCost: 4,
  value: 1,
  upgradeValue: 1,
  effect: AmpollaInestableItemEffect(),
);

/// Soporte defensivo verde para builds de aguante.
const shieldItem = Item(
  id: ItemId.shield,
  actionType: ItemActionType.block,
  actionValue: 6,
  archetypeAffinities: _inamovibleAffinities,
  tags: _vidaBarreraTags,
  name: 'Escudo',
  description: '+2 Barrera. Al usarse, recuperas 1 HP.',
  iconEmoji: '\u{1F6E1}',
  rarity: RarityTier.green,
  patternBonusKindOverride: _adjBarrier,
  patternBonusAmountOverride: 2,
  patternRequirementOverride: _patternRightAngle,
  baseCost: 4,
  value: 1,
  upgradeValue: 2,
  statModifiers: {
    BattlerStat.barrier: 2,
  },
  upgradeStatModifiers: {
    BattlerStat.barrier: 2,
  },
  effect: HealOnDefendItemEffect(),
);

/// Accesorio verde que sube vida maxima y barrera a la vez.
const bulwarkAmuletItem = Item(
  id: ItemId.bulwarkAmulet,
  actionType: ItemActionType.block,
  actionValue: 7,
  archetypeAffinities: _inamovibleAffinities,
  tags: _vidaBarreraTags,
  name: 'Amuleto de Bastion',
  description: '+6 HP y +1 Barrera mientras este equipado.',
  iconEmoji: '\u{1F9FF}',
  rarity: RarityTier.green,
  patternBonusKindOverride: _adjBarrier,
  patternBonusAmountOverride: 2,
  patternRequirementOverride: _patternSquare,
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

/// Accesorio verde que convierte el Ciclo en recarga defensiva u ofensiva.
const bateriaCrepuscularItem = Item(
  id: ItemId.bateriaCrepuscular,
  archetypeAffinities: _velozAffinities,
  tags: _cicloBuffTags,
  name: 'Bateria Crepuscular',
  description:
      '+1 Barrera. Ciclo. Al inicio de tu turno: de dia recuperas Barrera; de noche ganas Potencia.',
  iconEmoji: '\u{1F306}',
  rarity: RarityTier.green,
  patternBonusKindOverride: _adjBarrier,
  patternBonusAmountOverride: 2,
  patternRequirementOverride: _patternHourglass,
  baseCost: 4,
  value: 1,
  upgradeValue: 1,
  statModifiers: {BattlerStat.barrier: 1},
  effect: BateriaCrepuscularItemEffect(),
);

/// Accesorio verde que hace que Desafio atraviese barrera parcial.
const visorAperturaItem = Item(
  id: ItemId.visorApertura,
  archetypeAffinities: _imparableAffinities,
  tags: _desafioAtaqueBuffTags,
  name: 'Visor de Apertura',
  description: 'Los golpes directos de Desafio ignoran Barrera enemiga.',
  iconEmoji: '\u{1F576}',
  rarity: RarityTier.green,
  patternBonusKindOverride: _adjAttack,
  patternBonusAmountOverride: 2,
  patternRequirementOverride: _patternStraightAngle,
  baseCost: 4,
  value: 3,
  upgradeValue: 1,
  effect: VisorAperturaItemEffect(),
);

/// Accesorio verde ofensivo que aplica Intoxicacion al atacar.
const toxicCatalystItem = Item(
  id: ItemId.toxicCatalyst,
  actionType: ItemActionType.attack,
  actionValue: 5,
  archetypeAffinities: _velozAffinities,
  tags: _debuffIntoxicacionTags,
  name: 'Catalizador Toxico',
  description: '+1 ATK. Accesorio quimico que contamina cada impacto.',
  iconEmoji: '\u2623',
  rarity: RarityTier.green,
  patternBonusKindOverride: _adjAttack,
  patternBonusAmountOverride: 2,
  patternRequirementOverride: _patternMiddle,
  baseCost: 4,
  value: 1,
  upgradeValue: 1,
  statModifiers: {BattlerStat.attack: 1},
  effect: IntoxicarOnAttackItemEffect(),
);

/// Accesorio verde ofensivo que aplica Quemadura al atacar.
const emberCharmItem = Item(
  id: ItemId.emberCharm,
  actionType: ItemActionType.attack,
  actionValue: 5,
  archetypeAffinities: _imparableAffinities,
  tags: _debuffQuemaduraTags,
  name: 'Amuleto de Ascuas',
  description: '+1 ATK. Accesorio ofensivo que prende fuego en cada impacto.',
  iconEmoji: '\u{1F525}',
  rarity: RarityTier.green,
  patternBonusKindOverride: _adjAttack,
  patternBonusAmountOverride: 2,
  patternRequirementOverride: _patternLast,
  baseCost: 4,
  value: 3,
  upgradeValue: 1,
  statModifiers: {BattlerStat.attack: 1},
  effect: QuemaduraOnAttackItemEffect(),
);

/// Accesorio verde defensivo contra Quemadura e Intoxicacion.
const chemicalFilterItem = Item(
  id: ItemId.chemicalFilter,
  actionType: ItemActionType.block,
  actionValue: 5,
  archetypeAffinities: _inamovibleAffinities,
  tags: _debuffQuemaduraIntoxicacionTags,
  name: 'Filtro Quimico',
  description: '+1 Barrera. Reduce la Quemadura y la Intoxicacion que recibes.',
  iconEmoji: '\u{1F637}',
  rarity: RarityTier.green,
  patternBonusKindOverride: _adjBarrier,
  patternBonusAmountOverride: 2,
  patternRequirementOverride: _patternRightAngle,
  baseCost: 4,
  value: 1,
  upgradeValue: 1,
  statModifiers: {BattlerStat.barrier: 1},
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
  patternBonusKindOverride: _adjBarrier,
  patternBonusAmountOverride: 2,
  patternRequirementOverride: _patternSquare,
  baseCost: 4,
  value: 2,
  upgradeValue: 1,
  incomePerValueUnit: 1,
  effect: BillingModuleItemEffect(),
);

/// Arma verde equilibrada que aporta un poco de ataque y barrera a la vez.
const placaBisagraItem = Item(
  id: ItemId.placaBisagra,
  actionType: ItemActionType.attack,
  actionValue: 6,
  archetypeAffinities: _generalAffinities,
  tags: _ataqueBarreraTags,
  name: 'Placa Bisagra',
  description: '+1 ATK y +1 Barrera mientras este equipada.',
  iconEmoji: '\u{2699}',
  rarity: RarityTier.green,
  patternBonusKindOverride: _adjAttack,
  patternBonusAmountOverride: 2,
  patternRequirementOverride: _patternRightAngle,
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

/// Accesorio verde defensivo simple que mezcla un poco de vida y barrera.
const fundaAislanteItem = Item(
  id: ItemId.fundaAislante,
  actionType: ItemActionType.block,
  actionValue: 5,
  archetypeAffinities: _generalAffinities,
  tags: _vidaBarreraTags,
  name: 'Funda Aislante',
  description: '+2 HP y +1 Barrera mientras este equipada.',
  iconEmoji: '\u{1F9BA}',
  rarity: RarityTier.green,
  patternBonusKindOverride: _adjBarrier,
  patternBonusAmountOverride: 2,
  patternRequirementOverride: _patternRightAngle,
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

/// Accesorio verde general que amortigua el primer debuff recibido en combate.
const filtroRuidoItem = Item(
  id: ItemId.filtroRuido,
  archetypeAffinities: _generalAffinities,
  tags: _barreraDebuffTags,
  name: 'Filtro de Ruido',
  description:
      'La primera vez por combate que fueras a recibir un debuff, reduce su valor o duracion.',
  iconEmoji: '\u{1F39A}',
  rarity: RarityTier.gray,
  patternBonusKindOverride: _adjBarrier,
  patternBonusAmountOverride: 2,
  patternRequirementOverride: _patternRightAngle,
  baseCost: 4,
  value: 1,
  upgradeValue: 2,
  effect: FiltroRuidoItemEffect(),
);

/// Arma verde suicida que sobrecarga el primer golpe del turno a cambio de autodebuff.
const clavoReactorItem = Item(
  id: ItemId.clavoReactor,
  actionType: ItemActionType.attack,
  actionValue: 6,
  archetypeAffinities: _imparableAffinities,
  tags: _ataqueDebuffQuemaduraTags,
  name: 'Clavo Reactor',
  description:
      '+2 ATK. Al usarse, una vez por turno, infliges daño directo extra y te aplicas Quemadura.',
  iconEmoji: '\u{1F529}',
  rarity: RarityTier.gray,
  patternBonusKindOverride: _adjAttack,
  patternBonusAmountOverride: 2,
  patternRequirementOverride: _patternStraightAngle,
  baseCost: 4,
  value: 1,
  upgradeValue: 2,
  statModifiers: {BattlerStat.attack: 2},
  upgradeStatModifiers: {BattlerStat.attack: 1},
  effect: ClavoReactorItemEffect(),
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
  actionType: ItemActionType.attack,
  actionValue: 10,
  patternBonusKindOverride: _adjAttack,
  patternBonusAmountOverride: 3,
  patternRequirementOverride: _patternStraightAngle,
  baseCost: 4,
  value: 3,
  upgradeValue: 3,
  statModifiers: {BattlerStat.attack: 3},
  upgradeStatModifiers: {BattlerStat.attack: 3},
);

/// Soporte verde defensivo para enemigos y tienda.
const guardShieldItem = Item(
  id: ItemId.guardShield,
  archetypeAffinities: _generalAffinities,
  tags: _barreraTags,
  name: 'Escudo de Guardia',
  description: '+2 Barrera mientras este equipado.',
  iconEmoji: '\u{1F482}',
  rarity: RarityTier.green,
  actionType: ItemActionType.block,
  actionValue: 8,
  patternBonusKindOverride: _adjBarrier,
  patternBonusAmountOverride: 3,
  patternRequirementOverride: _patternSquare,
  baseCost: 4,
  value: 2,
  upgradeValue: 2,
  statModifiers: {BattlerStat.barrier: 2},
  upgradeStatModifiers: {BattlerStat.barrier: 2},
);

/// Arma verde orientada a abrir ventanas de daño de forma estable.
const serratedEdgeItem = Item(
  id: ItemId.serratedEdge,
  actionType: ItemActionType.attack,
  actionValue: 6,
  archetypeAffinities: _velozAffinities,
  tags: _ataqueDebuffTags,
  name: 'Sierra Dentada',
  description: '+1 ATK. Al usarse: acumula Fragilidad en el enemigo.',
  iconEmoji: '\u2692',
  rarity: RarityTier.green,
  patternBonusKindOverride: _adjAttack,
  patternBonusAmountOverride: 2,
  patternRequirementOverride: _patternLast,
  baseCost: 4,
  value: 2,
  upgradeValue: 1,
  statModifiers: {BattlerStat.attack: 1},
  upgradeStatModifiers: {BattlerStat.attack: 1},
  effect: StatusItemEffect(
    kind: ItemStatusEffectKind.fragilidad,
    trigger: ItemStatusEffectTrigger.attackTarget,
  ),
);

/// Armadura verde que recompone una pequena porcion de barrera al defender.
const containmentCoilItem = Item(
  id: ItemId.containmentCoil,
  actionType: ItemActionType.block,
  actionValue: 6,
  archetypeAffinities: _inamovibleAffinities,
  tags: _barreraBuffTags,
  name: 'Bobina de Contencion',
  description: '+1 Barrera. Al usarse, recuperas 1 de Barrera.',
  iconEmoji: '\u26A1',
  rarity: RarityTier.green,
  patternBonusKindOverride: _adjBarrier,
  patternBonusAmountOverride: 2,
  patternRequirementOverride: _patternSquare,
  baseCost: 4,
  value: 1,
  upgradeValue: 1,
  statModifiers: {BattlerStat.barrier: 1},
  upgradeStatModifiers: {BattlerStat.barrier: 1},
  effect: ContainmentCoilItemEffect(),
);

/// Accesorio verde que acelera el escalado ofensivo golpe a golpe.
const thermalTurbineItem = Item(
  id: ItemId.thermalTurbine,
  actionType: ItemActionType.attack,
  actionValue: 5,
  archetypeAffinities: _imparableAffinities,
  tags: _ataqueBuffTags,
  name: 'Turbina Termica',
  description: '+1 ATK. Al recibir Quemadura, ganas Potencia.',
  iconEmoji: '\u{1F321}',
  rarity: RarityTier.green,
  patternBonusKindOverride: _adjAttack,
  patternBonusAmountOverride: 2,
  patternRequirementOverride: _patternMiddle,
  baseCost: 4,
  value: 15,
  upgradeValue: 1,
  statModifiers: {BattlerStat.attack: 1},
  effect: ThermalTurbineItemEffect(),
);

/// Accesorio verde que convierte las recargas de Barrera en Resonancia.
const nucleoPiezoelectricoItem = Item(
  id: ItemId.nucleoPiezoelectrico,
  actionType: ItemActionType.block,
  actionValue: 7,
  archetypeAffinities: _inamovibleAffinities,
  tags: _resonanciaBarreraBuffTags,
  name: 'Nucleo Piezoelectrico',
  description:
      '+2 Barrera. La primera vez cada turno que ganas Barrera, ganas Resonancia.',
  iconEmoji: '\u{1F50A}',
  rarity: RarityTier.green,
  patternBonusKindOverride: _adjBarrier,
  patternBonusAmountOverride: 2,
  patternRequirementOverride: _patternSquare,
  baseCost: 4,
  value: 2,
  upgradeValue: 1,
  statModifiers: {BattlerStat.barrier: 2},
  upgradeStatModifiers: {BattlerStat.barrier: 1},
  effect: NucleoPiezoelectricoItemEffect(),
);

/// Arma verde que descarga toda la Resonancia acumulada en un golpe.
const descargaResonanteItem = Item(
  id: ItemId.descargaResonante,
  actionType: ItemActionType.attack,
  actionValue: 6,
  archetypeAffinities: _inamovibleAffinities,
  tags: _resonanciaAtaqueBarreraTags,
  name: 'Descarga Resonante',
  description:
      '+1 ATK. Al usarse, consume toda tu Resonancia para infligir daño directo.',
  iconEmoji: '\u{1F4AB}',
  rarity: RarityTier.green,
  patternBonusKindOverride: _adjAttack,
  patternBonusAmountOverride: 2,
  patternRequirementOverride: _patternStraightAngle,
  baseCost: 4,
  value: 1,
  upgradeValue: 1,
  statModifiers: {BattlerStat.attack: 1},
  upgradeStatModifiers: {BattlerStat.attack: 1},
  effect: DescargaResonanteItemEffect(),
);

/// Arma verde de veneno progresivo con remate directo sobre objetivos ya expuestos.
const toxicScalpelItem = Item(
  id: ItemId.toxicScalpel,
  archetypeAffinities: _velozAffinities,
  tags: _ataqueDebuffIntoxicacionTags,
  name: 'Bisturi Toxico',
  description:
      '+1 ATK. Al usarse: aplica o aumenta Intoxicacion. Si ya la tenia, infliges 1 daño directo extra.',
  iconEmoji: '\u{1F9A0}',
  rarity: RarityTier.green,
  actionType: ItemActionType.attack,
  actionValue: 6,
  patternBonusKindOverride: _adjAttack,
  patternBonusAmountOverride: 2,
  patternRequirementOverride: _patternLast,
  baseCost: 4,
  value: 1,
  upgradeValue: 1,
  statModifiers: {BattlerStat.attack: 1},
  upgradeStatModifiers: {BattlerStat.attack: 1},
  effect: ToxicScalpelItemEffect(),
);

// Blue

/// Accesorio azul que cultiva Contagio cuando el enemigo acumula sintomas.
const tuboCultivoItem = Item(
  id: ItemId.tuboCultivo,
  archetypeAffinities: _velozAffinities,
  tags: _debuffContagioTags,
  name: 'Tubo de Cultivo',
  description:
      'Al final de tu turno: si el enemigo tiene 2+ debuffos, aplica Contagio.',
  iconEmoji: '\u{1F9EB}',
  rarity: RarityTier.blue,
  patternBonusKindOverride: _adjAttack,
  patternBonusAmountOverride: 3,
  patternRequirementOverride: _patternMiddle,
  baseCost: 6,
  value: 1,
  upgradeValue: 1,
  effect: TuboCultivoItemEffect(),
);

/// Arma azul que inyecta Contagio desde patrones rectos.
const cyberCerbatanaItem = Item(
  id: ItemId.cyberCerbatana,
  actionType: ItemActionType.attack,
  actionValue: 9,
  archetypeAffinities: _velozAffinities,
  tags: _ataqueDebuffContagioTags,
  name: 'Cyber-cerbatana',
  description:
      'Al usarse: aplica o aumenta Contagio al enemigo. Bonus de Patron en angulos de 180 grados.',
  iconEmoji: '\u{1FA88}',
  rarity: RarityTier.blue,
  patternBonusKindOverride: _adjAttack,
  patternBonusAmountOverride: 2,
  patternRequirementOverride: OperativePatternRequirement.straightAngle(),
  baseCost: 6,
  value: 2,
  upgradeValue: 2,
  effect: CyberCerbatanaItemEffect(),
);

/// Accesorio azul que marca pulsos de curacion o daño segun el momento del Ciclo.
const relojDeTurnoItem = Item(
  id: ItemId.relojDeTurno,
  archetypeAffinities: _velozAffinities,
  tags: _cicloTags,
  name: 'Reloj de Turno',
  description:
      'Ciclo. Al final de tu turno: de dia te curas; de noche infliges daño directo.',
  iconEmoji: '\u23F1',
  rarity: RarityTier.blue,
  patternBonusKindOverride: _adjBarrier,
  patternBonusAmountOverride: 3,
  patternRequirementOverride: _patternHourglass,
  baseCost: 6,
  value: 2,
  upgradeValue: 1,
  effect: RelojDeTurnoItemEffect(),
);

/// Accesorio azul que senala al rival con efectos distintos segun el Ciclo.
const faroNoctivagoItem = Item(
  id: ItemId.faroNoctivago,
  archetypeAffinities: _velozAffinities,
  tags: _cicloBarreraDebuffTags,
  name: 'Faro Noctivago',
  description:
      'Ciclo. Al usarse: de dia aplica Conmocion. De noche acumula Fragilidad.',
  iconEmoji: '\u{1F6A8}',
  rarity: RarityTier.blue,
  patternBonusKindOverride: _adjBarrier,
  patternBonusAmountOverride: 3,
  patternRequirementOverride: _patternZigzag,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(
      _adjS,
      EntityTag.debuff,
      _adjAttack,
      1,
    ),
    OperativePatternAdjacencyBonus.match(
      _adjW,
      EntityTag.debuff,
      _adjBarrier,
      1,
    ),
  ],
  baseCost: 6,
  value: 2,
  upgradeValue: 1,
  effect: FaroNoctivagoItemEffect(),
);

/// Accesorio azul que convierte el riesgo de Desafio en escalado posterior.
const seguroRotoItem = Item(
  id: ItemId.seguroRoto,
  actionType: ItemActionType.attack,
  actionValue: 8,
  archetypeAffinities: _imparableAffinities,
  tags: _desafioAtaqueBuffTags,
  name: 'Seguro Roto',
  description:
      'Cuando un Desafio provoca contraataque, mejora tus siguientes Desafios.',
  iconEmoji: '\u{1F4A5}',
  rarity: RarityTier.blue,
  patternBonusKindOverride: _adjAttack,
  patternBonusAmountOverride: 3,
  patternRequirementOverride: _patternLast,
  baseCost: 6,
  value: 1,
  upgradeValue: 1,
  effect: SeguroRotoItemEffect(),
);

/// Accesorio azul que cura al portar mercancia ajena sin equipar.
const muestrarioContrabandoItem = Item(
  id: ItemId.muestrarioContrabando,
  actionType: ItemActionType.heal,
  actionValue: 7,
  archetypeAffinities: _mercanteAffinities,
  tags: _economiaVidaTags,
  name: 'Muestrario de Contrabando',
  description:
      'Al usarse, te curas por cada item de otro arquetipo en tu inventario.',
  iconEmoji: '\u{1F9F3}',
  rarity: RarityTier.blue,
  patternBonusKindOverride: _adjBarrier,
  patternBonusAmountOverride: 3,
  patternRequirementOverride: _patternZigzag,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(
      _adjW,
      EntityTag.vida,
      _adjBarrier,
      1,
    ),
    OperativePatternAdjacencyBonus.match(
      _adjN,
      EntityTag.economia,
      _adjBarrier,
      1,
    ),
    OperativePatternAdjacencyBonus.match(
      _adjE,
      EntityTag.accesorio,
      _adjBarrier,
      1,
    ),
  ],
  baseCost: 6,
  value: 1,
  upgradeValue: 1,
  effect: MuestrarioContrabandoItemEffect(),
);

/// Arma azul que convierte tu defensa en Potencia persistente de combate.
const magnetiCHammerItem = Item(
  id: ItemId.magnetiCHammer,
  actionType: ItemActionType.block,
  actionValue: 8,
  archetypeAffinities: _inamovibleAffinities,
  tags: _ataqueBarreraTags,
  name: 'M(agneti)C Hammer',
  description:
      'Al usarse, ganas Potencia igual a la mitad de tu Barrera total actual.',
  iconEmoji: '\u{1F528}',
  rarity: RarityTier.blue,
  patternBonusKindOverride: _adjAttack,
  patternBonusAmountOverride: 3,
  patternRequirementOverride: _patternLast,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(
      _adjS,
      EntityTag.arma,
      _adjAttack,
      1,
    ),
    OperativePatternAdjacencyBonus.match(
      _adjW,
      EntityTag.ataque,
      _adjAttack,
      1,
    ),
    OperativePatternAdjacencyBonus.match(
      _adjN,
      EntityTag.barrera,
      _adjBarrier,
      1,
    ),
  ],
  baseCost: 6,
  value: 2,
  upgradeValue: 1,
  effect: MagnetiCHammerItemEffect(),
);

/// Accesorio azul de control defensivo que aturde al agresor.
const silbatoMudoItem = Item(
  id: ItemId.silbatoMudo,
  archetypeAffinities: _generalAffinities,
  tags: _barreraDebuffTags,
  name: 'Silbato Mudo',
  description: 'Al recibir daño: aplica Conmocion al agresor.',
  iconEmoji: '\u{1F507}',
  rarity: RarityTier.blue,
  patternBonusKindOverride: _adjBarrier,
  patternBonusAmountOverride: 3,
  patternRequirementOverride: _patternFirst,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(
      _adjE,
      EntityTag.barrera,
      _adjBarrier,
      1,
    ),
    OperativePatternAdjacencyBonus.match(
      _adjS,
      EntityTag.debuff,
      _adjAttack,
      1,
    ),
    OperativePatternAdjacencyBonus.match(
      _adjW,
      EntityTag.accesorio,
      _adjBarrier,
      1,
    ),
  ],
  baseCost: 6,
  value: 1,
  upgradeValue: 1,
  effect: StatusItemEffect(
    kind: ItemStatusEffectKind.conmocion,
    trigger: ItemStatusEffectTrigger.receiveDamageSource,
  ),
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
  patternBonusKindOverride: _adjBarrier,
  patternBonusAmountOverride: 3,
  patternRequirementOverride: _patternRightAngle,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(
      _adjS,
      EntityTag.debuff,
      _adjAttack,
      1,
    ),
    OperativePatternAdjacencyBonus.match(
      _adjW,
      EntityTag.quemadura,
      _adjAttack,
      1,
    ),
    OperativePatternAdjacencyBonus.match(
      _adjN,
      EntityTag.accesorio,
      _adjBarrier,
      1,
    ),
  ],
  baseCost: 6,
  value: 4,
  upgradeValue: 1,
  effect: QuemaduraOnHitReceivedItemEffect(),
);

/// Arma azul oportunista que protege al portador al defender contra rivales ya tocados.
const kunaiAnchoItem = Item(
  id: ItemId.kunaiAncho,
  actionType: ItemActionType.block,
  actionValue: 8,
  archetypeAffinities: _velozAffinities,
  tags: _ataqueBarreraDebuffTags,
  name: 'Kunai Ancho',
  description: 'Al usarse, si el enemigo tiene un debuff, recuperas Barrera.',
  iconEmoji: '\u{1F52A}',
  rarity: RarityTier.blue,
  patternBonusKindOverride: _adjAttack,
  patternBonusAmountOverride: 3,
  patternRequirementOverride: _patternStraightAngle,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(
      _adjS,
      EntityTag.arma,
      _adjAttack,
      1,
    ),
    OperativePatternAdjacencyBonus.match(
      _adjW,
      EntityTag.ataque,
      _adjAttack,
      1,
    ),
    OperativePatternAdjacencyBonus.match(
      _adjN,
      EntityTag.barrera,
      _adjBarrier,
      1,
    ),
  ],
  baseCost: 6,
  value: 2,
  upgradeValue: 1,
  effect: KunaiAnchoItemEffect(),
);

/// Arma azul que castiga el siguiente ataque del rival.
const pulseCarbineItem = Item(
  id: ItemId.pulseCarbine,
  actionType: ItemActionType.attack,
  actionValue: 9,
  archetypeAffinities: _velozAffinities,
  tags: _ataqueDebuffTags,
  name: 'Carabina de Pulsos',
  description: 'Al usarse: aplica Conmocion al enemigo.',
  iconEmoji: '\u{1F52B}',
  rarity: RarityTier.blue,
  patternBonusKindOverride: _adjAttack,
  patternBonusAmountOverride: 3,
  patternRequirementOverride: _patternStraightAngle,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(
      _adjE,
      EntityTag.arma,
      _adjAttack,
      1,
    ),
    OperativePatternAdjacencyBonus.match(
      _adjS,
      EntityTag.ataque,
      _adjAttack,
      1,
    ),
    OperativePatternAdjacencyBonus.match(
      _adjW,
      EntityTag.debuff,
      _adjAttack,
      1,
    ),
  ],
  baseCost: 6,
  value: 2,
  upgradeValue: 1,
  effect: StatusItemEffect(
    kind: ItemStatusEffectKind.conmocion,
    trigger: ItemStatusEffectTrigger.attackTarget,
  ),
);

/// Armadura azul que recompone una buena porcion de barrera cada turno.
const phaseVeilItem = Item(
  id: ItemId.phaseVeil,
  actionType: ItemActionType.block,
  actionValue: 9,
  archetypeAffinities: _inamovibleAffinities,
  tags: _barreraBuffTags,
  name: 'Velo de Fase',
  description: 'Al inicio de tu turno, recuperas 2 de Barrera.',
  iconEmoji: '\u{1F300}',
  rarity: RarityTier.blue,
  patternBonusKindOverride: _adjBarrier,
  patternBonusAmountOverride: 3,
  patternRequirementOverride: _patternSquare,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(
      _adjS,
      EntityTag.barrera,
      _adjBarrier,
      1,
    ),
    OperativePatternAdjacencyBonus.match(
      _adjW,
      EntityTag.buff,
      _adjBarrier,
      1,
    ),
    OperativePatternAdjacencyBonus.match(
      _adjN,
      EntityTag.barrera,
      _adjBarrier,
      1,
    ),
  ],
  baseCost: 6,
  value: 2,
  upgradeValue: 1,
  effect: RecoverBarrierOnTurnStartItemEffect(amount: 2),
);

/// Blindaje azul de barrera plana alta.
const platedJacketItem = Item(
  id: ItemId.platedJacket,
  actionType: ItemActionType.block,
  actionValue: 8,
  archetypeAffinities: _generalAffinities,
  tags: _barreraTags,
  name: 'Chaqueta Blindada',
  description: '+4 HP y +3 Barrera mientras este equipada.',
  iconEmoji: '\u{1F9E5}',
  rarity: RarityTier.green,
  patternBonusKindOverride: _adjBarrier,
  patternBonusAmountOverride: 2,
  patternRequirementOverride: _patternSquare,
  baseCost: 4,
  value: 4,
  upgradeValue: 4,
  statModifiers: {BattlerStat.health: 4, BattlerStat.barrier: 3},
  upgradeStatModifiers: {BattlerStat.health: 4, BattlerStat.barrier: 3},
);

/// Accesorio azul que descarga la barrera ganada cuando se rompe.
const contingencySealItem = Item(
  id: ItemId.contingencySeal,
  actionType: ItemActionType.block,
  actionValue: 8,
  archetypeAffinities: _inamovibleAffinities,
  tags: _barreraBuffTags,
  name: 'Sello de Contingencia',
  description:
      'Cuando se rompe tu Barrera, haces daño al agresor igual a la Barrera ganada en la ultima ronda de este combate.',
  iconEmoji: '\u2726',
  rarity: RarityTier.blue,
  patternBonusKindOverride: _adjBarrier,
  patternBonusAmountOverride: 3,
  patternRequirementOverride: _patternSquare,
  baseCost: 6,
  value: 1,
  upgradeValue: 1,
  effect: ContingencySealItemEffect(),
);

/// Accesorio azul que transforma impactos sobre Barrera en carga acumulada.
const placasCompresionItem = Item(
  id: ItemId.placasCompresion,
  actionType: ItemActionType.block,
  actionValue: 9,
  archetypeAffinities: _inamovibleAffinities,
  tags: _resonanciaBarreraBuffTags,
  name: 'Placas de Compresion',
  description:
      'Cuando recibes daño a Barrera, ganas Resonancia por la Barrera perdida.',
  iconEmoji: '\u{1F4BF}',
  rarity: RarityTier.blue,
  patternBonusKindOverride: _adjBarrier,
  patternBonusAmountOverride: 3,
  patternRequirementOverride: _patternRightAngle,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(
      _adjW,
      EntityTag.barrera,
      _adjBarrier,
      1,
    ),
    OperativePatternAdjacencyBonus.match(
      _adjN,
      EntityTag.resonancia,
      _adjBarrier,
      1,
    ),
    OperativePatternAdjacencyBonus.match(
      _adjE,
      EntityTag.buff,
      _adjBarrier,
      1,
    ),
  ],
  baseCost: 6,
  value: 3,
  upgradeValue: 1,
  effect: PlacasCompresionItemEffect(),
);

/// Arma azul de control que castiga las barreras de objetivos ya aturdidos.
const interferenceCannonItem = Item(
  id: ItemId.interferenceCannon,
  actionType: ItemActionType.attack,
  actionValue: 9,
  archetypeAffinities: _velozAffinities,
  tags: _ataqueDebuffTags,
  name: 'Cañón de Conmocion',
  description:
      'Al usarse: aplica Conmocion. Si el objetivo ya la tenia, pierde 1 de Barrera.',
  iconEmoji: '\u{1F4E1}',
  rarity: RarityTier.blue,
  patternBonusKindOverride: _adjAttack,
  patternBonusAmountOverride: 3,
  patternRequirementOverride: _patternStraightAngle,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(
      _adjS,
      EntityTag.arma,
      _adjAttack,
      1,
    ),
    OperativePatternAdjacencyBonus.match(
      _adjW,
      EntityTag.ataque,
      _adjAttack,
      1,
    ),
    OperativePatternAdjacencyBonus.match(
      _adjN,
      EntityTag.debuff,
      _adjAttack,
      1,
    ),
  ],
  baseCost: 6,
  value: 2,
  upgradeValue: 1,
  effect: InterferenceCannonItemEffect(),
);

/// Armadura azul de respuesta que recompone barrera solo si no la castigan.
const responseFrameItem = Item(
  id: ItemId.responseFrame,
  actionType: ItemActionType.block,
  actionValue: 8,
  archetypeAffinities: _inamovibleAffinities,
  tags: _barreraBuffTags,
  name: 'Bastidor de Respuesta',
  description:
      'Al final de tu turno, si no has recibido daño, recuperas 2 de Barrera.',
  iconEmoji: '\u{1F5BC}',
  rarity: RarityTier.blue,
  patternBonusKindOverride: _adjBarrier,
  patternBonusAmountOverride: 3,
  patternRequirementOverride: _patternSquare,
  baseCost: 6,
  value: 2,
  upgradeValue: 1,
  effect: ResponseFrameItemEffect(),
);

/// Armadura azul hibrida de economia ligera y recuperacion defensiva condicionada.
const capaDelContrabandistaItem = Item(
  id: ItemId.capaDelContrabandista,
  archetypeAffinities: _velozAffinities,
  tags: _economiaBarreraDebuffTags,
  name: 'Capa del Contrabandista',
  description:
      'Al inicio de tu turno, si el enemigo tiene un debuff, recuperas Barrera segun tu INCOME actual.',
  iconEmoji: '\u{1F977}',
  rarity: RarityTier.blue,
  patternBonusKindOverride: _adjBarrier,
  patternBonusAmountOverride: 3,
  patternRequirementOverride: _patternHourglass,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(
      _adjW,
      EntityTag.barrera,
      _adjBarrier,
      1,
    ),
    OperativePatternAdjacencyBonus.match(
      _adjN,
      EntityTag.debuff,
      _adjAttack,
      1,
    ),
    OperativePatternAdjacencyBonus.match(
      _adjE,
      EntityTag.economia,
      _adjBarrier,
      1,
    ),
  ],
  baseCost: 6,
  value: 1,
  upgradeValue: 1,
  incomePerValueUnit: 1,
  effect: CapaDelContrabandistaItemEffect(),
);

// Purple

/// Accesorio morado que convierte el agotamiento de Contagio en veneno.
const protocoloBroteItem = Item(
  id: ItemId.protocoloBrote,
  archetypeAffinities: _velozAffinities,
  tags: _debuffContagioTags,
  name: 'Protocolo de Brote',
  description:
      'Cuando Contagio enemigo llega a 0 al activarse, aplica Intoxicacion.',
  iconEmoji: '\u{1F9EC}',
  rarity: RarityTier.purple,
  patternBonusKindOverride: _adjAttack,
  patternBonusAmountOverride: 4,
  patternRequirementOverride: _patternMiddle,
  baseCost: 8,
  value: 2,
  upgradeValue: 1,
  effect: ProtocoloBroteItemEffect(),
);

/// Accesorio morado que refuerza la defensa diurna y la pegada nocturna.
const prismaCircadianoItem = Item(
  id: ItemId.prismaCircadiano,
  archetypeAffinities: _velozAffinities,
  tags: _cicloAtaqueBarreraBuffTags,
  name: 'Prisma Circadiano',
  description:
      'Ciclo. De dia reduces daño recibido. De noche infliges daño extra.',
  iconEmoji: '\u{1F308}',
  rarity: RarityTier.purple,
  patternBonusKindOverride: _adjAttack,
  patternBonusAmountOverride: 4,
  patternRequirementOverride: _patternSquare,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(_adjS, EntityTag.arma, _adjAttack, 2),
    OperativePatternAdjacencyBonus.match(
        _adjN, EntityTag.barrera, _adjBarrier, 2),
    OperativePatternAdjacencyBonus.match(_adjW, EntityTag.buff, _adjBarrier, 2),
    OperativePatternAdjacencyBonus.match(_adjE, EntityTag.ciclo, _adjAttack, 2),
  ],
  baseCost: 8,
  value: 2,
  upgradeValue: 1,
  effect: PrismaCircadianoItemEffect(),
);

/// Accesorio morado que cambia sobrevivir contraataques por mejores Desafios.
const aceleradorRetoItem = Item(
  id: ItemId.aceleradorReto,
  actionType: ItemActionType.attack,
  actionValue: 11,
  archetypeAffinities: _imparableAffinities,
  tags: _desafioAtaqueBuffTags,
  name: 'Acelerador de Reto',
  description:
      'Sobrevivir contraataques provocados por Desafio mejora tus siguientes Desafios.',
  iconEmoji: '\u{1F3CE}',
  rarity: RarityTier.purple,
  patternBonusKindOverride: _adjAttack,
  patternBonusAmountOverride: 4,
  patternRequirementOverride: _patternFirst,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(
        _adjS, EntityTag.ataque, _adjAttack, 2),
    OperativePatternAdjacencyBonus.match(
        _adjW, EntityTag.desafio, _adjAttack, 2),
    OperativePatternAdjacencyBonus.match(_adjN, EntityTag.buff, _adjAttack, 2),
    OperativePatternAdjacencyBonus.match(
        _adjE, EntityTag.accesorio, _adjBarrier, 2),
  ],
  baseCost: 8,
  value: 2,
  upgradeValue: 2,
  effect: AceleradorRetoItemEffect(),
);

/// Arma morada que convierte el catalogo ajeno acumulado en ataque estable.
const roperaUnidaItem = Item(
  id: ItemId.roperaUnida,
  actionType: ItemActionType.attack,
  actionValue: 12,
  archetypeAffinities: _mercanteAffinities,
  tags: _economiaAtaqueTags,
  name: 'Ropera Unida',
  description: 'Otorga un bonus de ATK segun tus items de otro arquetipo.',
  iconEmoji: '\u{1F455}',
  rarity: RarityTier.purple,
  patternBonusKindOverride: _adjAttack,
  patternBonusAmountOverride: 4,
  patternRequirementOverride: _patternSquare,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(_adjN, EntityTag.arma, _adjAttack, 2),
    OperativePatternAdjacencyBonus.match(
        _adjE, EntityTag.ataque, _adjAttack, 2),
    OperativePatternAdjacencyBonus.match(
        _adjS, EntityTag.economia, _adjBarrier, 2),
    OperativePatternAdjacencyBonus.match(_adjW, EntityTag.arma, _adjAttack, 2),
  ],
  baseCost: 8,
  value: 2,
  upgradeValue: 3,
  effect: RoperaUnidaItemEffect(),
);

/// Accesorio morado que convierte la vida faltante en daño explosivo para el primer ataque del turno.
const ultimaMarchaItem = Item(
  id: ItemId.ultimaMarcha,
  actionType: ItemActionType.attack,
  actionValue: 12,
  archetypeAffinities: _imparableAffinities,
  tags: _ataqueVidaTags,
  name: 'Ultima Marcha',
  description:
      '+1 ATK. Al usarse, una vez por turno, infliges daño extra segun la vida que te falta.',
  iconEmoji: '\u{1FA78}',
  rarity: RarityTier.purple,
  patternBonusKindOverride: _adjAttack,
  patternBonusAmountOverride: 4,
  patternRequirementOverride: _patternLast,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(
        _adjS, EntityTag.ataque, _adjAttack, 2),
    OperativePatternAdjacencyBonus.match(_adjW, EntityTag.vida, _adjBarrier, 2),
    OperativePatternAdjacencyBonus.match(
        _adjN, EntityTag.accesorio, _adjBarrier, 2),
    OperativePatternAdjacencyBonus.match(
        _adjE, EntityTag.ataque, _adjAttack, 2),
  ],
  baseCost: 8,
  value: 2,
  upgradeValue: 1,
  effect: UltimaMarchaItemEffect(),
);

/// Armadura morada que bloquea automaticamente cuando la vida cae demasiado.
const emergencyPlatingItem = Item(
  id: ItemId.emergencyPlating,
  archetypeAffinities: _inamovibleAffinities,
  tags: _barreraBuffTags,
  name: 'Placa de Emergencia',
  description:
      '+2 Barrera. Las primeras 2 veces en combate que empieces tu turno por debajo de la mitad de vida, bloqueas sin gastar tu turno.',
  iconEmoji: '\u{1F6A7}',
  rarity: RarityTier.purple,
  patternBonusKindOverride: _adjBarrier,
  patternBonusAmountOverride: 4,
  patternRequirementOverride: _patternSquare,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(
        _adjN, EntityTag.barrera, _adjBarrier, 2),
    OperativePatternAdjacencyBonus.match(_adjE, EntityTag.buff, _adjBarrier, 2),
    OperativePatternAdjacencyBonus.match(
        _adjS, EntityTag.barrera, _adjBarrier, 2),
    OperativePatternAdjacencyBonus.match(_adjW, EntityTag.buff, _adjBarrier, 2),
  ],
  baseCost: 8,
  value: 2,
  upgradeValue: 2,
  effect: EmergencyPlatingItemEffect(),
);

/// Accesorio morado que devuelve una conmocion potente al agresor.
const concussionPrismItem = Item(
  id: ItemId.concussionPrism,
  archetypeAffinities: _inamovibleAffinities,
  tags: _barreraDebuffTags,
  name: 'Prisma Concusivo',
  description: 'Al recibir daño: aplica Conmocion al agresor.',
  iconEmoji: '\u{1F48E}',
  rarity: RarityTier.purple,
  patternBonusKindOverride: _adjBarrier,
  patternBonusAmountOverride: 4,
  patternRequirementOverride: _patternSquare,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(
        _adjS, EntityTag.barrera, _adjBarrier, 2),
    OperativePatternAdjacencyBonus.match(
        _adjW, EntityTag.debuff, _adjAttack, 2),
    OperativePatternAdjacencyBonus.match(
        _adjN, EntityTag.accesorio, _adjBarrier, 2),
    OperativePatternAdjacencyBonus.match(
        _adjE, EntityTag.barrera, _adjBarrier, 2),
  ],
  baseCost: 8,
  value: 3,
  upgradeValue: 1,
  effect: StatusItemEffect(
    kind: ItemStatusEffectKind.conmocion,
    trigger: ItemStatusEffectTrigger.receiveDamageSource,
  ),
);

/// Soporte morado defensivo simple y consistente.
const midnightCloakItem = Item(
  id: ItemId.midnightCloak,
  actionType: ItemActionType.block,
  actionValue: 14,
  archetypeAffinities: _generalAffinities,
  tags: _barreraTags,
  name: 'Capa de Medianoche',
  description: '+5 Barrera mientras este equipada.',
  iconEmoji: '\u{1F576}',
  rarity: RarityTier.purple,
  patternBonusKindOverride: _adjBarrier,
  patternBonusAmountOverride: 5,
  patternRequirementOverride: _patternSquare,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(
        _adjS, EntityTag.barrera, _adjBarrier, 2),
    OperativePatternAdjacencyBonus.match(
        _adjW, EntityTag.barrera, _adjBarrier, 2),
    OperativePatternAdjacencyBonus.match(
        _adjN, EntityTag.barrera, _adjBarrier, 2),
    OperativePatternAdjacencyBonus.match(
        _adjE, EntityTag.barrera, _adjBarrier, 2),
  ],
  baseCost: 8,
  value: 5,
  upgradeValue: 5,
  statModifiers: {BattlerStat.barrier: 5},
  upgradeStatModifiers: {BattlerStat.barrier: 5},
);

/// Soporte morado que potencia Quemaduras y las devuelve al portador cada turno.
const portableOvenItem = Item(
  id: ItemId.portableOven,
  actionType: ItemActionType.attack,
  actionValue: 11,
  archetypeAffinities: _imparableAffinities,
  tags: _debuffQuemaduraTags,
  name: 'Horno Portatil',
  description: 'Amplifica tus Quemaduras, pero siempre deja rescoldos.',
  iconEmoji: '\u2668',
  rarity: RarityTier.purple,
  patternBonusKindOverride: _adjAttack,
  patternBonusAmountOverride: 4,
  patternRequirementOverride: _patternSquare,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(
        _adjN, EntityTag.debuff, _adjAttack, 2),
    OperativePatternAdjacencyBonus.match(
        _adjE, EntityTag.quemadura, _adjAttack, 2),
    OperativePatternAdjacencyBonus.match(
        _adjS, EntityTag.debuff, _adjAttack, 2),
    OperativePatternAdjacencyBonus.match(
        _adjW, EntityTag.quemadura, _adjAttack, 2),
  ],
  baseCost: 8,
  value: 1,
  upgradeValue: 1,
  effect: PortableOvenItemEffect(),
);

/// Accesorio morado oportunista que roba liquidez y la convierte en aguante.
const succionaCreditosItem = Item(
  id: ItemId.succionaCreditos,
  actionType: ItemActionType.attack,
  actionValue: 11,
  archetypeAffinities: _velozAffinities,
  tags: _economiaBarreraDebuffTags,
  name: 'SuccionaCreditos',
  description:
      'Al usarse, una vez por turno, si el objetivo tiene un debuff, ganas creditos y recuperas Barrera.',
  iconEmoji: '\u{1F4B8}',
  rarity: RarityTier.purple,
  patternBonusKindOverride: _adjBarrier,
  patternBonusAmountOverride: 4,
  patternRequirementOverride: _patternLast,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(
        _adjN, EntityTag.barrera, _adjBarrier, 2),
    OperativePatternAdjacencyBonus.match(
        _adjE, EntityTag.debuff, _adjAttack, 2),
    OperativePatternAdjacencyBonus.match(
        _adjS, EntityTag.economia, _adjBarrier, 2),
    OperativePatternAdjacencyBonus.match(
        _adjW, EntityTag.accesorio, _adjBarrier, 2),
  ],
  baseCost: 8,
  value: 3,
  upgradeValue: 1,
  effect: SuccionaCreditosItemEffect(),
);

/// Accesorio morado mixto de ataque y vida maxima.
const voidInjectorItem = Item(
  id: ItemId.voidInjector,
  actionType: ItemActionType.attack,
  actionValue: 16,
  archetypeAffinities: _generalAffinities,
  tags: _ataqueVidaTags,
  name: 'Inyector del Vacio',
  description: '+4 ATK y +8 HP mientras este equipado.',
  iconEmoji: '\u{1F573}',
  rarity: RarityTier.purple,
  patternBonusKindOverride: _adjAttack,
  patternBonusAmountOverride: 5,
  patternRequirementOverride: _patternStraightAngle,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(
        _adjW, EntityTag.ataque, _adjAttack, 2),
    OperativePatternAdjacencyBonus.match(_adjN, EntityTag.vida, _adjBarrier, 2),
    OperativePatternAdjacencyBonus.match(
        _adjE, EntityTag.accesorio, _adjBarrier, 2),
    OperativePatternAdjacencyBonus.match(
        _adjS, EntityTag.ataque, _adjAttack, 2),
  ],
  baseCost: 8,
  value: 4,
  upgradeValue: 4,
  statModifiers: {BattlerStat.attack: 4, BattlerStat.health: 8},
  upgradeStatModifiers: {BattlerStat.attack: 4, BattlerStat.health: 8},
);

/// Accesorio morado que sacrifica Barrera al defender para cargar Resonancia.
const torreRetornoItem = Item(
  id: ItemId.torreRetorno,
  actionType: ItemActionType.block,
  actionValue: 12,
  archetypeAffinities: _inamovibleAffinities,
  tags: _resonanciaBarreraBuffTags,
  name: 'Torre de Retorno',
  description:
      'Al usarse, conviertes parte de tu Barrera actual en Resonancia duplicada.',
  iconEmoji: '\u{1F5FC}',
  rarity: RarityTier.purple,
  patternBonusKindOverride: _adjBarrier,
  patternBonusAmountOverride: 4,
  patternRequirementOverride: _patternSquare,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(
        _adjN, EntityTag.barrera, _adjBarrier, 2),
    OperativePatternAdjacencyBonus.match(
        _adjE, EntityTag.resonancia, _adjBarrier, 2),
    OperativePatternAdjacencyBonus.match(_adjS, EntityTag.buff, _adjBarrier, 2),
    OperativePatternAdjacencyBonus.match(
        _adjW, EntityTag.accesorio, _adjBarrier, 2),
  ],
  baseCost: 8,
  value: 2,
  upgradeValue: 1,
  effect: TorreRetornoItemEffect(),
);

/// Accesorio morado que proyecta Resonancia como daño sin consumirla.
const prismaDeEcoItem = Item(
  id: ItemId.prismaDeEco,
  actionType: ItemActionType.attack,
  actionValue: 11,
  archetypeAffinities: _inamovibleAffinities,
  tags: _resonanciaAtaqueBarreraTags,
  name: 'Prisma de Eco',
  description:
      'Una vez por turno, al usarse, infliges daño directo igual a la mitad de tu Resonancia actual.',
  iconEmoji: '\u{1FA9E}',
  rarity: RarityTier.purple,
  patternBonusKindOverride: _adjAttack,
  patternBonusAmountOverride: 4,
  patternRequirementOverride: _patternSquare,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(
        _adjN, EntityTag.resonancia, _adjBarrier, 2),
    OperativePatternAdjacencyBonus.match(
        _adjE, EntityTag.ataque, _adjAttack, 2),
    OperativePatternAdjacencyBonus.match(
        _adjS, EntityTag.barrera, _adjBarrier, 2),
    OperativePatternAdjacencyBonus.match(
        _adjW, EntityTag.accesorio, _adjBarrier, 2),
  ],
  baseCost: 8,
  value: 2,
  upgradeValue: 1,
  effect: PrismaDeEcoItemEffect(),
);

/// Accesorio morado que traduce el sobrecalentamiento en defensa inmediata.
const overloadAnchorItem = Item(
  id: ItemId.overloadAnchor,
  actionType: ItemActionType.block,
  actionValue: 12,
  archetypeAffinities: _imparableAffinities,
  tags: _ataqueBarreraBuffTags,
  name: 'Ancla de Sobrecarga',
  description: 'Al usarse, si tienes Calentando, recuperas Barrera.',
  iconEmoji: '\u2693',
  rarity: RarityTier.purple,
  patternBonusKindOverride: _adjAttack,
  patternBonusAmountOverride: 4,
  patternRequirementOverride: _patternLast,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(
        _adjN, EntityTag.ataque, _adjAttack, 2),
    OperativePatternAdjacencyBonus.match(
        _adjE, EntityTag.barrera, _adjBarrier, 2),
    OperativePatternAdjacencyBonus.match(_adjS, EntityTag.buff, _adjBarrier, 2),
    OperativePatternAdjacencyBonus.match(
        _adjW, EntityTag.accesorio, _adjBarrier, 2),
  ],
  baseCost: 8,
  value: 2,
  upgradeValue: 1,
  effect: OverloadAnchorItemEffect(),
);

/// Accesorio morado reactivo que solo devuelve una penalizacion por turno.
const reboundLensItem = Item(
  id: ItemId.reboundLens,
  actionType: ItemActionType.block,
  actionValue: 11,
  archetypeAffinities: _inamovibleAffinities,
  tags: _barreraDebuffTags,
  name: 'Lente de Rebote',
  description:
      '+1 Barrera. La primera vez que recibes daño cada turno, acumulas Fragilidad en el agresor.',
  iconEmoji: '\u{1F52E}',
  rarity: RarityTier.purple,
  patternBonusKindOverride: _adjBarrier,
  patternBonusAmountOverride: 4,
  patternRequirementOverride: _patternRightAngle,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(
        _adjE, EntityTag.barrera, _adjBarrier, 2),
    OperativePatternAdjacencyBonus.match(
        _adjS, EntityTag.debuff, _adjAttack, 2),
    OperativePatternAdjacencyBonus.match(
        _adjW, EntityTag.accesorio, _adjBarrier, 2),
    OperativePatternAdjacencyBonus.match(
        _adjN, EntityTag.barrera, _adjBarrier, 2),
  ],
  baseCost: 8,
  value: 2,
  upgradeValue: 1,
  effect: ReboundLensItemEffect(),
);

// Yellow

/// Accesorio amarillo que abre el combate con Contagio y da Barrera al activarlo.
const incubadoraPortatilItem = Item(
  id: ItemId.incubadoraPortatil,
  archetypeAffinities: _velozAffinities,
  tags: _barreraDebuffContagioTags,
  name: 'Incubadora Portatil',
  description:
      'Al principio del combate, aplica Contagio. Cada vez que Contagio enemigo se activa, recuperas 3 Barrera.',
  iconEmoji: '\u{1F9EB}',
  rarity: RarityTier.yellow,
  patternBonusKindOverride: _adjBarrier,
  patternBonusAmountOverride: 5,
  patternRequirementOverride: _patternSquare,
  baseCost: 10,
  value: 3,
  upgradeValue: 1,
  effect: IncubadoraPortatilItemEffect(),
);

/// Arma amarilla que remata tras recibir el castigo de Desafio.
const ultimaPalabraItem = Item(
  id: ItemId.ultimaPalabra,
  actionType: ItemActionType.attack,
  actionValue: 18,
  archetypeAffinities: _imparableAffinities,
  tags: _desafioAtaqueBuffTags,
  name: 'Ultima Palabra',
  description:
      'Una vez por turno, tras recibir un contraataque de Desafio, atacas.',
  iconEmoji: '\u{1F5E1}',
  rarity: RarityTier.yellow,
  patternBonusKindOverride: _adjAttack,
  patternBonusAmountOverride: 5,
  patternRequirementOverride: _patternLast,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(_adjW, EntityTag.arma, _adjAttack, 2),
    OperativePatternAdjacencyBonus.match(
        _adjN, EntityTag.ataque, _adjAttack, 2),
    OperativePatternAdjacencyBonus.match(
        _adjE, EntityTag.desafio, _adjAttack, 2),
    OperativePatternAdjacencyBonus.match(_adjS, EntityTag.buff, _adjAttack, 2),
  ],
  baseCost: 10,
  value: 4,
  upgradeValue: 0,
  statModifiers: {BattlerStat.attack: 3},
  effect: UltimaPalabraItemEffect(),
);

/// Accesorio amarillo que purga con fuerza cualquier debuff purgable.
const ceramicaPurgadoraItem = Item(
  id: ItemId.ceramicaPurgadora,
  actionType: ItemActionType.block,
  actionValue: 16,
  archetypeAffinities: _inamovibleAffinities,
  tags: _barreraDebuffTags,
  name: 'Ceramica Purgadora',
  description:
      '+3 Barrera. Al inicio de tu turno, reduces turnos de todos tus debuffs purgables.',
  iconEmoji: '\u{1F3FA}',
  rarity: RarityTier.yellow,
  patternBonusKindOverride: _adjBarrier,
  patternBonusAmountOverride: 5,
  patternRequirementOverride: _patternRightAngle,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(
        _adjW, EntityTag.barrera, _adjBarrier, 2),
    OperativePatternAdjacencyBonus.match(
        _adjN, EntityTag.debuff, _adjAttack, 2),
    OperativePatternAdjacencyBonus.match(
        _adjE, EntityTag.accesorio, _adjBarrier, 2),
    OperativePatternAdjacencyBonus.match(
        _adjS, EntityTag.barrera, _adjBarrier, 2),
  ],
  baseCost: 10,
  value: 2,
  upgradeValue: 1,
  statModifiers: {BattlerStat.barrier: 3},
  effect: CeramicaPurgadoraItemEffect(),
);

/// Arma amarilla que acelera de verdad las cadenas de Calentando.
const overloadInjectorItem = Item(
  id: ItemId.overloadInjector,
  actionType: ItemActionType.attack,
  actionValue: 18,
  archetypeAffinities: _imparableAffinities,
  tags: _ataqueBuffTags,
  name: 'Inyector de Sobrecarga',
  description:
      '+3 ATK. Al inicio del combate, ganas una gran carga de Calentando.',
  iconEmoji: '\u{1F489}',
  rarity: RarityTier.yellow,
  patternBonusKindOverride: _adjAttack,
  patternBonusAmountOverride: 5,
  patternRequirementOverride: _patternStraightAngle,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(_adjW, EntityTag.arma, _adjAttack, 2),
    OperativePatternAdjacencyBonus.match(
        _adjN, EntityTag.ataque, _adjAttack, 2),
    OperativePatternAdjacencyBonus.match(_adjE, EntityTag.buff, _adjAttack, 2),
    OperativePatternAdjacencyBonus.match(_adjS, EntityTag.arma, _adjAttack, 2),
  ],
  baseCost: 10,
  value: 9,
  upgradeValue: 3,
  statModifiers: {BattlerStat.attack: 3},
  upgradeStatModifiers: {BattlerStat.attack: 1},
  effect: ThermalTurbineItemEffect(),
);

/// Accesorio amarillo que devuelve Barrera cuando la Resonancia hace daño.
const canonContrapresionItem = Item(
  id: ItemId.canonContrapresion,
  actionType: ItemActionType.block,
  actionValue: 16,
  archetypeAffinities: _inamovibleAffinities,
  tags: _resonanciaAtaqueBarreraTags,
  name: 'Cañón de Contrapresion',
  description:
      '+2 Barrera. Cuando tu Resonancia inflige daño, ganas Barrera igual a la mitad del daño infligido.',
  iconEmoji: '\u{1F4E3}',
  rarity: RarityTier.yellow,
  patternBonusKindOverride: _adjBarrier,
  patternBonusAmountOverride: 5,
  patternRequirementOverride: _patternStraightAngle,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(
        _adjS, EntityTag.ataque, _adjAttack, 2),
    OperativePatternAdjacencyBonus.match(
        _adjW, EntityTag.barrera, _adjBarrier, 2),
    OperativePatternAdjacencyBonus.match(
        _adjN, EntityTag.resonancia, _adjBarrier, 2),
    OperativePatternAdjacencyBonus.match(
        _adjE, EntityTag.accesorio, _adjBarrier, 2),
  ],
  baseCost: 10,
  value: 0,
  upgradeValue: 0,
  statModifiers: {BattlerStat.barrier: 2},
  effect: CanonContrapresionItemEffect(),
);

/// Arma amarilla de daño alto para el tramo final.
const sunsteelBladeItem = Item(
  id: ItemId.sunsteelBlade,
  actionType: ItemActionType.attack,
  actionValue: 26,
  archetypeAffinities: _generalAffinities,
  tags: _ataqueTags,
  name: 'Filo Solar',
  description: '+10 ATK mientras este equipado.',
  iconEmoji: '\u{1F5E1}',
  rarity: RarityTier.yellow,
  patternBonusKindOverride: _adjAttack,
  patternBonusAmountOverride: 6,
  patternRequirementOverride: _patternStraightAngle,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(_adjN, EntityTag.arma, _adjAttack, 2),
    OperativePatternAdjacencyBonus.match(
        _adjE, EntityTag.ataque, _adjAttack, 2),
    OperativePatternAdjacencyBonus.match(_adjS, EntityTag.arma, _adjAttack, 2),
    OperativePatternAdjacencyBonus.match(
        _adjW, EntityTag.ataque, _adjAttack, 2),
  ],
  baseCost: 10,
  value: 8,
  upgradeValue: 8,
  statModifiers: {BattlerStat.attack: 10},
  upgradeStatModifiers: {BattlerStat.attack: 10},
);

/// Accesorio amarillo centrado en vida maxima.
const dawnCharmItem = Item(
  id: ItemId.dawnCharm,
  actionType: ItemActionType.heal,
  actionValue: 18,
  archetypeAffinities: _generalAffinities,
  tags: _vidaTags,
  name: 'Amuleto del Alba',
  description: '+20 HP mientras este equipado.',
  iconEmoji: '\u2600',
  rarity: RarityTier.yellow,
  patternBonusKindOverride: _adjBarrier,
  patternBonusAmountOverride: 6,
  patternRequirementOverride: _patternSquare,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(_adjE, EntityTag.vida, _adjBarrier, 2),
    OperativePatternAdjacencyBonus.match(
        _adjS, EntityTag.accesorio, _adjBarrier, 2),
    OperativePatternAdjacencyBonus.match(_adjW, EntityTag.vida, _adjBarrier, 2),
    OperativePatternAdjacencyBonus.match(
        _adjN, EntityTag.accesorio, _adjBarrier, 2),
  ],
  baseCost: 10,
  value: 16,
  upgradeValue: 16,
  statModifiers: {BattlerStat.health: 20},
  upgradeStatModifiers: {BattlerStat.health: 20},
);

/// Soporte amarillo que alterna entre defensa diurna y ataque nocturno.
const eclipseMantleItem = Item(
  id: ItemId.eclipseMantle,
  archetypeAffinities: _velozAffinities,
  tags: _cicloAtaqueBarreraTags,
  name: 'Manto de Eclipse',
  description:
      '+2 Barrera. Ciclo. Alterna entre Barrera y ATK, y marca el ritmo para tus efectos de Ciclo.',
  iconEmoji: '\u{1F318}',
  rarity: RarityTier.yellow,
  patternBonusKindOverride: _adjBarrier,
  patternBonusAmountOverride: 5,
  patternRequirementOverride: _patternHourglass,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(
        _adjS, EntityTag.ataque, _adjAttack, 2),
    OperativePatternAdjacencyBonus.match(
        _adjW, EntityTag.barrera, _adjBarrier, 2),
    OperativePatternAdjacencyBonus.match(
        _adjN, EntityTag.ciclo, _adjBarrier, 2),
    OperativePatternAdjacencyBonus.match(
        _adjE, EntityTag.accesorio, _adjBarrier, 2),
  ],
  baseCost: 10,
  value: 3,
  upgradeValue: 1,
  statModifiers: {BattlerStat.barrier: 2},
  effect: EclipseMantleItemEffect(),
);

/// Accesorio amarillo que evita una muerte por combate.
const operativeBlackBoxItem = Item(
  id: ItemId.operativeBlackBox,
  actionType: ItemActionType.heal,
  actionValue: 10,
  archetypeAffinities: _generalAffinities,
  tags: _vidaTags,
  name: 'Caja Negra del Operativo',
  description:
      '+8 HP. Failsafe de emergencia que rehusa dejar caer la unidad a la primera.',
  iconEmoji: '\u{1F4E6}',
  rarity: RarityTier.yellow,
  patternBonusKindOverride: _adjBarrier,
  patternBonusAmountOverride: 5,
  patternRequirementOverride: _patternSquare,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(_adjW, EntityTag.vida, _adjBarrier, 2),
    OperativePatternAdjacencyBonus.match(
        _adjN, EntityTag.accesorio, _adjBarrier, 2),
    OperativePatternAdjacencyBonus.match(_adjE, EntityTag.vida, _adjBarrier, 2),
    OperativePatternAdjacencyBonus.match(
        _adjS, EntityTag.accesorio, _adjBarrier, 2),
  ],
  baseCost: 10,
  value: 1,
  upgradeValue: 1,
  statModifiers: {BattlerStat.health: 8},
  effect: OperativeBlackBoxItemEffect(),
);

/// Arma amarilla de remate que convierte la Quemadura acumulada en daño inmediato.
const sunExecutionBladeItem = Item(
  id: ItemId.sunExecutionBlade,
  actionType: ItemActionType.attack,
  actionValue: 18,
  archetypeAffinities: _imparableAffinities,
  tags: _ataqueDebuffQuemaduraTags,
  name: 'Hoja de Ejecucion Solar',
  description:
      '+4 ATK. Al usarse, si el objetivo tiene Quemadura, la consume y añade daño directo extra.',
  iconEmoji: '\u{1F506}',
  rarity: RarityTier.yellow,
  patternBonusKindOverride: _adjAttack,
  patternBonusAmountOverride: 5,
  patternRequirementOverride: _patternStraightAngle,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(
      _adjE,
      EntityTag.arma,
      _adjAttack,
      2,
    ),
    OperativePatternAdjacencyBonus.match(
      _adjS,
      EntityTag.ataque,
      _adjAttack,
      2,
    ),
    OperativePatternAdjacencyBonus.match(
      _adjW,
      EntityTag.debuff,
      _adjAttack,
      2,
    ),
    OperativePatternAdjacencyBonus.match(
      _adjN,
      EntityTag.quemadura,
      _adjAttack,
      2,
    ),
  ],
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
  vialRotoItem,
  plumaSepticaItem,
  lanzaSuciaItem,
  cyberWhipsItem,
  ampollaInestableItem,
  tuboCultivoItem,
  cyberCerbatanaItem,
  sunglassesItem,
  shieldItem,
  bulwarkAmuletItem,
  crackedBatteryItem,
  gafasFotocromaticasItem,
  bateriaCrepuscularItem,
  relojDeTurnoItem,
  faroNoctivagoItem,
  prismaCircadianoItem,
  impactGlovesItem,
  guanteRetoItem,
  clavoDuelistaItem,
  vendasApretadasItem,
  marcaRetadorItem,
  hemomedidorItem,
  carbonParaHeridasItem,
  juegosucio101Item,
  contratoDolorosoItem,
  yunqueCardiacoItem,
  revanchadoraItem,
  embudoMejorasItem,
  arnesTacticoItem,
  mandibultimatumItem,
  estandarteUltimoSolItem,
  motorMartirioItem,
  visorAperturaItem,
  protocoloBroteItem,
  seguroRotoItem,
  aceleradorRetoItem,
  incubadoraPortatilItem,
  ultimaPalabraItem,
  toxicCatalystItem,
  emberCharmItem,
  chemicalFilterItem,
  billingModuleItem,
  mochilaStronkboxItem,
  buzonVirtualAzulItem,
  buzonVirtualRojoItem,
  buzonVirtualVerdeItem,
  taladronItem,
  cuboDinamitalicoItem,
  medidorRoturaItem,
  murallaAutomaticaItem,
  barbedShieldItem,
  literalPaywallItem,
  passCardItem,
  tonfasEscudoItem,
  constructionSealItem,
  shoppingChecklistItem,
  laCuentaItem,
  coinLauncherItem,
  seguroBolsilloItem,
  bolsoR33mItem,
  selloMercanteItem,
  compraAgresivaItem,
  subastaRelampagoItem,
  bolsaRiesgoItem,
  camaraArbitrajeItem,
  nivelPrecisionItem,
  sonicaltropsItem,
  bancoAmbulanteItem,
  mekaYunqueItem,
  pilarAceroItem,
  duplicadorAtomosItem,
  cortinaHumoItem,
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
  filtroRuidoItem,
  clavoReactorItem,
  ultimaMarchaItem,
  stunBatonItem,
  emergencyPlatingItem,
  pocketJammerItem,
  serratedEdgeItem,
  containmentCoilItem,
  thermalTurbineItem,
  pulseCarbineItem,
  phaseVeilItem,
  concussionPrismItem,
  overloadInjectorItem,
  contingencySealItem,
  nucleoPiezoelectricoItem,
  descargaResonanteItem,
  placasCompresionItem,
  torreRetornoItem,
  prismaDeEcoItem,
  aislanteArmonicoItem,
  canonContrapresionItem,
  ironSwordItem,
  guardShieldItem,
  platedJacketItem,
  reactiveCasingItem,
  portableOvenItem,
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
  sunExecutionBladeItem,
];

/// Registro canonico por id para resolver presets sin recorrer toda la lista.
final Map<ItemId, Item> itemPresetRegistry = Map<ItemId, Item>.unmodifiable({
  for (final item in itemPresets) item.id: item,
});
