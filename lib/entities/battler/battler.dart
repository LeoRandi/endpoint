import '_imports.dart';

class Battler {
  final String name;
  final int attack;
  final int defense;
  final int health;
  final int maxHealth;
  final List<String> abilities;

  const Battler({
    required this.name,
    required this.attack,
    required this.defense,
    required this.health,
    int? maxHealth,
    this.abilities = const [],
  })  : assert(attack >= 0),
        assert(defense >= 0),
        assert(health >= 0),
        assert(maxHealth == null || maxHealth >= 0),
        assert(maxHealth == null || health <= maxHealth),
        maxHealth = maxHealth ?? health;

  bool get isDefeated => health <= 0;

  int calculateDamageAgainst(Battler target) {
    return max(1, attack - target.defense);
  }

  Battler receiveAttack(Battler attacker) {
    return receiveDamage(attacker.calculateDamageAgainst(this));
  }

  Battler receiveDamage(int damage) {
    final safeDamage = max(0, damage);
    return copyWith(health: max(0, health - safeDamage));
  }

  Battler copyWith({
    String? name,
    int? attack,
    int? defense,
    int? health,
    int? maxHealth,
    List<String>? abilities,
  }) {
    final resolvedMaxHealth = maxHealth ?? this.maxHealth;
    final resolvedHealth = min(health ?? this.health, resolvedMaxHealth);

    return Battler(
      name: name ?? this.name,
      attack: attack ?? this.attack,
      defense: defense ?? this.defense,
      health: max(0, resolvedHealth),
      maxHealth: resolvedMaxHealth,
      abilities: abilities ?? this.abilities,
    );
  }
}
