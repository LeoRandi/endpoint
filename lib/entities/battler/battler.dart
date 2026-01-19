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

  // Get the weapon stat type used by this battler based on equipped weapons
  // Returns equipped weapon's stat type, or unarmed if none equipped
  // If multiple weapons equipped, returns the one with highest stat
  // If tied, returns the first one equipped
  MapEntry<BattlerStatsType, int> getEquippedWeaponStat() {
    final weaponSlots = <int, BattlerEquipment>{};
    final layout = equipmentLayout.layout;

    // Collect all equipped weapons with their slot indices
    for (int i = 0; i < min(equipmentList.length, layout.length); i++) {
      if (layout[i] == BattlerEquipmentType.weapon &&
          equipmentList[i].name.isNotEmpty) {
        weaponSlots[i] = equipmentList[i];
      }
    }

    // If no weapons equipped, return unarmed
    if (weaponSlots.isEmpty) {
      return MapEntry(
          BattlerStatsType.unarmed, calculatedStats[BattlerStatsType.unarmed] ?? 0);
    }

    // Build weapon type to stat value map
    final weaponTypeStats = <BattlerStatsType, int>{};
    final weaponTypeOrder = <BattlerStatsType, int>{};

    for (final entry in weaponSlots.entries) {
      final equipment = entry.value;
      int slotIndex = entry.key;

      // Extract weapon type from bonus stats
      for (final bonus in equipment.bonus.entries) {
        final statType = bonus.key;
        // Check if it's a weapon stat type
        if (_isWeaponStatType(statType)) {
          final stat = calculatedStats[statType] ?? 0;
          if (!weaponTypeStats.containsKey(statType) || stat > weaponTypeStats[statType]!) {
            weaponTypeStats[statType] = stat;
            weaponTypeOrder[statType] = slotIndex;
          }
        }
      }
    }

    // If no weapon stat types found in bonus, return unarmed
    if (weaponTypeStats.isEmpty) {
      return MapEntry(
          BattlerStatsType.unarmed, calculatedStats[BattlerStatsType.unarmed] ?? 0);
    }

    // Find the highest stat value
    int maxValue = weaponTypeStats.values.first;
    for (final value in weaponTypeStats.values) {
      if (value > maxValue) maxValue = value;
    }

    // Return the weapon type with highest stat (first one if tied)
    BattlerStatsType resultType = BattlerStatsType.unarmed;
    int earliestSlot = 999;

    for (final entry in weaponTypeStats.entries) {
      if (entry.value == maxValue) {
        final slotIndex = weaponTypeOrder[entry.key] ?? 999;
        if (slotIndex < earliestSlot) {
          earliestSlot = slotIndex;
          resultType = entry.key;
        }
      }
    }

    return MapEntry(resultType, calculatedStats[resultType] ?? 0);
  }

  // Helper to check if a stat type is a weapon type
  bool _isWeaponStatType(BattlerStatsType type) {
    return type == BattlerStatsType.sword ||
        type == BattlerStatsType.spear ||
        type == BattlerStatsType.axe ||
        type == BattlerStatsType.hammer ||
        type == BattlerStatsType.dagger ||
        type == BattlerStatsType.unarmed ||
        type == BattlerStatsType.shield ||
        type == BattlerStatsType.bow;
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

  Battler copyWith({
    String? name,
    String? imagePath,
    BattlerSide? side,
    BattlerStats? stats,
    BattlerEquipmentLayout? equipmentLayout,
    List<BattlerEquipment>? equipmentList,
    BattlerClass? mainClass,
    BattlerClass? subClass,
  }) {
    return Battler(
      name: name ?? this.name,
      imagePath: imagePath ?? this.imagePath,
      side: side ?? this.side,
      stats: stats ?? this.stats,
      equipmentLayout: equipmentLayout ?? this.equipmentLayout,
      equipmentList: equipmentList ?? this.equipmentList,
      mainClass: mainClass ?? this.mainClass,
      subClass: subClass ?? this.subClass,
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
