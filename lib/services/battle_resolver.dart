import '_imports.dart';

class BattleAttackResolution {
  final Battler attacker;
  final Battler defender;
  final int damageDealt;

  const BattleAttackResolution({
    required this.attacker,
    required this.defender,
    required this.damageDealt,
  });
}

class BattleResolver {
  const BattleResolver();

  BattleAttackResolution resolveAttack({
    required Battler attacker,
    required Battler defender,
  }) {
    final damageDealt = attacker.calculateDamageAgainst(defender);
    final updatedDefender = defender.receiveDamage(damageDealt);

    // TODO: Apply thorns, damage reduction, and vampirism once combat rules are finalized.
    return BattleAttackResolution(
      attacker: attacker,
      defender: updatedDefender,
      damageDealt: damageDealt,
    );
  }
}
