import "_imports.dart";

class Battler {
  final Map<BattlerClass, int> classExp = {};
  final BattlerClass? mainClass;
  final BattlerClass? subClass;
  final BattlerStats stats;
  final BattlerEquipmentLayout equipmentLayout;
  final String imagePath;
  final String name;
  final int id;
  late int maxHealth;
  late int health;
  bool isSelected = false;
  BattlerSide side;
  List<BattlerEquipment> equipmentList;
  bool get isAlive => health > 0;

  Map<BattlerStatsType, int> get calculatedStats {
    final baseStats = Map<BattlerStatsType, int>.from(stats.rawStats);
    final layout = equipmentLayout.layout; // expected type per slot

    // Safety: in case something rare happens and sizes don't match
    final int slots = min(equipmentList.length, layout.length);

    for (int i = 0; i < slots; i++) {
      final equipment = equipmentList[i];
      if (!equipmentLayout.isValidAtSlot(i, equipment)) continue;

      equipment.bonus.forEach((statType, bonusValue) {
        baseStats[statType] = (baseStats[statType] ?? 0) + bonusValue;
      });
    }

    return baseStats;
  }

  void select() {
    isSelected = true;
  }

  Battler(
      {required this.name,
      required this.id,
      required this.imagePath,
      required this.side,
      required this.stats,
      required this.equipmentLayout,
      List<BattlerEquipment>? equipmentList,
      this.mainClass,
      this.subClass})
      : equipmentList =
            equipmentList ?? List.filled(8, BattlerEquipment.empty()) {
    maxHealth = calculatedStats[BattlerStatsType.health] ?? 0;
    health = maxHealth;
  }

  int getStat(BattlerStatsType statType) {
    return calculatedStats[statType] ?? 0;
  }

  bool fillEquipment(BattlerEquipment equipment) {
    final layout = equipmentLayout.layout;
    final int slots = min(equipmentList.length, layout.length);

    for (int i = 0; i < slots; i++) {
      equipmentList[i] = equipment;
    }

    return true;
  }

  bool addEquipment(BattlerEquipment equipment, {int? slot}) {
    final layout = equipmentLayout.layout;

    if (slot != null && equipmentList[slot].name.isEmpty) {
      equipmentList[slot] = equipment;
      return true;
    }

    // Safety in case something weird happens with lengths
    final int slots = min(equipmentList.length, layout.length);

    int? fallbackConsumableIndex;

    for (int i = 0; i < slots; i++) {
      final BattlerEquipmentType expectedType = layout[i];
      final BattlerEquipment current = equipmentList[i];

      // Consider the slot free if it's an "empty" equipment
      final bool isFree = current.name.isEmpty;

      if (!isFree) continue;

      // Perfect match: free slot whose type matches the equipment type
      if (expectedType == equipment.type) {
        equipmentList[i] = equipment;
        return true;
      }

      // Store first free consumable slot as fallback
      if (fallbackConsumableIndex == null &&
          expectedType == BattlerEquipmentType.consumable) {
        fallbackConsumableIndex = i;
      }
    }

    // No matching type free slots; try a free consumable slot
    if (fallbackConsumableIndex != null) {
      equipmentList[fallbackConsumableIndex] = equipment;
      return true;
    }

    // No space anywhere
    return false;
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
    final hero = Battler(
      imagePath: 'assets/sprites/base_dude.png',
      name: "Hero",
      side: BattlerSide.ally,
      equipmentLayout: BattlerEquipmentLayout.humanlike,
      stats: BattlerStats(
        rawStats: BattlerStatsMap.baseHuman(),
      ),
    );

    hero.addEquipment(BattlerEquipment(
        name: "placeholder axe",
        type: BattlerEquipmentType.weapon,
        bonus: {BattlerStatsType.axe: 1},
        description: "A basic axe for testing.",
        imagePath: 'assets/images/icons/icon_axe.png'));

    return hero;
  }

  static Battler heroMage() {
    final hero = Battler(
      imagePath: 'assets/sprites/base_dude.png',
      name: "Hero Mage",
      side: BattlerSide.ally,
      equipmentLayout: BattlerEquipmentLayout.humanlike,
      stats: BattlerStats(
        rawStats: BattlerStatsMap.baseHuman().copyWith(changes: [
          (BattlerStatsType.magic, 3),
          (BattlerStatsType.magicDefense, 2)
        ]),
      ),
    );

    hero.addEquipment(BattlerEquipment(
        name: "placeholder magic hand",
        type: BattlerEquipmentType.weapon,
        bonus: {BattlerStatsType.magic: 1},
        description: "A basic magic hand for testing.",
        imagePath: 'assets/images/icons/icon_unarmed.png'));
    return hero;
  }

  static Battler heroRogue() {
    final hero = Battler(
      imagePath: 'assets/sprites/base_dude.png',
      name: "Hero Rogue",
      side: BattlerSide.ally,
      equipmentLayout: BattlerEquipmentLayout.humanlike,
      stats: BattlerStats(
        rawStats: BattlerStatsMap.baseHuman().copyWith(changes: [
          (BattlerStatsType.speed, 4),
          (BattlerStatsType.dodge, 10),
          (BattlerStatsType.dagger, 2)
        ]),
      ),
    );

    hero.addEquipment(BattlerEquipment(
        name: "placeholder dagger",
        type: BattlerEquipmentType.weapon,
        bonus: {BattlerStatsType.dagger: 1},
        description: "A basic dagger for testing.",
        imagePath: 'assets/images/icons/icon_dagger.png'));

    return hero;
  }

  static Battler heroCleric() {
    final hero = Battler(
      imagePath: 'assets/sprites/base_dude.png',
      name: "Hero Cleric",
      side: BattlerSide.ally,
      equipmentLayout: BattlerEquipmentLayout.humanlike,
      stats: BattlerStats(
        rawStats: BattlerStatsMap.baseHuman().copyWith(changes: [
          (BattlerStatsType.magic, 2),
          (BattlerStatsType.magicDefense, 1),
          (BattlerStatsType.defense, 1)
        ]),
      ),
    );

    hero.addEquipment(BattlerEquipment(
        name: "placeholder hammer",
        type: BattlerEquipmentType.weapon,
        bonus: {BattlerStatsType.hammer: 1},
        description: "A basic hammer for testing.",
        imagePath: 'assets/images/icons/icon_hammer.png'));

    return hero;
  }

  static Battler goblin() {
    final goblin = Battler(
      imagePath: 'assets/sprites/base_green_dude.png',
      name: "Goblin",
      side: BattlerSide.enemy,
      equipmentLayout: BattlerEquipmentLayout.humanlike,
      stats: BattlerStats(rawStats: BattlerStatsMap.baseGoblin()),
    );

    goblin.addEquipment(BattlerEquipment(
        name: "placeholder dagger",
        type: BattlerEquipmentType.weapon,
        bonus: {BattlerStatsType.dagger: 1},
        description: "A basic dagger for testing.",
        imagePath: 'assets/images/icons/icon_dagger.png'));

    return goblin;
  }

  static Battler goblinTank() {
    final goblin = Battler(
      imagePath: 'assets/sprites/base_green_dude.png',
      name: "Goblin Tank",
      side: BattlerSide.enemy,
      equipmentLayout: BattlerEquipmentLayout.humanlike,
      stats: BattlerStats(rawStats: BattlerStatsMap.baseGoblin()),
    );

    goblin.addEquipment(BattlerEquipment(
        name: "placeholder dagger",
        type: BattlerEquipmentType.weapon,
        bonus: {BattlerStatsType.dagger: 1},
        description: "A basic dagger for testing.",
        imagePath: 'assets/images/icons/icon_dagger.png'));

    goblin.addEquipment(BattlerEquipment(
        name: "placeholder armor",
        type: BattlerEquipmentType.armor,
        bonus: {BattlerStatsType.defense: 1},
        description: "A basic armor for testing.",
        imagePath: 'assets/images/icons/icon_dodge.png'));

    goblin.addEquipment(BattlerEquipment(
        name: "placeholder shield",
        type: BattlerEquipmentType.weapon,
        bonus: {BattlerStatsType.dodge: 3},
        description: "A basic shield for testing.",
        imagePath: 'assets/images/icons/icon_shield.png'));

    return goblin;
  }

  static Battler goblinArcher() {
    final goblin = Battler(
      imagePath: 'assets/sprites/base_green_dude.png',
      name: "Goblin Archer",
      side: BattlerSide.enemy,
      equipmentLayout: BattlerEquipmentLayout.humanlike,
      stats: BattlerStats(rawStats: BattlerStatsMap.baseGoblin()),
    );

    goblin.addEquipment(BattlerEquipment(
        name: "placeholder bow",
        type: BattlerEquipmentType.weapon,
        bonus: {BattlerStatsType.bow: 1},
        description: "A basic bow for testing.",
        imagePath: 'assets/images/icons/icon_bow.png'));

    goblin.addEquipment(
        BattlerEquipment(
            name: "placeholder dagger",
            type: BattlerEquipmentType.weapon,
            bonus: {BattlerStatsType.dagger: 1},
            description: "A basic dagger for testing.",
            imagePath: 'assets/images/icons/icon_dagger.png'),
        slot: 7);

    return goblin;
  }

  static Battler trashGoblin() {
    final goblin = Battler(
      imagePath: 'assets/sprites/base_green_dude.png',
      name: "Trash Goblin",
      side: BattlerSide.enemy,
      equipmentLayout: BattlerEquipmentLayout.humanlike,
      stats: BattlerStats(rawStats: BattlerStatsMap.baseGoblin()),
    );

    goblin.fillEquipment(BattlerEquipment(
        name: "placeholder trash",
        type: BattlerEquipmentType.consumable,
        bonus: {},
        description: "A basic trash for testing.",
        imagePath: 'assets/images/icons/icon_luck.png'));

    return goblin;
  }

  static Battler voidBattler() {
    return Battler(
      imagePath: 'assets/images/void.png',
      name: "",
      side: BattlerSide.unkown,
      equipmentLayout: BattlerEquipmentLayout.unkown,
      stats: BattlerStats(rawStats: BattlerStatsMap.baseStats()),
    );
  }
}

extension BattlerList on List<Battler> {
  Battler? get selectedBattler {
    return firstWhere((battler) => battler.isSelected, orElse: () => first);
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
