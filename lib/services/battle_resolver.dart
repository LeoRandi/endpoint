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
    final baseDamage = attacker.calculateDamageAgainst(defender);
    final outgoingModifiedDamage = attacker.applyOutgoingDamageModifiers(
      target: defender,
      damage: baseDamage,
    );
    final damageDealt = defender.applyIncomingDamageModifiers(
      source: attacker,
      damage: outgoingModifiedDamage,
    );
    final defenderAfterDamage = defender.receiveDamage(damageDealt);
    final updatedAttacker = attacker.applyAttackResolvedEffects(
      target: defenderAfterDamage,
      damageDealt: damageDealt,
    );
    final updatedDefender =
        defenderAfterDamage.applyReceiveDamageResolvedEffects(
      source: updatedAttacker,
      damageTaken: damageDealt,
    );

    // TODO: Apply thorns, damage reduction, and vampirism once combat rules are finalized.
    return BattleAttackResolution(
      attacker: updatedAttacker,
      defender: updatedDefender,
      damageDealt: damageDealt,
    );
  }
}
