import '_imports.dart';

/// Enemigo gris economico que convierte creditos en pequenos golpes de Patron.
const debtRoachEnemyBattler = Battler(
  name: 'DEBT ROACH',
  imageAsset: 'assets/sprites/monsters/Debt roach128.png',
  health: 27,
  money: 10,
  income: 0,
  baseStats: {
    BattlerStat.health: 27,
    BattlerStat.attack: 3,
    BattlerStat.barrier: 1,
  },
  equippedItems: [],
  patternItemPointKeys: {},
);

/// Enemigo gris de debuffs que cambia fuerza bruta por presion toxica.
const rustyStingEnemyBattler = Battler(
  name: 'RUSTY STING',
  health: 27,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 27,
    BattlerStat.attack: 1,
    BattlerStat.barrier: 1,
  },
  equippedItems: [],
  patternItemPointKeys: {},
);

/// Enemigo gris duelista con mas vida y ataque, pero sin barrera inicial.
const duelistHopperEnemyBattler = Battler(
  name: 'DUELIST HOPPER',
  health: 27,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 27,
    BattlerStat.attack: 4,
    BattlerStat.barrier: 0,
  },
  equippedItems: [],
  patternItemPointKeys: {},
);

/// Enemigo gris defensivo con mucha barrera y poca presion directa.
const signalStagEnemyBattler = Battler(
  name: 'SIGNAL STAG',
  health: 24,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 24,
    BattlerStat.attack: 2,
    BattlerStat.barrier: 3,
  },
  equippedItems: [],
  patternItemPointKeys: {},
);

/// Enemigo gris fragil que usa su equipo para alcanzar ataque medio.
const reactorFleaEnemyBattler = Battler(
  name: 'REACTOR FLEA',
  health: 20,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 20,
    BattlerStat.attack: 1,
    BattlerStat.barrier: 0,
  },
  equippedItems: [],
  patternItemPointKeys: {},
);

/// Variante verde de presion temprana centrada en quemar al objetivo.
const cinderClawEnemyBattler = Battler(
  name: 'CINDER CLAW',
  imageAsset: 'assets/sprites/monsters/Cinder claw128.png',
  health: 41,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 41,
    BattlerStat.attack: 4,
    BattlerStat.barrier: 2,
  },
  equippedItems: [],
  patternItemPointKeys: {},
);

/// Enemigo final amarillo con el kit mas completo del roster actual.
const yellowEnemyBattler = Battler(
  name: 'SOLAR EXECUTOR',
  health: 204,
  money: 0,
  income: 0,
  equipmentCapacity: 5,
  baseStats: {
    BattlerStat.health: 204,
    BattlerStat.attack: 10,
    BattlerStat.barrier: 6,
  },
  equippedItems: [],
  patternItemPointKeys: {},
);

/// Alias del enemigo por defecto usado en previews y valores fallback.
const Battler defaultEnemyBattler = debtRoachEnemyBattler;

/// Jugador base de la run antes de elegir arquetipo o conseguir equipo.
const defaultPlayerBattler = Battler(
  name: 'ENDPOINT UNIT',
  imageAsset: null,
  health: 45,
  money: 0,
  income: 0,
  baseStats: {
    BattlerStat.health: 45,
    BattlerStat.attack: 0,
    BattlerStat.barrier: 0,
  },
);
