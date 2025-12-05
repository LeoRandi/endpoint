import "_imports.dart";

class Battler {
  final Map<BattlerClass, int> classExp = {};
  final BattlerClass? mainClass;
  final BattlerClass? subClass;
  final BattlerStats stats;
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
