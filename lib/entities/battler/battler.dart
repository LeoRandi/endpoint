import '_imports.dart';

enum BattlerStat {
  health,
  attack,
  defense,
  thorns,
  damageReduction,
  vampirism,
}

class Battler {
  final String name;
  final int health;
  final Map<BattlerStat, int> baseStats;
  final List<String> abilities;
  final List<Item> inventoryItems;
  final List<Item> equippedItems;

  const Battler({
    required this.name,
    required this.health,
    required this.baseStats,
    this.abilities = const [],
    this.inventoryItems = const [],
    this.equippedItems = const [],
  }) : assert(health >= 0);

  Battler.legacy({
    required String name,
    required int attack,
    required int defense,
    required int health,
    int? maxHealth,
    List<String> abilities = const [],
    List<Item> inventoryItems = const [],
    List<Item> equippedItems = const [],
  }) : this(
          name: name,
          health: health,
          baseStats: {
            BattlerStat.health: maxHealth ?? health,
            BattlerStat.attack: attack,
            BattlerStat.defense: defense,
            BattlerStat.thorns: 0,
            BattlerStat.damageReduction: 0,
            BattlerStat.vampirism: 0,
          },
          abilities: abilities,
          inventoryItems: inventoryItems,
          equippedItems: equippedItems,
        );

  int get baseMaxHealth => baseStat(BattlerStat.health);
  int get maxHealth => calculatedStat(BattlerStat.health);

  int get baseAttack => baseStat(BattlerStat.attack);
  int get attack => calculatedStat(BattlerStat.attack);

  int get baseDefense => baseStat(BattlerStat.defense);
  int get defense => calculatedStat(BattlerStat.defense);

  int get baseThorns => baseStat(BattlerStat.thorns);
  int get thorns => calculatedStat(BattlerStat.thorns);

  int get baseDamageReduction => baseStat(BattlerStat.damageReduction);
  int get damageReduction => calculatedStat(BattlerStat.damageReduction);

  int get baseVampirism => baseStat(BattlerStat.vampirism);
  int get vampirism => calculatedStat(BattlerStat.vampirism);

  bool get isDefeated => health <= 0;

  int baseStat(BattlerStat stat) {
    return baseStats[stat] ?? 0;
  }

  int calculatedStat(BattlerStat stat) {
    return _calculateStat(
      baseStats: baseStats,
      equippedItems: equippedItems,
      stat: stat,
    );
  }

  int calculateDamageAgainst(Battler target) {
    // TODO: Apply thorns, damage reduction, and vampirism when their combat rules are defined.
    return max(
      1,
      calculatedStat(BattlerStat.attack) -
          target.calculatedStat(BattlerStat.defense),
    );
  }

  Battler receiveAttack(Battler attacker) {
    return receiveDamage(attacker.calculateDamageAgainst(this));
  }

  Battler receiveDamage(int damage) {
    final safeDamage = max(0, damage);
    return copyWith(health: max(0, health - safeDamage));
  }

  Battler heal(int amount) {
    final safeAmount = max(0, amount);
    return copyWith(health: min(maxHealth, health + safeAmount));
  }

  Battler equipItem(Item item) {
    if (!inventoryItems.contains(item)) return this;
    if (equippedItems.contains(item)) return this;

    final updatedInventoryItems = List<Item>.from(inventoryItems)..remove(item);
    final updatedEquippedItems = List<Item>.from(equippedItems)..add(item);

    return copyWith(
      inventoryItems: updatedInventoryItems,
      equippedItems: updatedEquippedItems,
    );
  }

  Battler unequipItem(Item item) {
    if (!equippedItems.contains(item)) return this;

    final updatedEquippedItems = List<Item>.from(equippedItems)..remove(item);
    final updatedInventoryItems = List<Item>.from(inventoryItems)..add(item);

    return copyWith(
      inventoryItems: updatedInventoryItems,
      equippedItems: updatedEquippedItems,
    );
  }

  Battler copyWith({
    String? name,
    int? health,
    Map<BattlerStat, int>? baseStats,
    List<String>? abilities,
    List<Item>? inventoryItems,
    List<Item>? equippedItems,
  }) {
    final resolvedBaseStats = baseStats ?? this.baseStats;
    final resolvedInventoryItems = inventoryItems ?? this.inventoryItems;
    final resolvedEquippedItems = equippedItems ?? this.equippedItems;
    final resolvedMaxHealth = _calculateStat(
      baseStats: resolvedBaseStats,
      equippedItems: resolvedEquippedItems,
      stat: BattlerStat.health,
    );
    final resolvedHealth = min(health ?? this.health, resolvedMaxHealth);

    return Battler(
      name: name ?? this.name,
      health: max(0, resolvedHealth),
      baseStats: resolvedBaseStats,
      abilities: abilities ?? this.abilities,
      inventoryItems: resolvedInventoryItems,
      equippedItems: resolvedEquippedItems,
    );
  }

  static int _calculateStat({
    required Map<BattlerStat, int> baseStats,
    required List<Item> equippedItems,
    required BattlerStat stat,
  }) {
    final baseValue = baseStats[stat] ?? 0;
    final equipmentBonus = equippedItems.fold<int>(
      0,
      (total, item) => total + item.modifier(stat),
    );

    return max(0, baseValue + equipmentBonus);
  }
}
