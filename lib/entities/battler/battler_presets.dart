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

/// Enemigo final amarillo con el kit mas completo del roster actual.
const yellowEnemyBattler = Battler(
  name: 'SOLAR EXECUTOR',
  health: 135,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 135,
    BattlerStat.attack: 13,
    BattlerStat.barrier: 8,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: [ghostMeshAbility],
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
