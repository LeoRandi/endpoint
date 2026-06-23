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
    int flatAttackBonus = 0,
    int? baseDamageOverride,
    bool triggerAttackResolvedEffects = true,
  }) {
    if (defender.hasStatus(PuntoCiegoStatus.statusId)) {
      return _resolvePuntoCiegoMissedAttack(
        attacker: attacker,
        defender: defender,
        triggerAttackResolvedEffects: triggerAttackResolvedEffects,
      );
    }

    final bonusDamage = max(0, flatAttackBonus).toInt();
    final baseDamage = max(0,
            baseDamageOverride ?? attacker.calculateDamageAgainst(defender)) +
        bonusDamage;
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
    var defenderAfterDamage = _effectPipeline.receiveDirectDamage(
      owner: defender,
      damage: damageDealt,
      source: attacker,
    );
    if (defenderAfterDamage.isDefeated && damageDealt > 0) {
      defenderAfterDamage = _effectPipeline.applyAbilityFatalDamageEffects(
        owner: defenderAfterDamage,
        incomingDamage: damageDealt,
      );
    }
    final barrierWasBrokenByAttack = defender.currentBarrier > 0 &&
        defenderAfterDamage.currentBarrier <= 0 &&
        damageDealt > 0;
    var updatedAttacker = attacker;
    var updatedDefender = defenderAfterDamage;
    if (triggerAttackResolvedEffects) {
      updatedAttacker = _effectPipeline.applyAttackResolvedEffects(
        owner: updatedAttacker,
        target: updatedDefender,
        damageDealt: damageDealt,
      );
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
    }
    if (barrierWasBrokenByAttack) {
      updatedDefender = updatedDefender.addCombatFlag(
        Battler.barrierBrokenThisHitFlag,
      );
    }

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
    final statusLossResolution = _effectPipeline.applyStatusLossBarrierTriggers(
      ownerBefore: attacker,
      ownerAfter: updatedAttacker,
      opponentBefore: defender,
      opponentAfter: updatedDefender,
    );
    updatedAttacker = statusLossResolution.owner;
    updatedDefender = statusLossResolution.opponent;

    // TODO: Apply thorns, damage reduction, and vampirism once combat rules are finalized.
    return BattleAttackResolution(
      attacker: updatedAttacker,
      defender: updatedDefender,
      damageDealt: damageDealt,
    );
  }

  BattleAttackResolution _resolvePuntoCiegoMissedAttack({
    required Battler attacker,
    required Battler defender,
    required bool triggerAttackResolvedEffects,
  }) {
    var updatedAttacker = attacker;
    var updatedDefender = defender;
    if (triggerAttackResolvedEffects) {
      updatedAttacker = _effectPipeline.applyAttackResolvedEffects(
        owner: updatedAttacker,
        target: updatedDefender,
        damageDealt: 0,
      );

      final attackAbilityResolution =
          _effectPipeline.applyAbilityAttackResolvedEffects(
        owner: updatedAttacker,
        target: updatedDefender,
        damageDealt: 0,
      );
      updatedAttacker = attackAbilityResolution.owner;
      updatedDefender = attackAbilityResolution.opponent;

      final attackItemResolution =
          _effectPipeline.applyEquippedItemAttackResolvedEffects(
        owner: updatedAttacker,
        target: updatedDefender,
        damageDealt: 0,
      );
      updatedAttacker = attackItemResolution.owner;
      updatedDefender = attackItemResolution.opponent;
    }

    final statusLossResolution = _effectPipeline.applyStatusLossBarrierTriggers(
      ownerBefore: attacker,
      ownerAfter: updatedAttacker,
      opponentBefore: defender,
      opponentAfter: updatedDefender,
    );

    return BattleAttackResolution(
      attacker: statusLossResolution.owner,
      defender: statusLossResolution.opponent,
      damageDealt: 0,
    );
  }
}
