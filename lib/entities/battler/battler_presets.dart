import '_imports.dart';

const grayEnemyBattler = Battler(
  name: 'SCRAP MITE',
  health: 48,
  baseStats: {
    BattlerStat.health: 48,
    BattlerStat.attack: 6,
    BattlerStat.defense: 2,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
);

const greenEnemyBattler = Battler(
  name: 'HOLLOW DRONE',
  health: 72,
  baseStats: {
    BattlerStat.health: 72,
    BattlerStat.attack: 8,
    BattlerStat.defense: 4,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: [BattlerAbility.defend],
);

const blueEnemyBattler = Battler(
  name: 'RIFT HOUND',
  health: 96,
  baseStats: {
    BattlerStat.health: 96,
    BattlerStat.attack: 10,
    BattlerStat.defense: 6,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: [BattlerAbility.defend],
);

const purpleEnemyBattler = Battler(
  name: 'NULL WARDEN',
  health: 128,
  baseStats: {
    BattlerStat.health: 128,
    BattlerStat.attack: 13,
    BattlerStat.defense: 8,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: [
    BattlerAbility.defend,
    BattlerAbility.overclock,
  ],
);

const yellowEnemyBattler = Battler(
  name: 'SOLAR EXECUTOR',
  health: 168,
  baseStats: {
    BattlerStat.health: 168,
    BattlerStat.attack: 16,
    BattlerStat.defense: 10,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: [
    BattlerAbility.defend,
    BattlerAbility.overclock,
    BattlerAbility.purge,
  ],
);

const defaultEnemyBattler = greenEnemyBattler;

const defaultPlayerBattler = Battler(
  name: 'ENDPOINT UNIT',
  health: 84,
  baseStats: {
    BattlerStat.health: 100,
    BattlerStat.attack: 10,
    BattlerStat.defense: 5,
    BattlerStat.thorns: 0,
    BattlerStat.damageReduction: 0,
    BattlerStat.vampirism: 0,
  },
  abilities: [BattlerAbility.defend],
  inventoryItems: [woodenStickItem],
);
