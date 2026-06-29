import '_imports.dart';

class ContagioValueLossResolution {
  final Battler target;
  final Battler source;

  const ContagioValueLossResolution({
    required this.target,
    required this.source,
  });
}

/// Centraliza la resolucion de hooks de estados, habilidades e items.
class BattlerEffectPipeline {
  const BattlerEffectPipeline();

  ItemEffectResolution applyEquippedItemCombatStartEffects({
    required Battler owner,
    required Battler opponent,
    RunRandomizer? randomizer,
  }) {
    return ItemEffectDispatcher.resolvePassiveHook(
      owner: owner,
      opponent: opponent,
      hook: ItemEffectHook.combatStart,
    );
  }

  ContagioValueLossResolution applyContagioValueLostEffects({
    required Battler target,
    required Battler source,
    required BattlerStatus triggerStatus,
    required int lostValue,
    required bool wasRemoved,
  }) {
    return ContagioValueLossResolution(
      target: target.pruneExpiredStatuses(),
      source: source.pruneExpiredStatuses(),
    );
  }

  Battler receiveDirectDamage({
    required Battler owner,
    required int damage,
    required Battler source,
  }) {
    final resolution = applyIncomingDamageEffects(
      owner: owner,
      source: source,
      damage: damage,
      kind: DamageKind.direct,
    );
    return resolution.owner.receiveDamage(resolution.damage);
  }

  Battler receiveDebuffDamage({
    required Battler owner,
    required int damage,
    required Battler source,
    DamageKind kind = DamageKind.debuff,
  }) {
    final resolution = applyIncomingDamageEffects(
      owner: owner,
      source: source,
      damage: damage,
      kind: kind,
    );
    return resolution.owner.receiveDamage(resolution.damage);
  }

  Battler applyCombatEndEffects({
    required Battler owner,
  }) {
    final ownerAfterStatuses = applyStatusCombatEndEffects(owner: owner);
    final ownerAfterItems = applyEquippedItemCombatEndEffects(
      owner: ownerAfterStatuses,
    );
    return _clearCombatItemAugments(ownerAfterItems);
  }

  Battler applyStatusTurnStart({
    required Battler owner,
    required Battler opponent,
    required bool isOwnerTurn,
    RunRandomizer? randomizer,
  }) {
    final activeStatuses = List<BattlerStatus>.from(
      owner.statusesForHook(BattlerStatusHook.turnStart),
    );
    if (activeStatuses.isEmpty) return owner;
    var updatedOwner = owner;

    if (isOwnerTurn) {
      final burnDamage = activeStatuses
          .whereType<QuemaduraStatus>()
          .where((status) => !status.isExpired)
          .fold<int>(
            0,
            (total, status) => total + status.currentDamage(updatedOwner),
          );
      if (burnDamage > 0) {
        final ownerBeforeBurn = updatedOwner;
        updatedOwner = receiveDebuffDamage(
          owner: updatedOwner,
          damage: burnDamage,
          source: opponent,
          kind: DamageKind.burn,
        );
        final damageTaken = max(
          0,
          updatedOwner.barrierLostThisHit + updatedOwner.healthLostThisHit,
        );
        if (damageTaken > 0 || ownerBeforeBurn != updatedOwner) {
          final itemResolution = applyEquippedItemReceiveDamageResolvedEffects(
            owner: updatedOwner,
            source: opponent,
            damageTaken: damageTaken,
            damageKind: DamageKind.burn,
          );
          updatedOwner = itemResolution.owner;
        }
      }
    }

    for (final status in activeStatuses) {
      if (status is QuemaduraStatus) continue;

      final resolvedStatus = status.resolved(updatedOwner);
      updatedOwner = resolvedStatus.onTurnStart(
        owner: updatedOwner,
        opponent: opponent,
        isOwnerTurn: isOwnerTurn,
        randomizer: randomizer,
      );
    }

    return updatedOwner.pruneExpiredStatuses();
  }

  Battler applyStatusCombatEndEffects({
    required Battler owner,
  }) {
    final activeStatuses = List<BattlerStatus>.from(
      owner.statusesForHook(BattlerStatusHook.combatEnd),
    );
    if (activeStatuses.isEmpty) return owner;
    var updatedOwner = owner;

    for (final status in activeStatuses) {
      final matchingIndex = _findMatchingStatusIndex(
        statuses: updatedOwner.statuses,
        target: status,
      );
      if (matchingIndex < 0) continue;

      final currentStatus = updatedOwner.statuses[matchingIndex];
      updatedOwner = currentStatus.onCombatEnd(
        owner: updatedOwner,
      );
    }

    return updatedOwner.pruneExpiredStatuses();
  }

  Battler applyStatusTurnEnd({
    required Battler owner,
    required Battler opponent,
    required bool isOwnerTurn,
    RunRandomizer? randomizer,
  }) {
    final activeStatuses = List<BattlerStatus>.from(
      owner.statusesForHook(BattlerStatusHook.turnEnd),
    );
    if (activeStatuses.isEmpty) return owner;
    var updatedOwner = owner;

    for (final status in activeStatuses) {
      final resolvedStatus = status.resolved(updatedOwner);
      updatedOwner = resolvedStatus.onTurnEnd(
        owner: updatedOwner,
        opponent: opponent,
        isOwnerTurn: isOwnerTurn,
        randomizer: randomizer,
      );
    }

    return updatedOwner.pruneExpiredStatuses();
  }

  int applyOutgoingDamageModifiers({
    required Battler owner,
    required Battler target,
    required int damage,
  }) {
    var updatedDamage = damage;

    for (final status
        in owner.statusesForHook(BattlerStatusHook.outgoingDamageModifier)) {
      final resolvedStatus = status.resolved(owner);
      updatedDamage = resolvedStatus.modifyOutgoingDamage(
        owner: owner,
        target: target,
        damage: updatedDamage,
      );
    }

    return max(0, updatedDamage);
  }

  int applyEquippedItemOutgoingDamageModifiers({
    required Battler owner,
    required Battler target,
    required int damage,
  }) {
    var updatedDamage = damage;

    for (final item
        in owner.equippedItemsForHook(ItemEffectHook.outgoingDamageModifier)) {
      for (final effect in item.passiveEffects.where(
        (effect) => effect.hook == ItemEffectHook.outgoingDamageModifier,
      )) {
        switch (effect.effectKey) {
          case ItemEffectKeys.bloodflameGauntletLowHpDamage:
            if (owner.health * 2 < owner.maxHealth) {
              updatedDamage += effect.value * (_burnValue(owner) > 0 ? 2 : 1);
            }
            break;
          case ItemEffectKeys.crownOfTheBlackSunBurnScaling:
            updatedDamage +=
                effect.value * (_burnValue(owner) + _burnValue(target));
            break;
          case ItemEffectKeys.rampartRamBarrierDamage:
            updatedDamage += effect.value * (owner.currentBarrier ~/ 10);
            break;
          default:
            updatedDamage += effect.value;
            break;
        }
      }
    }

    return max(0, updatedDamage);
  }

  BattlerStatus? applyEquippedItemOutgoingStatusModifiers({
    required Battler owner,
    required Battler target,
    required BattlerStatus status,
  }) {
    return status;
  }

  int applyIncomingDamageModifiers({
    required Battler owner,
    required Battler source,
    required int damage,
  }) {
    var updatedDamage = damage;

    for (final status
        in owner.statusesForHook(BattlerStatusHook.incomingDamageModifier)) {
      final resolvedStatus = status.resolved(owner);
      updatedDamage = resolvedStatus.modifyIncomingDamage(
        owner: owner,
        source: source,
        damage: updatedDamage,
      );
    }

    return max(0, updatedDamage);
  }

  BattlerIncomingDamageResolution applyIncomingDamageEffects({
    required Battler owner,
    required Battler source,
    required int damage,
    required DamageKind kind,
  }) {
    var updatedOwner = owner;
    var updatedDamage = damage;
    final activeStatuses = List<BattlerStatus>.from(
      owner.statusesForHook(BattlerStatusHook.incomingDamageEffect),
    );

    for (final status in activeStatuses) {
      final matchingIndex = _findMatchingStatusIndex(
        statuses: updatedOwner.statuses,
        target: status,
      );
      if (matchingIndex < 0) continue;

      final resolvedStatus = updatedOwner.statuses[matchingIndex].resolved(
        updatedOwner,
      );
      final resolution = resolvedStatus.onIncomingDamage(
        owner: updatedOwner,
        source: source,
        damage: updatedDamage,
        kind: kind,
      );
      updatedOwner = resolution.owner;
      updatedDamage = resolution.damage;
    }

    return BattlerIncomingDamageResolution(
      owner: updatedOwner.pruneExpiredStatuses(),
      damage: max(0, updatedDamage),
    );
  }

  int applyEquippedItemIncomingDamageModifiers({
    required Battler owner,
    required Battler source,
    required int damage,
  }) {
    var updatedDamage = damage;

    for (final item
        in owner.equippedItemsForHook(ItemEffectHook.incomingDamageModifier)) {
      for (final effect in item.passiveEffects.where(
        (effect) => effect.hook == ItemEffectHook.incomingDamageModifier,
      )) {
        updatedDamage -= effect.value;
      }
    }

    return max(0, updatedDamage);
  }

  BattlerStatus? applyEquippedItemIncomingStatusModifiers({
    required Battler owner,
    required Battler source,
    required BattlerStatus status,
  }) {
    return applyEquippedItemIncomingStatusEffects(
      owner: owner,
      source: source,
      status: status,
    ).status;
  }

  ItemIncomingStatusResolution applyEquippedItemIncomingStatusEffects({
    required Battler owner,
    required Battler source,
    required BattlerStatus status,
  }) {
    return ItemIncomingStatusResolution(
      owner: owner,
      source: source,
      status: status,
    );
  }

  Battler applyAttackResolvedEffects({
    required Battler owner,
    required Battler target,
    required int damageDealt,
  }) {
    final activeStatuses = List<BattlerStatus>.from(
      owner.statusesForHook(BattlerStatusHook.attackResolved),
    );
    if (activeStatuses.isEmpty) return owner;
    var updatedOwner = owner;

    for (final status in activeStatuses) {
      final resolvedStatus = status.resolved(updatedOwner);
      updatedOwner = resolvedStatus.onAttackResolved(
        owner: updatedOwner,
        target: target,
        damageDealt: damageDealt,
      );
    }

    return updatedOwner.pruneExpiredStatuses();
  }

  ItemEffectResolution applyEquippedItemAttackResolvedEffects({
    required Battler owner,
    required Battler target,
    required int damageDealt,
    Item? sourceItem,
  }) {
    return ItemEffectDispatcher.resolvePassiveHook(
      owner: owner,
      opponent: target,
      hook: ItemEffectHook.attackResolved,
      damageDealt: damageDealt,
      sourceItem: sourceItem,
    );
  }

  Battler applyReceiveDamageResolvedEffects({
    required Battler owner,
    required Battler source,
    required int damageTaken,
  }) {
    final activeStatuses = List<BattlerStatus>.from(
      owner.statusesForHook(BattlerStatusHook.receiveDamageResolved),
    );
    if (activeStatuses.isEmpty) return owner;
    var updatedOwner = owner;

    for (final status in activeStatuses) {
      final resolvedStatus = status.resolved(updatedOwner);
      updatedOwner = resolvedStatus.onReceiveDamageResolved(
        owner: updatedOwner,
        source: source,
        damageTaken: damageTaken,
      );
    }

    return updatedOwner.pruneExpiredStatuses();
  }

  ItemEffectResolution applyEquippedItemReceiveDamageResolvedEffects({
    required Battler owner,
    required Battler source,
    required int damageTaken,
    DamageKind damageKind = DamageKind.direct,
  }) {
    return ItemEffectDispatcher.resolvePassiveHook(
      owner: owner,
      opponent: source,
      hook: ItemEffectHook.receiveDamageResolved,
      damageTaken: damageTaken,
      damageKind: damageKind,
    );
  }

  ItemEffectResolution applyEquippedItemTurnStartEffects({
    required Battler owner,
    required Battler opponent,
    required bool isOwnerTurn,
    RunRandomizer? randomizer,
  }) {
    return ItemEffectDispatcher.resolvePassiveHook(
      owner: owner,
      opponent: opponent,
      hook: ItemEffectHook.turnStart,
      isOwnerTurn: isOwnerTurn,
    );
  }

  ItemEffectResolution applyEquippedItemTurnEndEffects({
    required Battler owner,
    required Battler opponent,
    required bool isOwnerTurn,
    RunRandomizer? randomizer,
  }) {
    return ItemEffectDispatcher.resolvePassiveHook(
      owner: owner,
      opponent: opponent,
      hook: ItemEffectHook.turnEnd,
    );
  }

  ItemEffectResolution applyEquippedItemDefendResolvedEffects({
    required Battler owner,
    required Battler opponent,
  }) {
    return ItemEffectDispatcher.resolvePassiveHook(
      owner: owner,
      opponent: opponent,
      hook: ItemEffectHook.defendResolved,
    );
  }

  ItemEffectResolution applyEquippedItemPatternUsedEffects({
    required Battler owner,
    required Battler opponent,
    required BattlePatternMatchContext pattern,
  }) {
    return ItemEffectDispatcher.resolvePassiveHook(
      owner: owner,
      opponent: opponent,
      hook: ItemEffectHook.patternUsed,
      pattern: pattern,
    );
  }

  /// Ejecuta el efecto Al usarse de un unico item en el instante exacto en
  /// que su punto se recorre. Esto evita que efectos de otros puntos se
  /// mezclen con la accion actual.
  ItemEffectResolution applyEquippedItemPatternUsedEffect({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required BattlePatternMatchContext pattern,
  }) {
    return ItemEffectDispatcher.resolvePassiveHook(
      owner: owner,
      opponent: opponent,
      hook: ItemEffectHook.patternUsed,
      onlyItem: item,
      pattern: pattern,
    );
  }

  ItemEffectResolution applyEquippedItemPrePatternAttackEffects({
    required Battler owner,
    required Battler opponent,
    required BattlePatternMatchContext pattern,
  }) {
    return ItemEffectDispatcher.resolvePassiveHook(
      owner: owner,
      opponent: opponent,
      hook: ItemEffectHook.prePatternAttack,
    );
  }

  ItemEffectResolution applyEquippedItemForcedPatternUsedEffects({
    required Battler owner,
    required Battler opponent,
  }) {
    return ItemEffectDispatcher.resolvePassiveHook(
      owner: owner,
      opponent: opponent,
      hook: ItemEffectHook.patternUsed,
    );
  }

  Battler applyEquippedItemCombatEndEffects({
    required Battler owner,
  }) {
    return owner;
  }

  ItemEffectResolution applyEquippedItemPassiveEffects({
    required Battler owner,
    required Battler opponent,
  }) {
    return ItemEffectDispatcher.resolvePassiveHook(
      owner: owner,
      opponent: opponent,
      hook: ItemEffectHook.passive,
    );
  }

  Battler applyEquippedItemFatalDamageEffects({
    required Battler owner,
    required int incomingDamage,
  }) {
    return owner;
  }

  ItemEffectResolution applyStatusLossBarrierTriggers({
    required Battler ownerBefore,
    required Battler ownerAfter,
    required Battler opponentBefore,
    required Battler opponentAfter,
  }) {
    return ItemEffectResolution(
      owner: ownerAfter,
      opponent: opponentAfter,
    );
  }

  int _findMatchingStatusIndex({
    required List<BattlerStatus> statuses,
    required BattlerStatus target,
  }) {
    return statuses.indexWhere(
      (activeStatus) =>
          identical(activeStatus, target) ||
          (activeStatus.runtimeType == target.runtimeType &&
              activeStatus.id == target.id &&
              activeStatus.remainingTurns == target.remainingTurns &&
              activeStatus.value == target.value),
    );
  }
}

Battler _clearCombatItemAugments(Battler owner) {
  return owner;
}

int _burnValue(Battler owner) {
  return owner.statusesById(QuemaduraStatus.statusId).fold<int>(
        0,
        (total, status) => total + max(0, status.resolved(owner).value),
      );
}
