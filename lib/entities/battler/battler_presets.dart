import '../_imports.dart';

const _patternTop = '0,1';
const _patternLeft = '-1,0';
const _patternCenter = '0,0';
const _patternRight = '1,0';
const _patternBottom = '0,-1';
const _patternLeftBottom = '-1,-1';
const _patternRightBottom = '1,-1';
const _patternLeftTop = '-1,1';
const _patternRightTop = '1,1';

/// Enemigo gris economico que convierte creditos en pequenos golpes de Patron.
const debtRoachEnemyBattler = Battler(
  name: 'DEBT ROACH',
  health: 27,
  money: 10,
  income: 0,
  baseStats: {
    BattlerStat.health: 27,
    BattlerStat.attack: 3,
    BattlerStat.barrier: 1,
  },
  equippedItems: [
    laCuentaItem,
    coinLauncherItem,
    pagareRevalorizableItem,
  ],
  patternItemPointKeys: {
    'laCuenta': _patternCenter,
    'coinLauncher': _patternTop,
    'pagareRevalorizableItem': _patternLeftBottom,
  },
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
  equippedItems: [
    vialRotoItem,
    plumaSepticaItem,
    pagareRevalorizableItem,
  ],
  patternItemPointKeys: {
    'vialRoto': _patternCenter,
    'plumaSeptica': _patternRight,
    'pagareRevalorizableItem': _patternRightBottom,
  },
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
  equippedItems: [
    clavoDuelistaItem,
    guanteRetoItem,
    pagareRevalorizableItem,
  ],
  patternItemPointKeys: {
    'clavoDuelista': _patternCenter,
    'guanteReto': _patternRight,
    'pagareRevalorizableItem': _patternLeftBottom,
  },
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
  equippedItems: [
    pocketJammerItem,
    filtroRuidoItem,
    pagareRevalorizableItem,
  ],
  patternItemPointKeys: {
    'pocketJammer': _patternCenter,
    'filtroRuido': _patternRight,
    'pagareRevalorizableItem': _patternLeftTop,
  },
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
  equippedItems: [
    crackedBatteryItem,
    clavoReactorItem,
    pagareRevalorizableItem,
  ],
  patternItemPointKeys: {
    'crackedBattery': _patternCenter,
    'clavoReactor': _patternRight,
    'pagareRevalorizableItem': _patternRightTop,
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
