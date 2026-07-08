import '_imports.dart';

Item _enemyItem(String name) {
  final item = itemPresetRegistry[name];
  if (item == null) {
    throw StateError('Missing enemy preset item: $name');
  }
  return item;
}

Item _enemyItemAtTier(String name, RarityTier tier) {
  final item = _enemyItem(name);
  if (item.tier.isAtLeast(tier)) return item;
  return item.copyWith(tier: tier);
}

List<Item> _enemyItems(List<String> names) {
  return List<Item>.unmodifiable(names.map(_enemyItem));
}

/// Enemigo gris economico que convierte creditos en pequenos golpes de Patron.
final debtRoachEnemyBattler = Battler(
  name: 'DEBT ROACH',
  imageAsset: 'assets/sprites/monsters/Debt roach128.png',
  health: 27,
  money: 10,
  income: 0,
  level: 2,
  baseStats: {
    BattlerStat.health: 27,
    BattlerStat.attack: 3,
    BattlerStat.barrier: 1,
  },
  equippedItems: _enemyItems([
    'La Cuenta',
    'Lanzamonedas',
  ]),
  patternItemPointKeys: {
    'La Cuenta': '-1,1',
    'Lanzamonedas': '0,1',
  },
);

/// Enemigo gris de debuffs que cambia fuerza bruta por presion toxica.
final rustyStingEnemyBattler = Battler(
  name: 'RUSTY STING',
  health: 27,
  money: 0,
  income: 0,
  level: 2,
  baseStats: {
    BattlerStat.health: 27,
    BattlerStat.attack: 1,
    BattlerStat.barrier: 1,
  },
  equippedItems: _enemyItems([
    'Splinter Dart',
    'Venotronome',
  ]),
  patternItemPointKeys: {
    'Splinter Dart': '-1,1',
    'Venotronome': '0,0',
  },
);

/// Enemigo gris duelista con mas vida y ataque, pero sin barrera inicial.
final duelistHopperEnemyBattler = Battler(
  name: 'DUELIST HOPPER',
  health: 27,
  money: 0,
  income: 0,
  level: 2,
  baseStats: {
    BattlerStat.health: 27,
    BattlerStat.attack: 4,
    BattlerStat.barrier: 0,
  },
  equippedItems: _enemyItems([
    'Duelist Chalk',
    'Rusted Cleaver',
    'Spite Hook',
  ]),
  patternItemPointKeys: {
    'Duelist Chalk': '-1,1',
    'Rusted Cleaver': '0,1',
    'Spite Hook': '1,1',
  },
);

/// Enemigo gris defensivo con mucha barrera y poca presion directa.
final signalStagEnemyBattler = Battler(
  name: 'SIGNAL STAG',
  imageAsset: 'assets/sprites/monsters/Signal stag.png',
  health: 24,
  money: 0,
  income: 0,
  level: 2,
  baseStats: {
    BattlerStat.health: 24,
    BattlerStat.attack: 2,
    BattlerStat.barrier: 3,
  },
  equippedItems: _enemyItems([
    'Slate Buckler',
    'Oathplate',
    'Venotronome',
  ]),
  patternItemPointKeys: {
    'Slate Buckler': '-1,1',
    'Oathplate': '0,1',
    'Venotronome': '0,0',
  },
);

/// Enemigo gris fragil que usa su equipo para alcanzar ataque medio.
final reactorFleaEnemyBattler = Battler(
  name: 'REACTOR FLEA',
  health: 20,
  money: 0,
  income: 0,
  level: 2,
  baseStats: {
    BattlerStat.health: 20,
    BattlerStat.attack: 1,
    BattlerStat.barrier: 0,
  },
  equippedItems: _enemyItems([
    'Wooden Stick',
    'S-Harp-Ener',
    'Pocket Shiv',
  ]),
  patternItemPointKeys: {
    'Wooden Stick': '0,1',
    'S-Harp-Ener': '0,0',
    'Pocket Shiv': '1,0',
  },
);

/// Enemigo azul de presion centrada en Quemadura y golpes grandes.
final cinderClawEnemyBattler = Battler(
  name: 'CINDER CLAW',
  imageAsset: 'assets/sprites/monsters/Cinder claw128.png',
  health: 41,
  money: 0,
  income: 0,
  equipmentCapacity: 5,
  level: 8,
  baseStats: {
    BattlerStat.health: 41,
    BattlerStat.attack: 4,
    BattlerStat.barrier: 2,
  },
  equippedItems: _enemyItems([
    'Challenge Brand',
    'Furnace Heart',
    'Kindling Axe',
    'Ash-Eater Mask',
  ]),
  patternItemPointKeys: {
    'Challenge Brand': '-1,1',
    'Furnace Heart': '0,0',
    'Kindling Axe': '1,0',
    'Ash-Eater Mask': '-1,0',
  },
);

/// Enemigo final amarillo con el kit mas completo del roster actual.
final yellowEnemyBattler = Battler(
  name: 'SOLAR EXECUTOR',
  imageAsset: 'assets/sprites/monsters/Solar executor128.png',
  health: 204,
  money: 0,
  income: 0,
  equipmentCapacity: 8,
  level: 10,
  baseStats: {
    BattlerStat.health: 204,
    BattlerStat.attack: 10,
    BattlerStat.barrier: 6,
  },
  equippedItems: List<Item>.unmodifiable([
    _enemyItemAtTier('Challenge Brand', RarityTier.purple),
    _enemyItemAtTier('Execution Bell', RarityTier.purple),
    _enemyItemAtTier('Shield Lance', RarityTier.purple),
    _enemyItemAtTier('Bloodflame Gauntlet', RarityTier.purple),
    _enemyItemAtTier('Furnace Heart', RarityTier.purple),
    _enemyItemAtTier('Kindling Axe', RarityTier.purple),
    _enemyItemAtTier('Rampart Ram', RarityTier.purple),
    _enemyItemAtTier('Crown of the Black Sun', RarityTier.yellow),
  ]),
  patternItemPointKeys: {
    'Challenge Brand': '-1,1',
    'Execution Bell': '0,1',
    'Shield Lance': '1,1',
    'Bloodflame Gauntlet': '-1,0',
    'Furnace Heart': '0,0',
    'Kindling Axe': '1,0',
    'Rampart Ram': '0,-1',
    'Crown of the Black Sun': '1,-1',
  },
);

/// Alias del enemigo por defecto usado en previews y valores fallback.
final Battler defaultEnemyBattler = debtRoachEnemyBattler;

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
