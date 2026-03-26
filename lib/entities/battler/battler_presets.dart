import '_imports.dart';

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
  abilities: [defendAbility],
  equippedItems: [guardShieldItem],
);

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
  abilities: [defendAbility],
  equippedItems: [
    ironSwordItem,
    platedJacketItem,
  ],
);

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
  abilities: [
    defendAbility,
    overclockAbility,
  ],
  equippedItems: [
    ironSwordItem,
    voidInjectorItem,
  ],
);

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
  abilities: [
    defendAbility,
    overclockAbility,
    purgeAbility,
  ],
);

const defaultEnemyBattler = greenEnemyBattler;

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
  abilities: [
    weaknessHunterAbility,
    ghostMeshAbility,
    cruelCatalysisAbility,
    venousOverloadAbility,
    hardResetAbility,
  ],
);
