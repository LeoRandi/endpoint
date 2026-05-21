import '../_imports.dart';

const _patternTop = '0,1';
const _patternLeft = '-1,0';
const _patternCenter = '0,0';
const _patternRight = '1,0';
const _patternBottom = '0,-1';

/// Enemigo gris basico usado como encuentro de entrada y referencia de dificultad minima.
const grayEnemyBattler = Battler(
  name: 'SCRAP MITE',
  health: 28,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 28,
    BattlerStat.attack: 3,
    BattlerStat.barrier: 1,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  equippedItems: [woodenStickItem],
  patternItemPointKeys: {
    'woodenStick': _patternCenter,
  },
);

/// Variante gris evasiva que intercambia daño por mas impactos.
const shadeSkipperEnemyBattler = Battler(
  name: 'SHADE SKIPPER',
  health: 24,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 24,
    BattlerStat.attack: 4,
    BattlerStat.barrier: 1,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  equippedItems: [sunglassesItem],
  patternItemPointKeys: {
    'sunglasses': _patternCenter,
  },
);

/// Variante gris ofensiva que castiga a objetivos sin buffs.
const lensRuntEnemyBattler = Battler(
  name: 'LENS RUNT',
  health: 27,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 27,
    BattlerStat.attack: 3,
    BattlerStat.barrier: 1,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  equippedItems: [impactGlovesItem],
  patternItemPointKeys: {
    'impactGloves': _patternCenter,
  },
);

/// Variante gris defensiva apoyada en una pasiva de mitigar daño.
const phaseMoteEnemyBattler = Battler(
  name: 'PHASE MOTE',
  health: 26,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 26,
    BattlerStat.attack: 3,
    BattlerStat.barrier: 2,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  equippedItems: [mamparaPortatilItem],
  patternItemPointKeys: {
    'mamparaPortatil': _patternCenter,
  },
);

/// -------------------------------
/// SETS DE COMBATE (GRIS)
/// -------------------------------
const _grayChiselSetItems = <Item>[
  stunBatonItem,
];
const _grayChiselSetAbilities = <BattlerAbility>[];

const _grayStaticSetItems = <Item>[
  shockMeshItem,
];
const _grayStaticSetAbilities = <BattlerAbility>[];

const _grayHushSetItems = <Item>[
  impactGlovesItem,
];
const _grayHushSetAbilities = <BattlerAbility>[];

const _grayLeechSetItems = <Item>[
  botiquinCompactoItem,
];
const _grayLeechSetAbilities = <BattlerAbility>[];

/// Variante gris de control puntual con remates y autosustain.
const chiselImpEnemyBattler = Battler(
  name: 'CHISEL IMP',
  health: 27,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 27,
    BattlerStat.attack: 4,
    BattlerStat.barrier: 1,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: _grayChiselSetAbilities,
  equippedItems: _grayChiselSetItems,
  patternItemPointKeys: {
    'stunBaton': _patternCenter,
  },
);

/// Variante gris defensiva que castiga al agresor cuando entra en contacto.
const staticTickEnemyBattler = Battler(
  name: 'STATIC TICK',
  health: 26,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 26,
    BattlerStat.attack: 3,
    BattlerStat.barrier: 2,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: _grayStaticSetAbilities,
  equippedItems: _grayStaticSetItems,
  patternItemPointKeys: {
    'shockMesh': _patternCenter,
  },
);

/// Variante gris agresiva que presiona a rivales sin buffs.
const scrapHushEnemyBattler = Battler(
  name: 'SCRAP HUSH',
  health: 26,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 26,
    BattlerStat.attack: 4,
    BattlerStat.barrier: 1,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: _grayHushSetAbilities,
  equippedItems: _grayHushSetItems,
  patternItemPointKeys: {
    'impactGloves': _patternCenter,
  },
);

/// Variante gris de desgaste que se mantiene mientras limpia sus debuffs.
const rustLeechEnemyBattler = Battler(
  name: 'RUST LEECH',
  health: 29,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 29,
    BattlerStat.attack: 3,
    BattlerStat.barrier: 2,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: _grayLeechSetAbilities,
  equippedItems: _grayLeechSetItems,
  patternItemPointKeys: {
    'botiquinCompacto': _patternCenter,
  },
);

/// Enemigo verde estandar con postura defensiva para la capa media inicial.
const greenEnemyBattler = Battler(
  name: 'HOLLOW DRONE',
  health: 43,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 43,
    BattlerStat.attack: 4,
    BattlerStat.barrier: 2,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: [ghostMeshAbility],
  equippedItems: [guardShieldItem],
  patternItemPointKeys: {
    'guardShield': _patternCenter,
  },
);

/// Variante verde toxica que combina daño base con castigo a debuffs.
const venomStitchEnemyBattler = Battler(
  name: 'VENOM STITCH',
  health: 39,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 39,
    BattlerStat.attack: 4,
    BattlerStat.barrier: 2,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: [weaknessHunterAbility],
  equippedItems: [cyberWhipsItem],
  patternItemPointKeys: {
    'cyberWhips': _patternCenter,
  },
);

/// Variante verde de aguante que regenera mientras sostiene la linea.
const patchBulwarkEnemyBattler = Battler(
  name: 'PATCH BULWARK',
  health: 47,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 47,
    BattlerStat.attack: 3,
    BattlerStat.barrier: 2,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  equippedItems: [
    shieldItem,
    bulwarkAmuletItem,
  ],
  patternItemPointKeys: {
    'shield': _patternCenter,
    'bulwarkAmulet': _patternTop,
  },
);

/// Variante verde de presion temprana centrada en quemar al objetivo.
const cinderClawEnemyBattler = Battler(
  name: 'CINDER CLAW',
  health: 41,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 41,
    BattlerStat.attack: 4,
    BattlerStat.barrier: 2,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  equippedItems: [
    ironSwordItem,
    emberCharmItem,
  ],
  patternItemPointKeys: {
    'ironSword': _patternCenter,
    'emberCharm': _patternRight,
  },
);

/// -------------------------------
/// SETS DE COMBATE (VERDE)
/// -------------------------------
const _greenToxicSetItems = <Item>[
  toxicScalpelItem,
  serratedEdgeItem,
];
const _greenToxicSetAbilities = <BattlerAbility>[
  weaknessHunterAbility,
];

const _bastionSpringSetItems = <Item>[
  containmentCoilItem,
  deflectiveCapacitorItem,
];
const _bastionSpringSetAbilities = <BattlerAbility>[
  ghostMeshAbility,
  pulsoRepLAbility,
];

const _greenFurnaceSetItems = <Item>[
  ironSwordItem,
  thermalTurbineItem,
];
const _greenFurnaceSetAbilities = <BattlerAbility>[];

const _greenShieldmendSetItems = <Item>[
  shieldItem,
  placaBisagraItem,
];
const _greenShieldmendSetAbilities = <BattlerAbility>[
  opresionTacticaAbility,
];

/// Variante verde de debuffs en cadena con castigo incremental.
const toxicLacerEnemyBattler = Battler(
  name: 'TOXIC LACER',
  health: 42,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 42,
    BattlerStat.attack: 4,
    BattlerStat.barrier: 2,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: _greenToxicSetAbilities,
  equippedItems: _greenToxicSetItems,
  patternItemPointKeys: {
    'toxicScalpel': _patternCenter,
    'serratedEdge': _patternRight,
  },
);

/// Variante morada de aguante progresivo con doble motor de barrera.
const bastionSpringEnemyBattler = Battler(
  name: 'BASTION SPRING',
  health: 41,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 41,
    BattlerStat.attack: 3,
    BattlerStat.barrier: 2,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: _bastionSpringSetAbilities,
  equippedItems: _bastionSpringSetItems,
  patternItemPointKeys: {
    'containmentCoil': _patternCenter,
    'deflectiveCapacitor': _patternTop,
  },
);

/// Variante verde de presion ofensiva que escala por calor.
const furnaceFangEnemyBattler = Battler(
  name: 'FURNACE FANG',
  health: 41,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 41,
    BattlerStat.attack: 4,
    BattlerStat.barrier: 2,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: _greenFurnaceSetAbilities,
  equippedItems: _greenFurnaceSetItems,
  patternItemPointKeys: {
    'ironSword': _patternCenter,
    'thermalTurbine': _patternTop,
  },
);

/// Variante verde equilibrada con mezcla de sostén y daño estable.
const shieldmendBruteEnemyBattler = Battler(
  name: 'SHIELDMEND BRUTE',
  health: 44,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 44,
    BattlerStat.attack: 4,
    BattlerStat.barrier: 2,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: _greenShieldmendSetAbilities,
  equippedItems: _greenShieldmendSetItems,
  patternItemPointKeys: {
    'shield': _patternCenter,
    'placaBisagra': _patternTop,
  },
);

/// Enemigo azul Imparable que fuerza intercambios con Desafio.
const blueEnemyBattler = Battler(
  name: 'RIFT HOUND',
  health: 63,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 63,
    BattlerStat.attack: 5,
    BattlerStat.barrier: 3,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: [mandatoColiseoAbility],
  equippedItems: [
    guanteProvocacionItem,
    visorAperturaItem,
    yunqueCardiacoItem,
  ],
  patternItemPointKeys: {
    'guanteProvocacion': _patternCenter,
    'visorApertura': _patternLeft,
    'yunqueCardiaco': _patternRight,
  },
);

/// Variante azul toxica que escala mejor cuando el veneno ya esta activo.
const toxicReaverEnemyBattler = Battler(
  name: 'TOXIC REAVER',
  health: 57,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 57,
    BattlerStat.attack: 5,
    BattlerStat.barrier: 3,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: [weaknessHunterAbility],
  equippedItems: [
    cyberWhipsItem,
    toxicCatalystItem,
  ],
  patternItemPointKeys: {
    'cyberWhips': _patternCenter,
    'toxicCatalyst': _patternRight,
  },
);

/// Variante azul defensiva que se cura, refleja fuego y resiste mejor el burst.
const phaseBastionEnemyBattler = Battler(
  name: 'PHASE BASTION',
  health: 64,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 64,
    BattlerStat.attack: 4,
    BattlerStat.barrier: 3,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: [ghostMeshAbility],
  equippedItems: [
    shieldItem,
    reactiveCasingItem,
  ],
  patternItemPointKeys: {
    'reactiveCasing': _patternCenter,
    'shield': _patternTop,
  },
);

/// Variante azul agresiva que abre el combate con un golpe potenciado y Quemadura.
const cinderRamEnemyBattler = Battler(
  name: 'CINDER RAM',
  health: 58,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 58,
    BattlerStat.attack: 5,
    BattlerStat.barrier: 3,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: [furiaHematicaAbility],
  equippedItems: [
    ironSwordItem,
    emberCharmItem,
  ],
  patternItemPointKeys: {
    'ironSword': _patternCenter,
    'emberCharm': _patternRight,
  },
);

/// -------------------------------
/// SETS DE COMBATE (AZUL)
/// -------------------------------
const _blueJammerSetItems = <Item>[
  interferenceCannonItem,
  silbatoMudoItem,
];
const _blueJammerSetAbilities = <BattlerAbility>[
  weaknessHunterAbility,
  escanerRupturaAbility,
];

const _blueMagnetSetItems = <Item>[
  magnetiCHammerItem,
  platedJacketItem,
];
const _blueMagnetSetAbilities = <BattlerAbility>[
  escanerRupturaAbility,
  masaCriticaAbility,
];

const _blueVeninSetItems = <Item>[
  kunaiAnchoItem,
  toxicScalpelItem,
];
const _blueVeninSetAbilities = <BattlerAbility>[
  weaknessHunterAbility,
  triageAutomaticoAbility,
];

const _blueAshenSetItems = <Item>[
  responseFrameItem,
  reactiveCasingItem,
];
const _blueAshenSetAbilities = <BattlerAbility>[
  ghostMeshAbility,
];

/// Variante azul de control bilateral basada en Conmocion.
const jammerHowlerEnemyBattler = Battler(
  name: 'JAMMER HOWLER',
  health: 59,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 59,
    BattlerStat.attack: 5,
    BattlerStat.barrier: 3,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: _blueJammerSetAbilities,
  equippedItems: _blueJammerSetItems,
  patternItemPointKeys: {
    'interferenceCannon': _patternCenter,
    'silbatoMudo': _patternTop,
  },
);

/// Variante azul de burst que convierte barrera en daño puntual.
const magnetMaulerEnemyBattler = Battler(
  name: 'MAGNET MAULER',
  health: 62,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 62,
    BattlerStat.attack: 5,
    BattlerStat.barrier: 3,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: _blueMagnetSetAbilities,
  equippedItems: _blueMagnetSetItems,
  patternItemPointKeys: {
    'magnetiCHammer': _patternCenter,
    'platedJacket': _patternTop,
  },
);

/// Variante azul de ejecución sobre objetivos ya debilitados.
const veninRunnerEnemyBattler = Battler(
  name: 'VENIN RUNNER',
  health: 59,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 59,
    BattlerStat.attack: 5,
    BattlerStat.barrier: 3,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: _blueVeninSetAbilities,
  equippedItems: _blueVeninSetItems,
  patternItemPointKeys: {
    'kunaiAncho': _patternCenter,
    'toxicScalpel': _patternLeft,
  },
);

/// Variante azul de tempo defensivo con retorno de quemadura.
const ashenFrameEnemyBattler = Battler(
  name: 'ASHEN FRAME',
  health: 63,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 63,
    BattlerStat.attack: 4,
    BattlerStat.barrier: 3,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: _blueAshenSetAbilities,
  equippedItems: _blueAshenSetItems,
  patternItemPointKeys: {
    'reactiveCasing': _patternCenter,
    'responseFrame': _patternTop,
  },
);

/// Enemigo morado pensado para la noche, con kit completo de aguante y castigo.
const purpleEnemyBattler = Battler(
  name: 'NULL WARDEN',
  health: 80,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 80,
    BattlerStat.attack: 6,
    BattlerStat.barrier: 4,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: [
    weaknessHunterAbility,
    ghostMeshAbility,
  ],
  equippedItems: [
    emergencyPlatingItem,
    contingencySealItem,
    reboundLensItem,
  ],
  patternItemPointKeys: {
    'emergencyPlating': _patternCenter,
    'contingencySeal': _patternTop,
    'reboundLens': _patternRight,
  },
);

/// Variante morada toxica con mitigacion parcial contra debuffs rivales.
const venomOracleEnemyBattler = Battler(
  name: 'VENOM ORACLE',
  health: 78,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 78,
    BattlerStat.attack: 5,
    BattlerStat.barrier: 4,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: [weaknessHunterAbility],
  equippedItems: [
    succionaCreditosItem,
    reboundLensItem,
    concussionPrismItem,
  ],
  patternItemPointKeys: {
    'succionaCreditos': _patternCenter,
    'reboundLens': _patternTop,
    'concussionPrism': _patternRight,
  },
);

/// Variante morada de fuego sostenido que abre fuerte y escala sus Quemaduras.
const cinderExecutionerEnemyBattler = Battler(
  name: 'CINDER EXECUTIONER',
  health: 83,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 83,
    BattlerStat.attack: 6,
    BattlerStat.barrier: 3,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: [
    furiaHematicaAbility,
    hornoSimetricoAbility,
  ],
  equippedItems: [
    ultimaMarchaItem,
    aceleradorRetoItem,
  ],
  patternItemPointKeys: {
    'ultimaMarcha': _patternCenter,
    'aceleradorReto': _patternRight,
  },
);

/// Variante morada tecnica con barrera, drenaje y un primer golpe preparado.
const phaseDredgerEnemyBattler = Battler(
  name: 'PHASE DREDGER',
  health: 79,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 79,
    BattlerStat.attack: 5,
    BattlerStat.barrier: 4,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: [
    ghostMeshAbility,
    escanerRupturaAbility,
  ],
  equippedItems: [
    torreRetornoItem,
    deflectiveCapacitorItem,
  ],
  patternItemPointKeys: {
    'torreRetorno': _patternCenter,
    'deflectiveCapacitor': _patternBottom,
  },
);

/// -------------------------------
/// SETS DE COMBATE (MORADO)
/// -------------------------------
const _purpleHarpoonerSetItems = <Item>[
  guanteProvocacionItem,
  visorAperturaItem,
  ultimaPalabraItem,
];
const _purpleHarpoonerSetAbilities = <BattlerAbility>[
  mandatoColiseoAbility,
  hemostasiaAgresivaAbility,
];

const _purpleOvenSetItems = <Item>[
  portableOvenItem,
  emberCharmItem,
  ultimaMarchaItem,
];
const _purpleOvenSetAbilities = <BattlerAbility>[
  furiaHematicaAbility,
  hemostasiaAgresivaAbility,
  mallaReboteAbility,
];

const _purpleVoidSetItems = <Item>[
  emergencyPlatingItem,
  reboundLensItem,
  contingencySealItem,
];
const _purpleVoidSetAbilities = <BattlerAbility>[
  escanerRupturaAbility,
  nucleoParasitarioAbility,
];

const _purpleSmugglerSetItems = <Item>[
  succionaCreditosItem,
  reboundLensItem,
  concussionPrismItem,
];
const _purpleSmugglerSetAbilities = <BattlerAbility>[
  weaknessHunterAbility,
  ghostMeshAbility,
  mallaReboteAbility,
];

/// Variante morada Imparable que encadena Desafio y contraataques.
const challengeHarpoonerEnemyBattler = Battler(
  name: 'CHALLENGE HARPOONER',
  health: 80,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 80,
    BattlerStat.attack: 6,
    BattlerStat.barrier: 4,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: _purpleHarpoonerSetAbilities,
  equippedItems: _purpleHarpoonerSetItems,
  patternItemPointKeys: {
    'ultimaPalabra': _patternCenter,
    'guanteProvocacion': _patternRight,
    'visorApertura': _patternTop,
  },
);

/// Variante morada de fuego extremo con remate por vida faltante.
const ovenHarrowerEnemyBattler = Battler(
  name: 'OVEN HARROWER',
  health: 82,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 82,
    BattlerStat.attack: 6,
    BattlerStat.barrier: 3,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: _purpleOvenSetAbilities,
  equippedItems: _purpleOvenSetItems,
  patternItemPointKeys: {
    'portableOven': _patternCenter,
    'emberCharm': _patternRight,
    'ultimaMarcha': _patternBottom,
  },
);

/// Variante morada híbrida de presión estadística y castigo reactivo.
const voidLeecherEnemyBattler = Battler(
  name: 'VOID LEECHER',
  health: 80,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 80,
    BattlerStat.attack: 5,
    BattlerStat.barrier: 4,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: _purpleVoidSetAbilities,
  equippedItems: _purpleVoidSetItems,
  patternItemPointKeys: {
    'emergencyPlating': _patternCenter,
    'reboundLens': _patternTop,
    'contingencySeal': _patternRight,
  },
);

/// Variante morada de control sostenido con economía táctica y muro frontal.
const gloomSmugglerEnemyBattler = Battler(
  name: 'GLOOM SMUGGLER',
  health: 81,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 81,
    BattlerStat.attack: 5,
    BattlerStat.barrier: 4,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: _purpleSmugglerSetAbilities,
  equippedItems: _purpleSmugglerSetItems,
  patternItemPointKeys: {
    'succionaCreditos': _patternCenter,
    'reboundLens': _patternTop,
    'concussionPrism': _patternRight,
  },
);

/// Enemigo final amarillo con el kit mas completo del roster actual.
const yellowEnemyBattler = Battler(
  name: 'SOLAR EXECUTOR',
  health: 104,
  money: 0,
  income: 0,
  equipmentCapacity: 5,
  baseStats: {
    BattlerStat.health: 104,
    BattlerStat.attack: 10,
    BattlerStat.barrier: 6,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: [
    copiaDeSeguridadAbility,
    mallaReboteAbility,
    hemostasiaAgresivaAbility,
  ],
  equippedItems: [
    sunExecutionBladeItem,
    portableOvenItem,
    ceramicaPurgadoraItem,
    canonContrapresionItem,
    reactiveCasingItem,
  ],
  patternItemPointKeys: {
    'sunExecutionBlade': _patternCenter,
    'portableOven': _patternTop,
    'ceramicaPurgadora': _patternLeft,
    'canonContrapresion': _patternBottom,
    'reactiveCasing': _patternRight,
  },
);

/// Alias del enemigo por defecto usado en previews y valores fallback.
const Battler defaultEnemyBattler = greenEnemyBattler;

/// Jugador base de la run antes de elegir arquetipo o conseguir equipo.
const defaultPlayerBattler = Battler(
  name: 'ENDPOINT UNIT',
  health: 45,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 45,
    BattlerStat.attack: 0,
    BattlerStat.barrier: 0,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
);
