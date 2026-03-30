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
  final BattlerEffectPipeline _effectPipeline;

  const BattleResolver({
    BattlerEffectPipeline effectPipeline = const BattlerEffectPipeline(),
  }) : _effectPipeline = effectPipeline;

  BattleAttackResolution resolveAttack({
    required Battler attacker,
    required Battler defender,
  }) {
    final baseDamage = attacker.calculateDamageAgainst(defender);
    final outgoingStatusModifiedDamage =
        _effectPipeline.applyOutgoingDamageModifiers(
      owner: attacker,
      target: defender,
      damage: baseDamage,
    );
    final outgoingAbilityModifiedDamage =
        _effectPipeline.applyAbilityOutgoingDamageModifiers(
      owner: attacker,
      target: defender,
      damage: outgoingStatusModifiedDamage,
    );
    final outgoingModifiedDamage =
        _effectPipeline.applyEquippedItemOutgoingDamageModifiers(
      owner: attacker,
      target: defender,
      damage: outgoingAbilityModifiedDamage,
    );
    final incomingStatusModifiedDamage =
        _effectPipeline.applyIncomingDamageModifiers(
      owner: defender,
      source: attacker,
      damage: outgoingModifiedDamage,
    );
    final incomingAbilityModifiedDamage =
        _effectPipeline.applyAbilityIncomingDamageModifiers(
      owner: defender,
      source: attacker,
      damage: incomingStatusModifiedDamage,
    );
    final damageDealt =
        _effectPipeline.applyEquippedItemIncomingDamageModifiers(
      owner: defender,
      source: attacker,
      damage: incomingAbilityModifiedDamage,
    );
    final defenderAfterDamage = _effectPipeline.receiveDirectDamage(
      owner: defender,
      damage: damageDealt,
      source: attacker,
    );
    var updatedAttacker = _effectPipeline.applyAttackResolvedEffects(
      owner: attacker,
      target: defenderAfterDamage,
      damageDealt: damageDealt,
    );
    var updatedDefender = defenderAfterDamage;
    final attackAbilityResolution =
        _effectPipeline.applyAbilityAttackResolvedEffects(
      owner: updatedAttacker,
      target: updatedDefender,
      damageDealt: damageDealt,
    );
    updatedAttacker = attackAbilityResolution.owner;
    updatedDefender = attackAbilityResolution.opponent;

    final attackItemResolution =
        _effectPipeline.applyEquippedItemAttackResolvedEffects(
      owner: updatedAttacker,
      target: updatedDefender,
      damageDealt: damageDealt,
    );
    updatedAttacker = attackItemResolution.owner;
    updatedDefender = attackItemResolution.opponent;

    updatedDefender = _effectPipeline.applyReceiveDamageResolvedEffects(
      owner: updatedDefender,
      source: updatedAttacker,
      damageTaken: damageDealt,
    );
    final receiveAbilityResolution =
        _effectPipeline.applyAbilityReceiveDamageResolvedEffects(
      owner: updatedDefender,
      source: updatedAttacker,
      damageTaken: damageDealt,
    );
    updatedDefender = receiveAbilityResolution.owner;
    updatedAttacker = receiveAbilityResolution.opponent;
    final receiveItemResolution =
        _effectPipeline.applyEquippedItemReceiveDamageResolvedEffects(
      owner: updatedDefender,
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
