import '../_imports.dart';

const _adjN = OperativePatternAdjacencyDirection.north;
const _adjE = OperativePatternAdjacencyDirection.east;
const _adjS = OperativePatternAdjacencyDirection.south;
const _adjW = OperativePatternAdjacencyDirection.west;
const _adjAttack = OperativePatternBonusKind.attack;
const _adjBarrier = OperativePatternBonusKind.barrier;

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

// Item presets ordered by tier: gray -> green -> blue -> purple -> yellow

/// Arma gris sencilla para encuentros y tiendas de bajo nivel.
const woodenStickItem = Item(
  id: ItemId.woodenStick,
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

/// Accesorio agil que reduce el ATK total para convertir cada ataque en doble golpe.
const sunglassesItem = Item(
  id: ItemId.sunglasses,
  archetypeAffinities: _velozAffinities,
  tags: _ataqueBarreraTags,
  name: 'Gafas de Sol',
  description:
      'Cada ataque basico golpea dos veces, pero tus bonus de items se reducen a la mitad.',
  iconEmoji: '\u{1F453}',
  rarity: RarityTier.gray,
  patternBonusAmountOverride: 0,
  baseCost: 2,
  value: 1,
  upgradeValue: 1,
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
  value: 2,
  upgradeValue: 1,
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
      'Al recibir dano: si perdiste HP, ganas 2 Desafio. Una vez por turno.',
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
  archetypeAffinities: _imparableAffinities,
  tags: _desafioVidaBuffTags,
  name: 'Hemomedidor',
  description: 'Al usarse: ganas 1 Desafio por cada 10 HP faltantes, maximo 3.',
  iconEmoji: '\u{1FA78}',
  rarity: RarityTier.green,
  patternBonusAmountOverride: 0,
  baseCost: 4,
  value: 1,
  upgradeValue: 1,
  effect: HemomedidorItemEffect(),
);

const heridaCarbonizadaItem = Item(
  id: ItemId.heridaCarbonizada,
  archetypeAffinities: _imparableAffinities,
  tags: _desafioQuemaduraBuffTags,
  name: 'Herida Carbonizada',
  description: 'Al recibir dano de Quemadura a tu HP: ganas 3 Desafio.',
  iconEmoji: '\u{1FAE7}',
  rarity: RarityTier.green,
  patternBonusAmountOverride: 0,
  baseCost: 4,
  value: 3,
  upgradeValue: 2,
  effect: HeridaCarbonizadaItemEffect(),
);

const guanteProvocacionItem = Item(
  id: ItemId.guanteProvocacion,
  archetypeAffinities: _imparableAffinities,
  tags: _desafioAtaqueBuffTags,
  name: 'Guante de Provocacion',
  description:
      'Al usarse: ganas 2 Desafio. Si el enemigo tiene un debuff, ganas doble Desafio.',
  iconEmoji: '\u{1F94A}',
  rarity: RarityTier.green,
  patternBonusAmountOverride: 0,
  baseCost: 4,
  value: 2,
  upgradeValue: 1,
  statModifiers: {
    BattlerStat.attack: 1,
  },
  effect: GuanteProvocacionItemEffect(),
);

const contratoDolorosoItem = Item(
  id: ItemId.contratoDoloroso,
  archetypeAffinities: _imparableAffinities,
  tags: _desafioBarreraBuffTags,
  name: 'Contrato Doloroso',
  description:
      'Al final de tu turno: si recibiste dano a tu HP este turno, ganas 2 Desafio y 1 Barrera.',
  iconEmoji: '\u{1F4DC}',
  rarity: RarityTier.blue,
  patternBonusAmountOverride: 0,
  baseCost: 6,
  value: 2,
  upgradeValue: 2,
  effect: ContratoDolorosoItemEffect(),
);

const yunqueCardiacoItem = Item(
  id: ItemId.yunqueCardiaco,
  archetypeAffinities: _imparableAffinities,
  tags: _desafioBarreraBuffTags,
  name: 'Yunque Cardiaco',
  description:
      'Al recibir dano a HP: convierte hasta 2 de ese dano en Desafio, evitando ese dano hacia ti. Una vez por turno.',
  iconEmoji: '\u{1F528}',
  rarity: RarityTier.blue,
  patternBonusAmountOverride: 0,
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
      'Cuando una Quemadura propia te hace dano, ganas Desafio igual a la mitad de esa Quemadura y te curas 2.',
  iconEmoji: '\u{1F52A}',
  rarity: RarityTier.blue,
  patternBonusAmountOverride: 0,
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
  patternBonusAmountOverride: 0,
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
      'Al recibir dano de Quemadura: ganas 2 Potencia. Una vez por turno, al gastar o purgar tu Potencia, recibes la mitad en Desafio.',
  iconEmoji: '\u{1F9BA}',
  rarity: RarityTier.purple,
  patternBonusAmountOverride: 0,
  baseCost: 8,
  value: 2,
  upgradeValue: 3,
  effect: ArnesTacticoItemEffect(),
);

const mandibultimatumItem = Item(
  id: ItemId.mandibultimatum,
  archetypeAffinities: _imparableAffinities,
  tags: _desafioAtaqueBuffTags,
  name: 'Mandibultimatum',
  description:
      'Al usarse: consumes hasta 2 Quemadura propia para recibir ese dano a la HP, y ganar el doble en Desafio ANTES de resolver el ataque.',
  iconEmoji: '\u{1F9B7}',
  rarity: RarityTier.purple,
  patternBonusAmountOverride: 0,
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
  patternBonusAmountOverride: 0,
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
      'Al recibir dano a HP, o dano de Quemadura: ganas Desafio igual al dano recibido, max 8 por turno. Al final del turno, si tienes 8+ Desafio, te curas 8 HP.',
  iconEmoji: '\u{2699}',
  rarity: RarityTier.yellow,
  patternBonusAmountOverride: 0,
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
  archetypeAffinities: _generalAffinities,
  tags: _vidaTags,
  name: 'Botiquin Compacto',
  description: 'Al inicio de tu turno, recuperas 1 HP.',
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
  archetypeAffinities: _generalAffinities,
  tags: _ataqueVidaTags,
  name: 'Cuchilla de Rescate',
  description:
      '+3 ATK. Al usarse, si el objetivo queda al 50% de HP o menos, recuperas 3 HP.',
  iconEmoji: '\u{1F691}',
  rarity: RarityTier.green,
  patternBonusAmountOverride: 0,
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
  archetypeAffinities: _inamovibleMercanteAffinities,
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
  archetypeAffinities: _velozInamovibleMercanteAffinities,
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
  patternBonusAmountOverride: 1,
  patternRequirementOverride: OperativePatternRequirement.straightAngle(),
  baseCost: 4,
  value: 1,
  upgradeValue: 1,
  effect: IntoxicarOnAttackItemEffect(),
);

/// Soporte defensivo verde para builds de aguante.
const shieldItem = Item(
  id: ItemId.shield,
  archetypeAffinities: _inamovibleMercanteAffinities,
  tags: _vidaBarreraTags,
  name: 'Escudo',
  description: '+2 Barrera. Al usarse, recuperas 1 HP.',
  iconEmoji: '\u{1F6E1}',
  rarity: RarityTier.green,
  patternBonusAmountOverride: 0,
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
  archetypeAffinities: _inamovibleMercanteAffinities,
  tags: _vidaBarreraTags,
  name: 'Amuleto de Bastion',
  description: '+6 HP y +1 Barrera mientras este equipado.',
  iconEmoji: '\u{1F9FF}',
  rarity: RarityTier.green,
  patternBonusAmountOverride: 0,
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
  patternBonusAmountOverride: 0,
  baseCost: 4,
  value: 2,
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
  patternBonusAmountOverride: 0,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(
      _adjN,
      EntityTag.ataque,
      _adjAttack,
      1,
    ),
    OperativePatternAdjacencyBonus.match(
      _adjE,
      EntityTag.desafio,
      _adjAttack,
      1,
    ),
  ],
  baseCost: 4,
  value: 3,
  upgradeValue: 1,
);

/// Accesorio verde ofensivo que aplica Intoxicacion al atacar.
const toxicCatalystItem = Item(
  id: ItemId.toxicCatalyst,
  archetypeAffinities: _velozAffinities,
  tags: _debuffIntoxicacionTags,
  name: 'Catalizador Toxico',
  description: '+1 ATK. Accesorio quimico que contamina cada impacto.',
  iconEmoji: '\u2623',
  rarity: RarityTier.green,
  patternBonusAmountOverride: 0,
  baseCost: 4,
  value: 1,
  upgradeValue: 1,
  statModifiers: {BattlerStat.attack: 1},
  effect: IntoxicarOnAttackItemEffect(),
);

/// Accesorio verde ofensivo que aplica Quemadura al atacar.
const emberCharmItem = Item(
  id: ItemId.emberCharm,
  archetypeAffinities: _imparableAffinities,
  tags: _debuffQuemaduraTags,
  name: 'Amuleto de Ascuas',
  description: '+1 ATK. Accesorio ofensivo que prende fuego en cada impacto.',
  iconEmoji: '\u{1F525}',
  rarity: RarityTier.green,
  patternBonusAmountOverride: 0,
  baseCost: 4,
  value: 3,
  upgradeValue: 1,
  statModifiers: {BattlerStat.attack: 1},
  effect: QuemaduraOnAttackItemEffect(),
);

/// Accesorio verde defensivo contra Quemadura e Intoxicacion.
const chemicalFilterItem = Item(
  id: ItemId.chemicalFilter,
  archetypeAffinities: _velozInamovibleMercanteAffinities,
  tags: _debuffQuemaduraIntoxicacionTags,
  name: 'Filtro Quimico',
  description: '+1 Barrera. Reduce la Quemadura y la Intoxicacion que recibes.',
  iconEmoji: '\u{1F637}',
  rarity: RarityTier.green,
  patternBonusAmountOverride: 0,
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
  patternBonusAmountOverride: 0,
  baseCost: 4,
  value: 2,
  upgradeValue: 1,
  incomePerValueUnit: 1,
  effect: BillingModuleItemEffect(),
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
  patternBonusAmountOverride: 0,
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
  archetypeAffinities: _generalAffinities,
  tags: _vidaBarreraTags,
  name: 'Funda Aislante',
  description: '+2 HP y +1 Barrera mientras este equipada.',
  iconEmoji: '\u{1F9BA}',
  rarity: RarityTier.green,
  patternBonusAmountOverride: 0,
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
      '+2 ATK. Al usarse, una vez por turno, infliges dano directo extra y te aplicas Quemadura.',
  iconEmoji: '\u{1F529}',
  rarity: RarityTier.green,
  patternBonusAmountOverride: 0,
  baseCost: 4,
  value: 2,
  upgradeValue: 1,
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
  baseCost: 4,
  value: 2,
  upgradeValue: 2,
  statModifiers: {BattlerStat.barrier: 2},
  upgradeStatModifiers: {BattlerStat.barrier: 2},
);

/// Arma verde orientada a abrir ventanas de daño de forma estable.
const serratedEdgeItem = Item(
  id: ItemId.serratedEdge,
  archetypeAffinities: _velozImparableAffinities,
  tags: _ataqueDebuffTags,
  name: 'Sierra Dentada',
  description: '+1 ATK. Al usarse: acumula Fragilidad en el enemigo.',
  iconEmoji: '\u2692',
  rarity: RarityTier.green,
  patternBonusAmountOverride: 0,
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
  archetypeAffinities: _inamovibleMercanteAffinities,
  tags: _barreraBuffTags,
  name: 'Bobina de Contencion',
  description: '+1 Barrera. Al usarse, recuperas 1 de Barrera.',
  iconEmoji: '\u26A1',
  rarity: RarityTier.green,
  patternBonusAmountOverride: 0,
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
  archetypeAffinities: _imparableAffinities,
  tags: _ataqueBuffTags,
  name: 'Turbina Termica',
  description: '+1 ATK. Al recibir Quemadura, ganas Potencia.',
  iconEmoji: '\u{1F321}',
  rarity: RarityTier.green,
  patternBonusAmountOverride: 0,
  baseCost: 4,
  value: 10,
  upgradeValue: 1,
  statModifiers: {BattlerStat.attack: 1},
  effect: ThermalTurbineItemEffect(),
);

/// Accesorio verde que convierte las recargas de Barrera en Resonancia.
const nucleoPiezoelectricoItem = Item(
  id: ItemId.nucleoPiezoelectrico,
  archetypeAffinities: _inamovibleAffinities,
  tags: _resonanciaBarreraBuffTags,
  name: 'Nucleo Piezoelectrico',
  description:
      '+2 Barrera. La primera vez cada turno que ganas Barrera, ganas Resonancia.',
  iconEmoji: '\u{1F50A}',
  rarity: RarityTier.green,
  patternBonusAmountOverride: 0,
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
  archetypeAffinities: _inamovibleImparableAffinities,
  tags: _resonanciaAtaqueBarreraTags,
  name: 'Descarga Resonante',
  description:
      '+1 ATK. Al usarse, consume toda tu Resonancia para infligir dano directo.',
  iconEmoji: '\u{1F4AB}',
  rarity: RarityTier.green,
  patternBonusAmountOverride: 0,
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
  patternBonusAmountOverride: 0,
  baseCost: 4,
  value: 1,
  upgradeValue: 1,
  statModifiers: {BattlerStat.attack: 1},
  upgradeStatModifiers: {BattlerStat.attack: 1},
  effect: ToxicScalpelItemEffect(),
);

// Blue

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
  patternBonusAmountOverride: 0,
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
  archetypeAffinities: _imparableAffinities,
  tags: _desafioAtaqueBuffTags,
  name: 'Seguro Roto',
  description:
      'Cuando un Desafio provoca contraataque, mejora tus siguientes Desafios.',
  iconEmoji: '\u{1F4A5}',
  rarity: RarityTier.blue,
  baseCost: 6,
  value: 1,
  upgradeValue: 1,
  effect: SeguroRotoItemEffect(),
);

/// Accesorio azul que cura al portar mercancia ajena sin equipar.
const muestrarioContrabandoItem = Item(
  id: ItemId.muestrarioContrabando,
  archetypeAffinities: _mercanteAffinities,
  tags: _economiaVidaTags,
  name: 'Muestrario de Contrabando',
  description:
      'Al usarse, te curas por cada item de otro arquetipo en tu inventario.',
  iconEmoji: '\u{1F9F3}',
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

/// Arma azul que convierte tu defensa en un boost explosivo para el siguiente golpe.
const magnetiCHammerItem = Item(
  id: ItemId.magnetiCHammer,
  archetypeAffinities: _inamovibleAffinities,
  tags: _ataqueBarreraTags,
  name: 'M(agneti)C Hammer',
  description:
      'Al usarse, ganas Potencia para el siguiente golpe igual a tu Barrera total actual.',
  iconEmoji: '\u{1F528}',
  rarity: RarityTier.blue,
  patternBonusAmountOverride: 0,
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
  patternBonusAmountOverride: 0,
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

/// Soporte azul reactivo que devuelve Quemadura al recibir golpes.
const reactiveCasingItem = Item(
  id: ItemId.reactiveCasing,
  archetypeAffinities: _imparableAffinities,
  tags: _debuffQuemaduraTags,
  name: 'Coraza Reactiva',
  description: 'Blindaje inestable que devuelve fuego al agresor.',
  iconEmoji: '\u{1F9F1}',
  rarity: RarityTier.blue,
  patternBonusAmountOverride: 0,
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
  archetypeAffinities: _velozAffinities,
  tags: _ataqueBarreraDebuffTags,
  name: 'Kunai Ancho',
  description: 'Al usarse, si el enemigo tiene un debuff, recuperas Barrera.',
  iconEmoji: '\u{1F52A}',
  rarity: RarityTier.blue,
  patternBonusAmountOverride: 0,
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
  archetypeAffinities: _velozImparableAffinities,
  tags: _ataqueDebuffTags,
  name: 'Carabina de Pulsos',
  description: 'Al usarse: aplica Conmocion al enemigo.',
  iconEmoji: '\u{1F52B}',
  rarity: RarityTier.blue,
  patternBonusAmountOverride: 0,
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
  archetypeAffinities: _inamovibleMercanteAffinities,
  tags: _barreraBuffTags,
  name: 'Velo de Fase',
  description: 'Al inicio de tu turno, recuperas 2 de Barrera.',
  iconEmoji: '\u{1F300}',
  rarity: RarityTier.blue,
  patternBonusAmountOverride: 0,
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

/// Blindaje azul de barrera plana alta.
const platedJacketItem = Item(
  id: ItemId.platedJacket,
  archetypeAffinities: _generalAffinities,
  tags: _barreraTags,
  name: 'Chaqueta Blindada',
  description: '+4 HP y +3 Barrera mientras este equipada.',
  iconEmoji: '\u{1F9E5}',
  rarity: RarityTier.green,
  patternBonusAmountOverride: 0,
  baseCost: 4,
  value: 4,
  upgradeValue: 4,
  statModifiers: {BattlerStat.health: 4, BattlerStat.barrier: 3},
  upgradeStatModifiers: {BattlerStat.health: 4, BattlerStat.barrier: 3},
);

/// Accesorio azul que descarga la barrera ganada cuando se rompe.
const contingencySealItem = Item(
  id: ItemId.contingencySeal,
  archetypeAffinities: _inamovibleMercanteAffinities,
  tags: _barreraBuffTags,
  name: 'Sello de Contingencia',
  description:
      'Cuando se rompe tu Barrera, haces dano al agresor igual a la Barrera ganada en la ultima ronda de este combate.',
  iconEmoji: '\u2726',
  rarity: RarityTier.blue,
  baseCost: 6,
  value: 1,
  upgradeValue: 1,
  effect: ContingencySealItemEffect(),
);

/// Accesorio azul que transforma impactos sobre Barrera en carga acumulada.
const placasCompresionItem = Item(
  id: ItemId.placasCompresion,
  archetypeAffinities: _inamovibleAffinities,
  tags: _resonanciaBarreraBuffTags,
  name: 'Placas de Compresion',
  description:
      'Cuando recibes dano a Barrera, ganas Resonancia por la Barrera perdida.',
  iconEmoji: '\u{1F4BF}',
  rarity: RarityTier.blue,
  patternBonusAmountOverride: 0,
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
  archetypeAffinities: _velozAffinities,
  tags: _ataqueDebuffTags,
  name: 'Canon de Conmocion',
  description:
      'Al usarse: aplica Conmocion. Si el objetivo ya la tenia, pierde 1 de Barrera.',
  iconEmoji: '\u{1F4E1}',
  rarity: RarityTier.blue,
  patternBonusAmountOverride: 0,
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
  archetypeAffinities: _inamovibleMercanteAffinities,
  tags: _barreraBuffTags,
  name: 'Bastidor de Respuesta',
  description:
      'Al final de tu turno, si no has recibido daño, recuperas 2 de Barrera.',
  iconEmoji: '\u{1F5BC}',
  rarity: RarityTier.blue,
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
  patternBonusAmountOverride: 0,
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
  archetypeAffinities: _imparableAffinities,
  tags: _desafioAtaqueBuffTags,
  name: 'Acelerador de Reto',
  description:
      'Sobrevivir contraataques provocados por Desafio mejora tus siguientes Desafios.',
  iconEmoji: '\u{1F3CE}',
  rarity: RarityTier.purple,
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
  archetypeAffinities: _mercanteAffinities,
  tags: _economiaAtaqueTags,
  name: 'Ropera Unida',
  description: 'Otorga un bonus de ATK segun tus items de otro arquetipo.',
  iconEmoji: '\u{1F455}',
  rarity: RarityTier.purple,
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
  archetypeAffinities: _imparableAffinities,
  tags: _ataqueVidaTags,
  name: 'Ultima Marcha',
  description:
      '+1 ATK. Al usarse, una vez por turno, infliges dano extra segun la vida que te falta.',
  iconEmoji: '\u{1FA78}',
  rarity: RarityTier.purple,
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
  archetypeAffinities: _inamovibleMercanteAffinities,
  tags: _barreraBuffTags,
  name: 'Placa de Emergencia',
  description:
      '+2 Barrera. Las primeras 2 veces en combate que empieces tu turno por debajo de la mitad de vida, bloqueas sin gastar tu turno.',
  iconEmoji: '\u{1F6A7}',
  rarity: RarityTier.purple,
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

/// Arma morada que convierte cada impacto en reserva de ataque acumulable.
const impulseSpearItem = Item(
  id: ItemId.impulseSpear,
  archetypeAffinities: _imparableAffinities,
  tags: _ataqueBuffTags,
  name: 'Lanza de Impulso',
  description: 'Al usarse: ganas Reserva de Inercia: ATK.',
  iconEmoji: '\u{1F531}',
  rarity: RarityTier.purple,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(_adjN, EntityTag.arma, _adjAttack, 2),
    OperativePatternAdjacencyBonus.match(
        _adjE, EntityTag.ataque, _adjAttack, 2),
    OperativePatternAdjacencyBonus.match(_adjS, EntityTag.buff, _adjAttack, 2),
    OperativePatternAdjacencyBonus.match(_adjW, EntityTag.arma, _adjAttack, 2),
  ],
  baseCost: 8,
  value: 2,
  upgradeValue: 1,
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
      '+2 Barrera. Al recibir daño: ganas Reserva de Inercia: Barrera.',
  iconEmoji: '\u{1FAA2}',
  rarity: RarityTier.purple,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(
        _adjE, EntityTag.barrera, _adjBarrier, 2),
    OperativePatternAdjacencyBonus.match(_adjS, EntityTag.buff, _adjBarrier, 2),
    OperativePatternAdjacencyBonus.match(
        _adjW, EntityTag.barrera, _adjBarrier, 2),
    OperativePatternAdjacencyBonus.match(_adjN, EntityTag.buff, _adjBarrier, 2),
  ],
  baseCost: 8,
  value: 2,
  upgradeValue: 1,
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
  description: 'Al recibir daño: aplica Conmocion al agresor.',
  iconEmoji: '\u{1F48E}',
  rarity: RarityTier.purple,
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
  archetypeAffinities: _generalAffinities,
  tags: _barreraTags,
  name: 'Capa de Medianoche',
  description: '+5 Barrera mientras este equipada.',
  iconEmoji: '\u{1F576}',
  rarity: RarityTier.purple,
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
  archetypeAffinities: _imparableAffinities,
  tags: _debuffQuemaduraTags,
  name: 'Horno Portatil',
  description: 'Amplifica tus Quemaduras, pero siempre deja rescoldos.',
  iconEmoji: '\u2668',
  rarity: RarityTier.purple,
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

/// Accesorio morado que convierte golpes recibidos en reserva defensiva.
const parasiticCapacitorItem = Item(
  id: ItemId.parasiticCapacitor,
  archetypeAffinities: _inamovibleMercanteAffinities,
  tags: _vidaTags,
  name: 'Capacitador Parasitario',
  description: 'Al recibir dano: ganas Reserva de Inercia: Barrera.',
  iconEmoji: '\u{1FAAB}',
  rarity: RarityTier.purple,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(_adjE, EntityTag.vida, _adjBarrier, 2),
    OperativePatternAdjacencyBonus.match(
        _adjS, EntityTag.accesorio, _adjBarrier, 2),
    OperativePatternAdjacencyBonus.match(_adjW, EntityTag.vida, _adjBarrier, 2),
    OperativePatternAdjacencyBonus.match(
        _adjN, EntityTag.accesorio, _adjBarrier, 2),
  ],
  baseCost: 8,
  value: 5,
  upgradeValue: 5,
  effect: StatusItemEffect(
    kind: ItemStatusEffectKind.inerciaBarrera,
    trigger: ItemStatusEffectTrigger.receiveDamageOwner,
  ),
);

/// Accesorio morado oportunista que roba liquidez y la convierte en aguante.
const succionaCreditosItem = Item(
  id: ItemId.succionaCreditos,
  archetypeAffinities: _velozAffinities,
  tags: _economiaBarreraDebuffTags,
  name: 'SuccionaCreditos',
  description:
      'Al usarse, una vez por turno, si el objetivo tiene un debuff, ganas creditos y recuperas Barrera.',
  iconEmoji: '\u{1F4B8}',
  rarity: RarityTier.purple,
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
  archetypeAffinities: _generalAffinities,
  tags: _ataqueVidaTags,
  name: 'Inyector del Vacio',
  description: '+4 ATK y +8 HP mientras este equipado.',
  iconEmoji: '\u{1F573}',
  rarity: RarityTier.purple,
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
  archetypeAffinities: _inamovibleAffinities,
  tags: _resonanciaBarreraBuffTags,
  name: 'Torre de Retorno',
  description:
      'Al usarse, conviertes parte de tu Barrera actual en Resonancia duplicada.',
  iconEmoji: '\u{1F5FC}',
  rarity: RarityTier.purple,
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

/// Accesorio morado que proyecta Resonancia como dano sin consumirla.
const prismaDeEcoItem = Item(
  id: ItemId.prismaDeEco,
  archetypeAffinities: _inamovibleAffinities,
  tags: _resonanciaAtaqueBarreraTags,
  name: 'Prisma de Eco',
  description:
      'Una vez por turno, al usarse, infliges dano directo igual a la mitad de tu Resonancia actual.',
  iconEmoji: '\u{1FA9E}',
  rarity: RarityTier.purple,
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
  archetypeAffinities: _imparableAffinities,
  tags: _ataqueBarreraBuffTags,
  name: 'Ancla de Sobrecarga',
  description: 'Al usarse, si tienes Calentando, recuperas Barrera.',
  iconEmoji: '\u2693',
  rarity: RarityTier.purple,
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
  archetypeAffinities: _velozInamovibleMercanteAffinities,
  tags: _barreraDebuffTags,
  name: 'Lente de Rebote',
  description:
      '+1 Barrera. La primera vez que recibes daño cada turno, acumulas Fragilidad en el agresor.',
  iconEmoji: '\u{1F52E}',
  rarity: RarityTier.purple,
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

/// Arma amarilla que remata tras recibir el castigo de Desafio.
const ultimaPalabraItem = Item(
  id: ItemId.ultimaPalabra,
  archetypeAffinities: _imparableAffinities,
  tags: _desafioAtaqueBuffTags,
  name: 'Ultima Palabra',
  description:
      'Una vez por turno, tras recibir un contraataque de Desafio, atacas.',
  iconEmoji: '\u{1F5E1}',
  rarity: RarityTier.yellow,
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
  archetypeAffinities: _inamovibleAffinities,
  tags: _barreraDebuffTags,
  name: 'Ceramica Purgadora',
  description:
      '+3 Barrera. Al inicio de tu turno, reduces turnos de todos tus debuffs purgables.',
  iconEmoji: '\u{1F3FA}',
  rarity: RarityTier.yellow,
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
  archetypeAffinities: _imparableAffinities,
  tags: _ataqueBuffTags,
  name: 'Inyector de Sobrecarga',
  description:
      '+3 ATK. Al inicio del combate, ganas una gran carga de Calentando.',
  iconEmoji: '\u{1F489}',
  rarity: RarityTier.yellow,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(_adjW, EntityTag.arma, _adjAttack, 2),
    OperativePatternAdjacencyBonus.match(
        _adjN, EntityTag.ataque, _adjAttack, 2),
    OperativePatternAdjacencyBonus.match(_adjE, EntityTag.buff, _adjAttack, 2),
    OperativePatternAdjacencyBonus.match(_adjS, EntityTag.arma, _adjAttack, 2),
  ],
  baseCost: 10,
  value: 6,
  upgradeValue: 2,
  statModifiers: {BattlerStat.attack: 3},
  upgradeStatModifiers: {BattlerStat.attack: 1},
  effect: ThermalTurbineItemEffect(),
);

/// Armadura amarilla que garantiza una Inercia de alto valor si se pierde.
const vectorBulwarkItem = Item(
  id: ItemId.vectorBulwark,
  archetypeAffinities: _inamovibleImparableAffinities,
  tags: _ataqueBarreraBuffTags,
  name: 'Bastion Vectorial',
  description:
      '+3 Barrera. Al inicio de tu turno, si no lo tienes, ganas Inercia.',
  iconEmoji: '\u{1F9ED}',
  rarity: RarityTier.yellow,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(
        _adjN, EntityTag.ataque, _adjAttack, 2),
    OperativePatternAdjacencyBonus.match(
        _adjE, EntityTag.barrera, _adjBarrier, 2),
    OperativePatternAdjacencyBonus.match(_adjS, EntityTag.buff, _adjBarrier, 2),
    OperativePatternAdjacencyBonus.match(
        _adjW, EntityTag.ataque, _adjAttack, 2),
  ],
  baseCost: 10,
  value: 2,
  upgradeValue: 1,
  statModifiers: {BattlerStat.barrier: 3},
  upgradeStatModifiers: {BattlerStat.barrier: 1},
  effect: StatusItemEffect(
    kind: ItemStatusEffectKind.inercia,
    trigger: ItemStatusEffectTrigger.turnStartOwnerIfMissing,
  ),
);

/// Accesorio amarillo que devuelve Barrera cuando la Resonancia hace dano.
const canonContrapresionItem = Item(
  id: ItemId.canonContrapresion,
  archetypeAffinities: _inamovibleAffinities,
  tags: _resonanciaAtaqueBarreraTags,
  name: 'Canon de Contrapresion',
  description:
      '+2 Barrera. Cuando tu Resonancia inflige dano, ganas Barrera igual a la mitad del dano infligido.',
  iconEmoji: '\u{1F4E3}',
  rarity: RarityTier.yellow,
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
  archetypeAffinities: _generalAffinities,
  tags: _ataqueTags,
  name: 'Filo Solar',
  description: '+10 ATK mientras este equipado.',
  iconEmoji: '\u{1F5E1}',
  rarity: RarityTier.yellow,
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
  archetypeAffinities: _generalAffinities,
  tags: _vidaTags,
  name: 'Amuleto del Alba',
  description: '+20 HP mientras este equipado.',
  iconEmoji: '\u2600',
  rarity: RarityTier.yellow,
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
  archetypeAffinities: _generalAffinities,
  tags: _vidaTags,
  name: 'Caja Negra del Operativo',
  description:
      '+8 HP. Failsafe de emergencia que rehusa dejar caer la unidad a la primera.',
  iconEmoji: '\u{1F4E6}',
  rarity: RarityTier.yellow,
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

/// Accesorio amarillo que duplica el rendimiento del motor de Inercia.
const inertiaCrownItem = Item(
  id: ItemId.inertiaCrown,
  archetypeAffinities: _imparableAffinities,
  tags: _ataqueBarreraBuffTags,
  name: 'Corona de Inercia',
  description:
      '+2 Barrera. Si tienes Inercia al inicio de tu turno, ganas ambas reservas de Inercia.',
  iconEmoji: '\u{1F451}',
  rarity: RarityTier.yellow,
  patternAdjacencyBonuses: [
    OperativePatternAdjacencyBonus.match(
        _adjN, EntityTag.ataque, _adjAttack, 2),
    OperativePatternAdjacencyBonus.match(
        _adjE, EntityTag.barrera, _adjBarrier, 2),
    OperativePatternAdjacencyBonus.match(_adjS, EntityTag.buff, _adjBarrier, 2),
    OperativePatternAdjacencyBonus.match(
        _adjW, EntityTag.accesorio, _adjBarrier, 2),
  ],
  baseCost: 10,
  value: 2,
  upgradeValue: 1,
  statModifiers: {BattlerStat.barrier: 2},
  effect: InertiaCrownItemEffect(),
);

/// Arma amarilla de remate que convierte la Quemadura acumulada en daño inmediato.
const sunExecutionBladeItem = Item(
  id: ItemId.sunExecutionBlade,
  archetypeAffinities: _imparableAffinities,
  tags: _ataqueDebuffQuemaduraTags,
  name: 'Hoja de Ejecucion Solar',
  description:
      '+4 ATK. Al usarse, si el objetivo tiene Quemadura, la consume y anade dano directo extra.',
  iconEmoji: '\u{1F506}',
  rarity: RarityTier.yellow,
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
  cyberWhipsItem,
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
  heridaCarbonizadaItem,
  guanteProvocacionItem,
  contratoDolorosoItem,
  yunqueCardiacoItem,
  revanchadoraItem,
  embudoMejorasItem,
  arnesTacticoItem,
  mandibultimatumItem,
  estandarteUltimoSolItem,
  motorMartirioItem,
  visorAperturaItem,
  seguroRotoItem,
  aceleradorRetoItem,
  ultimaPalabraItem,
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
