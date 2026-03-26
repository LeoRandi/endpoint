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
    final outgoingAbilityModifiedDamage =
        attacker.applyAbilityOutgoingDamageModifiers(
      target: defender,
      damage: outgoingStatusModifiedDamage,
    );
    final outgoingModifiedDamage =
        attacker.applyEquippedItemOutgoingDamageModifiers(
      target: defender,
      damage: outgoingAbilityModifiedDamage,
    );
    final incomingStatusModifiedDamage = defender.applyIncomingDamageModifiers(
      source: attacker,
      damage: outgoingModifiedDamage,
    );
    final incomingAbilityModifiedDamage =
        defender.applyAbilityIncomingDamageModifiers(
      source: attacker,
      damage: incomingStatusModifiedDamage,
    );
    final damageDealt = defender.applyEquippedItemIncomingDamageModifiers(
      source: attacker,
      damage: incomingAbilityModifiedDamage,
    );
    final defenderAfterDamage = defender.receiveDamage(damageDealt);
    var updatedAttacker = attacker.applyAttackResolvedEffects(
      target: defenderAfterDamage,
      damageDealt: damageDealt,
    );
    var updatedDefender = defenderAfterDamage;
    final attackAbilityResolution =
        updatedAttacker.applyAbilityAttackResolvedEffects(
      target: updatedDefender,
      damageDealt: damageDealt,
    );
    updatedAttacker = attackAbilityResolution.owner;
    updatedDefender = attackAbilityResolution.opponent;

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
    final receiveAbilityResolution =
        updatedDefender.applyAbilityReceiveDamageResolvedEffects(
      source: updatedAttacker,
      damageTaken: damageDealt,
    );
    updatedDefender = receiveAbilityResolution.owner;
    updatedAttacker = receiveAbilityResolution.opponent;
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
