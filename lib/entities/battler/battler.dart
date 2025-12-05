import "_imports.dart";

class Battler {
  final Map<BattlerClass, int> classExp = {};
  final BattlerClass? mainClass;
  final BattlerClass? subClass;
  final BattlerStats stats;
  final BattlerEquipmentLayout equipmentLayout;
  final String imagePath;
  final String name;
  late int maxHealth;
  late int health;
  bool isSelected = false;
  BattlerSide side;
  List<BattlerEquipment> equipmentList;
  bool get isAlive => health > 0;

  void select() {
    isSelected = true;
  }

  Battler(
      {required this.name,
      required this.imagePath,
      required this.side,
      required this.stats,
      required this.equipmentLayout,
      this.equipmentList = const [],
      this.mainClass,
      this.subClass}) {
    maxHealth = stats.calculatedStats[BattlerStatsType.health] ?? 0;
    health = maxHealth;
  }

  int getStat(BattlerStatsType statType) {
    return stats.calculatedStats[statType] ?? 0;
  }

  int getRealDamage(int damage, DamageType damageType) {
    switch (damageType) {
      case DamageType.trueDamage:
        return damage;
      case DamageType.magical:
        return _getMagicalDamage(damage);
      case DamageType.physical:
        return _getPhysicalDamage(damage);
    }
  }

  int _getPhysicalDamage(int damage) {
    int defense = getStat(BattlerStatsType.defense);
    int realDamage = damage - defense;
    return realDamage < 1 ? 1 : realDamage;
  }

  int _getMagicalDamage(int damage) {
    int magicDefense = getStat(BattlerStatsType.magicDefense);
    int realDamage = damage - magicDefense;
    return realDamage < 1 ? 1 : realDamage;
  }

  bool get hasClass => mainClass != null;
  bool get hasSubClass => subClass != null;

  String? get mainClassIconPath => mainClass?.iconPath;
  String? get subClassIconPath => subClass?.iconPath;

  static Battler hero() {
    return Battler(
      imagePath: 'assets/sprites/image_1.png',
      name: "Hero",
      side: BattlerSide.ally,
      equipmentLayout: BattlerEquipmentLayout.humanlike,
      stats: BattlerStats(rawStats: <BattlerStatsType, int>{
        BattlerStatsType.health: 30,
        BattlerStatsType.mana: 15,
        BattlerStatsType.strength: 1,
        BattlerStatsType.magic: 1,
        BattlerStatsType.luck: 0,
        BattlerStatsType.speed: 3,
        BattlerStatsType.defense: 0,
        BattlerStatsType.magicDefense: 0,
        BattlerStatsType.dodge: 0,
        BattlerStatsType.magicDodge: 0,
        BattlerStatsType.axe: 0,
        BattlerStatsType.bow: 0,
        BattlerStatsType.sword: 0,
        BattlerStatsType.dagger: 0,
        BattlerStatsType.hammer: 0,
        BattlerStatsType.unarmed: 0,
        BattlerStatsType.spear: 0,
        BattlerStatsType.shield: 0
      }),
    );
  }

  static Battler goblin() {
    return Battler(
      imagePath: 'assets/sprites/image_1.png',
      name: "Goblin",
      side: BattlerSide.enemy,
      equipmentLayout: BattlerEquipmentLayout.humanlike,
      stats: BattlerStats(rawStats: <BattlerStatsType, int>{
        BattlerStatsType.health: 20,
        BattlerStatsType.mana: 15,
        BattlerStatsType.strength: 2,
        BattlerStatsType.magic: 0,
        BattlerStatsType.luck: 0,
        BattlerStatsType.speed: 4,
        BattlerStatsType.defense: 0,
        BattlerStatsType.magicDefense: 0,
        BattlerStatsType.dodge: 3,
        BattlerStatsType.magicDodge: 0,
        BattlerStatsType.axe: 0,
        BattlerStatsType.bow: 0,
        BattlerStatsType.sword: 0,
        BattlerStatsType.dagger: 1,
        BattlerStatsType.hammer: 0,
        BattlerStatsType.unarmed: 0,
        BattlerStatsType.spear: 0,
        BattlerStatsType.shield: 1
      }),
    );
  }
}

extension BattlerList on List<Battler> {
  Battler? get selectedBattler {
    return firstWhere2((battler) => battler.isSelected);
  }
}

extension BattlerMap on Map<BattlerSide, List<Battler>> {
  Battler? get selectedBattler {
    for (var battlerList in values) {
      return battlerList.selectedBattler;
    }
    return null;
  }

  List<Battler> get allBattlers {
    return values.expand((battlerList) => battlerList).toList();
  }

  List<Battler> get aliveBattlers {
    return allBattlers.where((battler) => battler.isAlive).toList();
  }

  List<Battler> get allyBattlers {
    return this[BattlerSide.ally] ?? [];
  }

  List<Battler> get enemyBattlers {
    return this[BattlerSide.enemy] ?? [];
  }

  List<Battler> get neutralBattlers {
    return this[BattlerSide.neutral] ?? [];
  }
}

enum BattlerSide {
  ally(0),
  enemy(1),
  neutral(2),
  unkown(-1);

  final int value;
  const BattlerSide(this.value);

  static BattlerSide fromInt(int value) {
    return BattlerSide.values.firstWhere(
      (e) => e.value == value,
      orElse: () => BattlerSide.unkown,
    );
  }

  Color getColor() {
    switch (this) {
      case BattlerSide.ally:
        return Colors.blue;
      case BattlerSide.enemy:
        return Colors.red;
      case BattlerSide.neutral:
        return Colors.grey;
      case BattlerSide.unkown:
        return Colors.black;
    }
  }
}
