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
    final outgoingStatusModifiedDamage = attacker.applyOutgoingDamageModifiers(
      target: defender,
      damage: baseDamage,
    );
    final outgoingModifiedDamage =
        attacker.applyEquippedItemOutgoingDamageModifiers(
      target: defender,
      damage: outgoingStatusModifiedDamage,
    );
    final incomingStatusModifiedDamage = defender.applyIncomingDamageModifiers(
      source: attacker,
      damage: outgoingModifiedDamage,
    );
    final damageDealt = defender.applyEquippedItemIncomingDamageModifiers(
      source: attacker,
      damage: incomingStatusModifiedDamage,
    );
    final defenderAfterDamage = defender.receiveDamage(damageDealt);
    var updatedAttacker = attacker.applyAttackResolvedEffects(
      target: defenderAfterDamage,
      damageDealt: damageDealt,
    );
    var updatedDefender = defenderAfterDamage;

    final attackItemResolution =
        updatedAttacker.applyEquippedItemAttackResolvedEffects(
      target: updatedDefender,
      damageDealt: damageDealt,
    );
    updatedAttacker = attackItemResolution.owner;
    updatedDefender = attackItemResolution.opponent;

    updatedDefender = updatedDefender.applyReceiveDamageResolvedEffects(
      source: updatedAttacker,
      damageTaken: damageDealt,
    );
    final receiveItemResolution =
        updatedDefender.applyEquippedItemReceiveDamageResolvedEffects(
      source: updatedAttacker,
      damageTaken: damageDealt,
    );
    updatedDefender = receiveItemResolution.owner;
    updatedAttacker = receiveItemResolution.opponent;

    // TODO: Apply thorns, damage reduction, and vampirism once combat rules are finalized.
    return BattleAttackResolution(
      attacker: updatedAttacker,
      defender: updatedDefender,
      damageDealt: damageDealt,
    );
  }
}
