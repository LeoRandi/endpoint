import '_imports.dart';

class BattleAttackResolution {
  final Battler attacker;
  final Battler defender;
  final int damageDealt;
  final List<ItemFollowUpAction> followUpItemActions;

  const BattleAttackResolution({
    required this.attacker,
    required this.defender,
    required this.damageDealt,
    this.followUpItemActions = const <ItemFollowUpAction>[],
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
    Item? sourceItem,
  }) {
    if (defender.hasStatus(PuntoCiegoStatus.statusId)) {
      return _resolvePuntoCiegoMissedAttack(
        attacker: attacker,
        defender: defender,
        triggerAttackResolvedEffects: triggerAttackResolvedEffects,
        sourceItem: sourceItem,
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
    final outgoingModifiedDamage =
        _effectPipeline.applyEquippedItemOutgoingDamageModifiers(
      owner: attacker,
      target: defender,
      damage: outgoingStatusModifiedDamage,
    );
    final incomingStatusModifiedDamage =
        _effectPipeline.applyIncomingDamageModifiers(
      owner: defender,
      source: attacker,
      damage: outgoingModifiedDamage,
    );
    final damageDealt =
        _effectPipeline.applyEquippedItemIncomingDamageModifiers(
      owner: defender,
      source: attacker,
      damage: incomingStatusModifiedDamage,
    );
    var defenderAfterDamage = _effectPipeline.receiveDirectDamage(
      owner: defender,
      damage: damageDealt,
      source: attacker,
    );
    final barrierWasBrokenByAttack = defender.currentBarrier > 0 &&
        defenderAfterDamage.currentBarrier <= 0 &&
        damageDealt > 0;
    var updatedAttacker = attacker;
    var updatedDefender = defenderAfterDamage;
    var followUpItemActions = const <ItemFollowUpAction>[];
    if (triggerAttackResolvedEffects) {
      updatedAttacker = _effectPipeline.applyAttackResolvedEffects(
        owner: updatedAttacker,
        target: updatedDefender,
        damageDealt: damageDealt,
      );
      final attackItemResolution =
          _effectPipeline.applyEquippedItemAttackResolvedEffects(
        owner: updatedAttacker,
        target: updatedDefender,
        damageDealt: damageDealt,
        sourceItem: sourceItem,
      );
      updatedAttacker = attackItemResolution.owner;
      updatedDefender = attackItemResolution.opponent;
      followUpItemActions = attackItemResolution.followUpItemActions;
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
      followUpItemActions: followUpItemActions,
    );
  }

  BattleAttackResolution _resolvePuntoCiegoMissedAttack({
    required Battler attacker,
    required Battler defender,
    required bool triggerAttackResolvedEffects,
    Item? sourceItem,
  }) {
    var updatedAttacker = attacker;
    var updatedDefender = defender;
    var followUpItemActions = const <ItemFollowUpAction>[];
    if (triggerAttackResolvedEffects) {
      updatedAttacker = _effectPipeline.applyAttackResolvedEffects(
        owner: updatedAttacker,
        target: updatedDefender,
        damageDealt: 0,
      );

      final attackItemResolution =
          _effectPipeline.applyEquippedItemAttackResolvedEffects(
        owner: updatedAttacker,
        target: updatedDefender,
        damageDealt: 0,
        sourceItem: sourceItem,
      );
      updatedAttacker = attackItemResolution.owner;
      updatedDefender = attackItemResolution.opponent;
      followUpItemActions = attackItemResolution.followUpItemActions;
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
      followUpItemActions: followUpItemActions,
    );
  }
}
