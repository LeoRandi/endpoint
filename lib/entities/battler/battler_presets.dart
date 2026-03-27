import '../_imports.dart';

/// Enemigo gris basico usado como encuentro de entrada y referencia de dificultad minima.
const grayEnemyBattler = Battler(
  name: 'SCRAP MITE',
  health: 48,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 48,
    BattlerStat.attack: 6,
    BattlerStat.defense: 2,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  equippedItems: [woodenStickItem],
);

/// Enemigo verde estandar con postura defensiva para la capa media inicial.
const greenEnemyBattler = Battler(
  name: 'HOLLOW DRONE',
  health: 72,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 72,
    BattlerStat.attack: 8,
    BattlerStat.defense: 4,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: [],
  equippedItems: [guardShieldItem],
);

/// Enemigo azul que mezcla defensa y dano para el tramo medio de la run.
const blueEnemyBattler = Battler(
  name: 'RIFT HOUND',
  health: 96,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 96,
    BattlerStat.attack: 10,
    BattlerStat.defense: 6,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: [],
  equippedItems: [
    ironSwordItem,
    platedJacketItem,
  ],
);

/// Enemigo morado pensado para la noche, con mas vida y dos habilidades activas.
const purpleEnemyBattler = Battler(
  name: 'NULL WARDEN',
  health: 128,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 128,
    BattlerStat.attack: 13,
    BattlerStat.defense: 8,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: [],
  equippedItems: [
    ironSwordItem,
    voidInjectorItem,
  ],
);

/// Enemigo final amarillo con el kit mas completo del roster actual.
const yellowEnemyBattler = Battler(
  name: 'SOLAR EXECUTOR',
  health: 168,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 168,
    BattlerStat.attack: 16,
    BattlerStat.defense: 10,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: [],
);

/// Alias del enemigo por defecto usado en previews y valores fallback.
const defaultEnemyBattler = greenEnemyBattler;

/// Jugador base de la run antes de elegir arquetipo o conseguir equipo.
const defaultPlayerBattler = Battler(
  name: 'ENDPOINT UNIT',
  health: 100,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 100,
    BattlerStat.attack: 10,
    BattlerStat.defense: 5,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
);
