import '../_imports.dart';

/// Enemigo gris basico usado como encuentro de entrada y referencia de dificultad minima.
const grayEnemyBattler = Battler(
  name: 'SCRAP MITE',
  health: 44,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 44,
    BattlerStat.attack: 6,
    BattlerStat.barrier: 2,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  equippedItems: [woodenStickItem],
);

/// Variante gris evasiva que intercambia dano por mas impactos.
const shadeSkipperEnemyBattler = Battler(
  name: 'SHADE SKIPPER',
  health: 38,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 38,
    BattlerStat.attack: 7,
    BattlerStat.barrier: 2,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  equippedItems: [sunglassesItem],
);

/// Variante gris ofensiva que castiga a objetivos sin buffs.
const lensRuntEnemyBattler = Battler(
  name: 'LENS RUNT',
  health: 42,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 42,
    BattlerStat.attack: 6,
    BattlerStat.barrier: 2,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  equippedItems: [impactGlovesItem],
);

/// Variante gris defensiva apoyada en una pasiva de mitigar dano.
const phaseMoteEnemyBattler = Battler(
  name: 'PHASE MOTE',
  health: 40,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 40,
    BattlerStat.attack: 6,
    BattlerStat.barrier: 3,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: [ghostMeshAbility],
);

/// -------------------------------
/// SETS DE COMBATE (GRIS)
/// -------------------------------
const _grayChiselSetItems = <Item>[
  stunBatonItem,
  rescueBladeItem,
];
const _grayChiselSetAbilities = <BattlerAbility>[];

const _grayStaticSetItems = <Item>[
  emergencyPlatingItem,
  shockMeshItem,
];
const _grayStaticSetAbilities = <BattlerAbility>[];

const _grayHushSetItems = <Item>[
  pocketJammerItem,
  impactGlovesItem,
];
const _grayHushSetAbilities = <BattlerAbility>[];

const _grayLeechSetItems = <Item>[
  mamparaPortatilItem,
  botiquinCompactoItem,
];
const _grayLeechSetAbilities = <BattlerAbility>[
  ghostMeshAbility,
];

/// Variante gris de control puntual con remates y autosustain.
const chiselImpEnemyBattler = Battler(
  name: 'CHISEL IMP',
  health: 43,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 43,
    BattlerStat.attack: 7,
    BattlerStat.barrier: 2,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: _grayChiselSetAbilities,
  equippedItems: _grayChiselSetItems,
);

/// Variante gris defensiva que castiga al agresor cuando entra en contacto.
const staticTickEnemyBattler = Battler(
  name: 'STATIC TICK',
  health: 41,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 41,
    BattlerStat.attack: 6,
    BattlerStat.barrier: 3,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: _grayStaticSetAbilities,
  equippedItems: _grayStaticSetItems,
);

/// Variante gris agresiva que presiona a rivales sin buffs.
const scrapHushEnemyBattler = Battler(
  name: 'SCRAP HUSH',
  health: 40,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 40,
    BattlerStat.attack: 7,
    BattlerStat.barrier: 2,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: _grayHushSetAbilities,
  equippedItems: _grayHushSetItems,
);

/// Variante gris de desgaste que se mantiene mientras limpia sus debuffs.
const rustLeechEnemyBattler = Battler(
  name: 'RUST LEECH',
  health: 45,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 45,
    BattlerStat.attack: 6,
    BattlerStat.barrier: 3,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: _grayLeechSetAbilities,
  equippedItems: _grayLeechSetItems,
);

/// Enemigo verde estandar con postura defensiva para la capa media inicial.
const greenEnemyBattler = Battler(
  name: 'HOLLOW DRONE',
  health: 62,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 62,
    BattlerStat.attack: 7,
    BattlerStat.barrier: 4,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: [ghostMeshAbility],
  equippedItems: [guardShieldItem],
);

/// Variante verde toxica que combina dano base con castigo a debuffs.
const venomStitchEnemyBattler = Battler(
  name: 'VENOM STITCH',
  health: 58,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 58,
    BattlerStat.attack: 8,
    BattlerStat.barrier: 3,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: [weaknessHunterAbility],
  equippedItems: [cyberWhipsItem],
);

/// Variante verde de aguante que regenera mientras sostiene la linea.
const patchBulwarkEnemyBattler = Battler(
  name: 'PATCH BULWARK',
  health: 67,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 67,
    BattlerStat.attack: 6,
    BattlerStat.barrier: 4,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  equippedItems: [
    shieldItem,
    bulwarkAmuletItem,
  ],
);

/// Variante verde de presion temprana centrada en quemar al objetivo.
const cinderClawEnemyBattler = Battler(
  name: 'CINDER CLAW',
  health: 60,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 60,
    BattlerStat.attack: 8,
    BattlerStat.barrier: 3,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  equippedItems: [
    ironSwordItem,
    emberCharmItem,
  ],
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
  inyeccionCorrosivaAbility,
];

const _greenSpringSetItems = <Item>[
  containmentCoilItem,
  deflectiveCapacitorItem,
];
const _greenSpringSetAbilities = <BattlerAbility>[
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
  limpiezaCacheAbility,
];

/// Variante verde de debuffs en cadena con castigo incremental.
const toxicLacerEnemyBattler = Battler(
  name: 'TOXIC LACER',
  health: 61,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 61,
    BattlerStat.attack: 8,
    BattlerStat.barrier: 3,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: _greenToxicSetAbilities,
  equippedItems: _greenToxicSetItems,
);

/// Variante verde de aguante progresivo con doble motor de barrera.
const bastionSpringEnemyBattler = Battler(
  name: 'BASTION SPRING',
  health: 66,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 66,
    BattlerStat.attack: 6,
    BattlerStat.barrier: 4,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: _greenSpringSetAbilities,
  equippedItems: _greenSpringSetItems,
);

/// Variante verde de presion ofensiva que escala por calor.
const furnaceFangEnemyBattler = Battler(
  name: 'FURNACE FANG',
  health: 60,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 60,
    BattlerStat.attack: 8,
    BattlerStat.barrier: 3,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: _greenFurnaceSetAbilities,
  equippedItems: _greenFurnaceSetItems,
);

/// Variante verde equilibrada con mezcla de sostén y daño estable.
const shieldmendBruteEnemyBattler = Battler(
  name: 'SHIELDMEND BRUTE',
  health: 64,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 64,
    BattlerStat.attack: 7,
    BattlerStat.barrier: 4,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: _greenShieldmendSetAbilities,
  equippedItems: _greenShieldmendSetItems,
);

/// Enemigo azul que mezcla barrera y dano para el tramo medio de la run.
const blueEnemyBattler = Battler(
  name: 'RIFT HOUND',
  health: 82,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 82,
    BattlerStat.attack: 9,
    BattlerStat.barrier: 6,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: [weaknessHunterAbility],
  equippedItems: [
    ironSwordItem,
    platedJacketItem,
  ],
);

/// Variante azul toxica que escala mejor cuando el veneno ya esta activo.
const toxicReaverEnemyBattler = Battler(
  name: 'TOXIC REAVER',
  health: 79,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 79,
    BattlerStat.attack: 9,
    BattlerStat.barrier: 5,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: [weaknessHunterAbility],
  equippedItems: [
    cyberWhipsItem,
    toxicCatalystItem,
  ],
);

/// Variante azul defensiva que se cura, refleja fuego y resiste mejor el burst.
const phaseBastionEnemyBattler = Battler(
  name: 'PHASE BASTION',
  health: 89,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 89,
    BattlerStat.attack: 7,
    BattlerStat.barrier: 6,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: [ghostMeshAbility],
  equippedItems: [
    shieldItem,
    reactiveCasingItem,
  ],
);

/// Variante azul agresiva que abre el combate con un golpe potenciado y Quemadura.
const cinderRamEnemyBattler = Battler(
  name: 'CINDER RAM',
  health: 80,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 80,
    BattlerStat.attack: 10,
    BattlerStat.barrier: 5,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: [venousOverloadAbility],
  equippedItems: [
    ironSwordItem,
    emberCharmItem,
  ],
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
  jaulaSenalAbility,
];

const _blueMagnetSetItems = <Item>[
  magnetiCHammerItem,
  platedJacketItem,
];
const _blueMagnetSetAbilities = <BattlerAbility>[
  criticalScannerAbility,
  escanerRupturaAbility,
  sustraccionAbility,
];

const _blueVeninSetItems = <Item>[
  kunaiAnchoItem,
  toxicScalpelItem,
];
const _blueVeninSetAbilities = <BattlerAbility>[
  weaknessHunterAbility,
  reenrutadoInversoAbility,
];

const _blueAshenSetItems = <Item>[
  responseFrameItem,
  reactiveCasingItem,
];
const _blueAshenSetAbilities = <BattlerAbility>[
  ghostMeshAbility,
];

/// Variante azul de control bilateral basada en Interferencia.
const jammerHowlerEnemyBattler = Battler(
  name: 'JAMMER HOWLER',
  health: 83,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 83,
    BattlerStat.attack: 9,
    BattlerStat.barrier: 5,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: _blueJammerSetAbilities,
  equippedItems: _blueJammerSetItems,
);

/// Variante azul de burst que convierte barrera en daño puntual.
const magnetMaulerEnemyBattler = Battler(
  name: 'MAGNET MAULER',
  health: 86,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 86,
    BattlerStat.attack: 9,
    BattlerStat.barrier: 6,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: _blueMagnetSetAbilities,
  equippedItems: _blueMagnetSetItems,
);

/// Variante azul de ejecución sobre objetivos ya debilitados.
const veninRunnerEnemyBattler = Battler(
  name: 'VENIN RUNNER',
  health: 81,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 81,
    BattlerStat.attack: 10,
    BattlerStat.barrier: 5,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: _blueVeninSetAbilities,
  equippedItems: _blueVeninSetItems,
);

/// Variante azul de tempo defensivo con retorno de quemadura.
const ashenFrameEnemyBattler = Battler(
  name: 'ASHEN FRAME',
  health: 88,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 88,
    BattlerStat.attack: 8,
    BattlerStat.barrier: 6,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: _blueAshenSetAbilities,
  equippedItems: _blueAshenSetItems,
);

/// Enemigo morado pensado para la noche, con kit completo de aguante y castigo.
const purpleEnemyBattler = Battler(
  name: 'NULL WARDEN',
  health: 103,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 103,
    BattlerStat.attack: 11,
    BattlerStat.barrier: 7,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: [
    weaknessHunterAbility,
    ghostMeshAbility,
  ],
  equippedItems: [
    ironSwordItem,
    voidInjectorItem,
  ],
);

/// Variante morada toxica con mitigacion parcial contra debuffs rivales.
const venomOracleEnemyBattler = Battler(
  name: 'VENOM ORACLE',
  health: 100,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 100,
    BattlerStat.attack: 10,
    BattlerStat.barrier: 7,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: [weaknessHunterAbility],
  equippedItems: [
    cyberWhipsItem,
    toxicCatalystItem,
    chemicalFilterItem,
  ],
);

/// Variante morada de fuego sostenido que abre fuerte y escala sus Quemaduras.
const cinderExecutionerEnemyBattler = Battler(
  name: 'CINDER EXECUTIONER',
  health: 106,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 106,
    BattlerStat.attack: 11,
    BattlerStat.barrier: 6,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: [venousOverloadAbility],
  equippedItems: [
    portableOvenItem,
    emberCharmItem,
    ironSwordItem,
  ],
);

/// Variante morada tecnica con barrera, drenaje y un primer golpe preparado.
const phaseDredgerEnemyBattler = Battler(
  name: 'PHASE DREDGER',
  health: 101,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 101,
    BattlerStat.attack: 10,
    BattlerStat.barrier: 8,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: [
    ghostMeshAbility,
    criticalScannerAbility,
  ],
  equippedItems: [
    midnightCloakItem,
    parasiticCapacitorItem,
  ],
);

/// -------------------------------
/// SETS DE COMBATE (MORADO)
/// -------------------------------
const _purpleHarpoonerSetItems = <Item>[
  impulseSpearItem,
  inertialCoreItem,
  reboundHarnessItem,
];
const _purpleHarpoonerSetAbilities = <BattlerAbility>[
  criticalScannerAbility,
  nucleoParasitarioAbility,
];

const _purpleOvenSetItems = <Item>[
  portableOvenItem,
  emberCharmItem,
  ultimaMarchaItem,
];
const _purpleOvenSetAbilities = <BattlerAbility>[
  venousOverloadAbility,
  hemostasiaAgresivaAbility,
  espejoDolorAbility,
];

const _purpleVoidSetItems = <Item>[
  voidInjectorItem,
  reboundLensItem,
  parasiticCapacitorItem,
];
const _purpleVoidSetAbilities = <BattlerAbility>[
  criticalScannerAbility,
  protocoloUsurpacionAbility,
];

const _purpleSmugglerSetItems = <Item>[
  midnightCloakItem,
  succionaCreditosItem,
  interferenceCannonItem,
];
const _purpleSmugglerSetAbilities = <BattlerAbility>[
  weaknessHunterAbility,
  ghostMeshAbility,
  mallaReboteAbility,
];

/// Variante morada de inercia que acumula reservas en ambos ejes.
const inertiaHarpoonerEnemyBattler = Battler(
  name: 'INERTIA HARPOONER',
  health: 103,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 103,
    BattlerStat.attack: 11,
    BattlerStat.barrier: 7,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: _purpleHarpoonerSetAbilities,
  equippedItems: _purpleHarpoonerSetItems,
);

/// Variante morada de fuego extremo con remate por vida faltante.
const ovenHarrowerEnemyBattler = Battler(
  name: 'OVEN HARROWER',
  health: 105,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 105,
    BattlerStat.attack: 11,
    BattlerStat.barrier: 6,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: _purpleOvenSetAbilities,
  equippedItems: _purpleOvenSetItems,
);

/// Variante morada híbrida de presión estadística y castigo reactivo.
const voidLeecherEnemyBattler = Battler(
  name: 'VOID LEECHER',
  health: 102,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 102,
    BattlerStat.attack: 10,
    BattlerStat.barrier: 8,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: _purpleVoidSetAbilities,
  equippedItems: _purpleVoidSetItems,
);

/// Variante morada de control sostenido con economía táctica y muro frontal.
const gloomSmugglerEnemyBattler = Battler(
  name: 'GLOOM SMUGGLER',
  health: 104,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 104,
    BattlerStat.attack: 10,
    BattlerStat.barrier: 7,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: _purpleSmugglerSetAbilities,
  equippedItems: _purpleSmugglerSetItems,
);

/// Enemigo final amarillo con el kit mas completo del roster actual.
const yellowEnemyBattler = Battler(
  name: 'SOLAR EXECUTOR',
  health: 108,
  money: 0,
  income: 0,
  equipmentCapacity: 4,
  baseStats: {
    BattlerStat.health: 108,
    BattlerStat.attack: 10,
    BattlerStat.barrier: 6,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: [
    ghostMeshAbility,
    pulsoRepLAbility,
    hemostasiaAgresivaAbility,
  ],
  equippedItems: [
    sunExecutionBladeItem,
    portableOvenItem,
    emberCharmItem,
    eclipseMantleItem,
  ],
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
    BattlerStat.attack: 10,
    BattlerStat.barrier: 5,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
);
