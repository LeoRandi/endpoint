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

  Battler applyAbilityHourStartEffects({
    required Battler owner,
  }) {
    final activeAbilityIds = List<BattlerAbilityId>.from(
      owner.abilityIdsForHook(BattlerAbilityHook.hourStart),
    );
    if (activeAbilityIds.isEmpty) return owner;

    var updatedOwner = owner;

    for (final abilityId in activeAbilityIds) {
      final ability = updatedOwner.abilityById(abilityId);
      final effect = ability?.effect;
      if (ability == null || effect == null) continue;

      updatedOwner = effect.onHourStart(
        owner: updatedOwner,
        ability: ability,
      );
    }

    return updatedOwner.pruneExpiredStatuses();
  }

  Battler applyAbilityCombatStartEffects({
    required Battler owner,
  }) {
    final activeAbilityIds = List<BattlerAbilityId>.from(
      owner.abilityIdsForHook(BattlerAbilityHook.combatStart),
    );
    if (activeAbilityIds.isEmpty) return owner;

    var updatedOwner = owner;

    for (final abilityId in activeAbilityIds) {
      final ability = updatedOwner.abilityById(abilityId);
      final effect = ability?.effect;
      if (ability == null || effect == null) continue;

      updatedOwner = effect.onCombatStart(
        owner: updatedOwner,
        ability: ability,
      );
    }

    return updatedOwner.pruneExpiredStatuses();
  }

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

  BattlerAbilityEffectResolution applyAbilityCombatStartOpponentEffects({
    required Battler owner,
    required Battler opponent,
  }) {
    var updatedOwner = owner;
    var updatedOpponent = opponent;

    final activeAbilityIds = List<BattlerAbilityId>.from(
      owner.abilityIdsForHook(BattlerAbilityHook.combatStartOpponent),
    );

    for (final abilityId in activeAbilityIds) {
      final ability = updatedOwner.abilityById(abilityId);
      final effect = ability?.effect;
      if (ability == null || effect == null) continue;

      final resolution = effect.onCombatStartOpponent(
        owner: updatedOwner,
        opponent: updatedOpponent,
        ability: ability,
      );
      updatedOwner = resolution.owner;
      updatedOpponent = resolution.opponent;
    }

    return BattlerAbilityEffectResolution(
      owner: updatedOwner.pruneExpiredStatuses(),
      opponent: updatedOpponent.pruneExpiredStatuses(),
    );
  }

  ContagioValueLossResolution applyContagioValueLostEffects({
    required Battler target,
    required Battler source,
    required BattlerStatus triggerStatus,
    required int lostValue,
    required bool wasRemoved,
  }) {
    var updatedTarget = target;
    var updatedSource = source;

    for (final abilityId in updatedTarget
        .abilityIdsForHook(BattlerAbilityHook.contagioValueLost)) {
      final ability = updatedTarget.abilityById(abilityId);
      final effect = ability?.effect;
      if (ability == null || effect == null) continue;

      final resolution = effect.onContagioValueLost(
        owner: updatedTarget,
        opponent: updatedSource,
        ability: ability,
        lostValue: lostValue,
        isOwnerContagioCarrier: true,
        wasRemoved: wasRemoved,
        triggerStatus: triggerStatus,
      );
      updatedTarget = resolution.owner;
      updatedSource = resolution.opponent;
    }

    for (final abilityId in updatedSource
        .abilityIdsForHook(BattlerAbilityHook.contagioValueLost)) {
      final ability = updatedSource.abilityById(abilityId);
      final effect = ability?.effect;
      if (ability == null || effect == null) continue;

      final resolution = effect.onContagioValueLost(
        owner: updatedSource,
        opponent: updatedTarget,
        ability: ability,
        lostValue: lostValue,
        isOwnerContagioCarrier: false,
        wasRemoved: wasRemoved,
        triggerStatus: triggerStatus,
      );
      updatedSource = resolution.owner;
      updatedTarget = resolution.opponent;
    }

    return ContagioValueLossResolution(
      target: updatedTarget.pruneExpiredStatuses(),
      source: updatedSource.pruneExpiredStatuses(),
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
    final ownerAfterAbilities = applyAbilityCombatEndEffects(
      owner: ownerAfterItems,
    );
    return _clearCombatItemAugments(ownerAfterAbilities);
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
        updatedOwner = receiveDebuffDamage(
          owner: updatedOwner,
          damage: burnDamage,
          source: opponent,
          kind: DamageKind.burn,
        );
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

  BattlerAbilityEffectResolution applyAbilityTurnStartEffects({
    required Battler owner,
    required Battler opponent,
    required bool isOwnerTurn,
  }) {
    final activeAbilityIds = List<BattlerAbilityId>.from(
      owner.abilityIdsForHook(BattlerAbilityHook.turnStart),
    );
    if (activeAbilityIds.isEmpty) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
    }

    var updatedOwner = owner;
    var updatedOpponent = opponent;

    for (final abilityId in activeAbilityIds) {
      final previousAbility = updatedOwner.abilityById(abilityId);
      final effect = previousAbility?.effect;
      if (previousAbility == null || effect == null) continue;

      final resolution = effect.onTurnStart(
        owner: updatedOwner,
        opponent: updatedOpponent,
        ability: previousAbility,
        isOwnerTurn: isOwnerTurn,
      );
      updatedOwner = resolution.owner;
      updatedOpponent = resolution.opponent;
      updatedOwner = _applyRegulatedOverloadCooldownPenalty(
        owner: updatedOwner,
        previousAbility: previousAbility,
      );

      final itemResolution = applyEquippedItemAbilityResolvedEffects(
        owner: updatedOwner,
        opponent: updatedOpponent,
        previousAbility: previousAbility,
        context: ItemAbilityResolutionContext.turnStart,
      );
      updatedOwner = itemResolution.owner;
      updatedOpponent = itemResolution.opponent;
    }

    return BattlerAbilityEffectResolution(
      owner: updatedOwner.pruneExpiredStatuses(),
      opponent: updatedOpponent.pruneExpiredStatuses(),
    );
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

  BattlerAbilityEffectResolution applyAbilityTurnEndEffects({
    required Battler owner,
    required Battler opponent,
    required bool isOwnerTurn,
  }) {
    final activeAbilityIds = List<BattlerAbilityId>.from(
      owner.abilityIdsForHook(BattlerAbilityHook.turnEnd),
    );
    if (activeAbilityIds.isEmpty) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
    }

    var updatedOwner = owner;
    var updatedOpponent = opponent;

    for (final abilityId in activeAbilityIds) {
      final previousAbility = updatedOwner.abilityById(abilityId);
      final effect = previousAbility?.effect;
      if (previousAbility == null || effect == null) continue;

      final resolution = effect.onTurnEnd(
        owner: updatedOwner,
        opponent: updatedOpponent,
        ability: previousAbility,
        isOwnerTurn: isOwnerTurn,
      );
      updatedOwner = resolution.owner;
      updatedOpponent = resolution.opponent;
      updatedOwner = _applyRegulatedOverloadCooldownPenalty(
        owner: updatedOwner,
        previousAbility: previousAbility,
      );

      final itemResolution = applyEquippedItemAbilityResolvedEffects(
        owner: updatedOwner,
        opponent: updatedOpponent,
        previousAbility: previousAbility,
        context: ItemAbilityResolutionContext.turnEnd,
      );
      updatedOwner = itemResolution.owner;
      updatedOpponent = itemResolution.opponent;
    }

    return BattlerAbilityEffectResolution(
      owner: updatedOwner.pruneExpiredStatuses(),
      opponent: updatedOpponent.pruneExpiredStatuses(),
    );
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
        updatedDamage += effect.value;
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

  int applyAbilityOutgoingDamageModifiers({
    required Battler owner,
    required Battler target,
    required int damage,
  }) {
    var updatedDamage = damage;

    for (final abilityId
        in owner.abilityIdsForHook(BattlerAbilityHook.outgoingDamageModifier)) {
      final ability = owner.abilityById(abilityId);
      if (ability == null) continue;
      final effect = ability.effect;
      if (effect == null) continue;

      updatedDamage = effect.modifyOutgoingDamage(
        owner: owner,
        target: target,
        ability: ability,
        damage: updatedDamage,
      );
    }

    return max(0, updatedDamage);
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

    final activeAbilityIds = List<BattlerAbilityId>.from(
      updatedOwner.abilityIdsForHook(BattlerAbilityHook.incomingDamageEffect),
    );
    for (final abilityId in activeAbilityIds) {
      final ability = updatedOwner.abilityById(abilityId);
      final effect = ability?.effect;
      if (ability == null || effect == null) continue;

      final resolution = effect.onIncomingDamage(
        owner: updatedOwner,
        source: source,
        ability: ability,
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

  BattlerAbilityIncomingStatusResolution applyAbilityIncomingStatusEffects({
    required Battler owner,
    required Battler source,
    required BattlerStatus status,
  }) {
    var updatedOwner = owner;
    var updatedSource = source;
    BattlerStatus? updatedStatus = status;

    final activeAbilityIds = List<BattlerAbilityId>.from(
      owner.abilityIdsForHook(BattlerAbilityHook.incomingStatusModifier),
    );

    for (final abilityId in activeAbilityIds) {
      final ability = updatedOwner.abilityById(abilityId);
      final effect = ability?.effect;
      if (ability == null || effect == null || updatedStatus == null) {
        continue;
      }

      final resolution = effect.onIncomingStatus(
        owner: updatedOwner,
        source: updatedSource,
        ability: ability,
        status: updatedStatus,
      );
      updatedOwner = resolution.owner;
      updatedSource = resolution.source;
      updatedStatus = resolution.status;
    }

    return BattlerAbilityIncomingStatusResolution(
      owner: updatedOwner.pruneExpiredStatuses(),
      source: updatedSource.pruneExpiredStatuses(),
      status: updatedStatus,
    );
  }

  int applyAbilityIncomingDamageModifiers({
    required Battler owner,
    required Battler source,
    required int damage,
  }) {
    var updatedDamage = damage;

    for (final abilityId
        in owner.abilityIdsForHook(BattlerAbilityHook.incomingDamageModifier)) {
      final ability = owner.abilityById(abilityId);
      if (ability == null) continue;
      final effect = ability.effect;
      if (effect == null) continue;

      updatedDamage = effect.modifyIncomingDamage(
        owner: owner,
        source: source,
        ability: ability,
        damage: updatedDamage,
      );
    }

    return max(0, updatedDamage);
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
  }) {
    return ItemEffectDispatcher.resolvePassiveHook(
      owner: owner,
      opponent: target,
      hook: ItemEffectHook.attackResolved,
    );
  }

  BattlerAbilityEffectResolution applyAbilityAttackResolvedEffects({
    required Battler owner,
    required Battler target,
    required int damageDealt,
  }) {
    final activeAbilityIds =
        BattlerEffectPriorityPolicy.orderAbilityIdsForEvent(
      event: BattlerEffectEvent.attackResolved,
      owner: owner,
      abilityIds: owner.abilityIdsForHook(BattlerAbilityHook.attackResolved),
    );
    if (activeAbilityIds.isEmpty) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: target);
    }

    var updatedOwner = owner;
    var updatedTarget = target;

    for (final abilityId in activeAbilityIds) {
      final previousAbility = updatedOwner.abilityById(abilityId);
      final effect = previousAbility?.effect;
      if (previousAbility == null || effect == null) continue;

      final resolution = effect.onAttackResolved(
        owner: updatedOwner,
        target: updatedTarget,
        ability: previousAbility,
        damageDealt: damageDealt,
      );
      updatedOwner = resolution.owner;
      updatedTarget = resolution.opponent;
      updatedOwner = _applyRegulatedOverloadCooldownPenalty(
        owner: updatedOwner,
        previousAbility: previousAbility,
      );

      final itemResolution = applyEquippedItemAbilityResolvedEffects(
        owner: updatedOwner,
        opponent: updatedTarget,
        previousAbility: previousAbility,
        context: ItemAbilityResolutionContext.attackResolved,
      );
      updatedOwner = itemResolution.owner;
      updatedTarget = itemResolution.opponent;
    }

    return BattlerAbilityEffectResolution(
      owner: updatedOwner.pruneExpiredStatuses(),
      opponent: updatedTarget.pruneExpiredStatuses(),
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
  }) {
    return ItemEffectDispatcher.resolvePassiveHook(
      owner: owner,
      opponent: source,
      hook: ItemEffectHook.receiveDamageResolved,
    );
  }

  BattlerAbilityEffectResolution applyAbilityReceiveDamageResolvedEffects({
    required Battler owner,
    required Battler source,
    required int damageTaken,
  }) {
    final activeAbilityIds = List<BattlerAbilityId>.from(
      owner.abilityIdsForHook(BattlerAbilityHook.receiveDamageResolved),
    );
    if (activeAbilityIds.isEmpty) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: source);
    }

    var updatedOwner = owner;
    var updatedSource = source;

    for (final abilityId in activeAbilityIds) {
      final previousAbility = updatedOwner.abilityById(abilityId);
      final effect = previousAbility?.effect;
      if (previousAbility == null || effect == null) continue;

      final resolution = effect.onReceiveDamageResolved(
        owner: updatedOwner,
        source: updatedSource,
        ability: previousAbility,
        damageTaken: damageTaken,
      );
      updatedOwner = resolution.owner;
      updatedSource = resolution.opponent;
      updatedOwner = _applyRegulatedOverloadCooldownPenalty(
        owner: updatedOwner,
        previousAbility: previousAbility,
      );

      final itemResolution = applyEquippedItemAbilityResolvedEffects(
        owner: updatedOwner,
        opponent: updatedSource,
        previousAbility: previousAbility,
        context: ItemAbilityResolutionContext.receiveDamageResolved,
      );
      updatedOwner = itemResolution.owner;
      updatedSource = itemResolution.opponent;
    }

    return BattlerAbilityEffectResolution(
      owner: updatedOwner.pruneExpiredStatuses(),
      opponent: updatedSource.pruneExpiredStatuses(),
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

  ItemAbilityPreparationResolution applyEquippedItemManualAbilityPreparation({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlerAbilityActivationContext screenContext,
  }) {
    return ItemAbilityPreparationResolution(
      owner: owner,
      opponent: opponent,
      ability: ability,
    );
  }

  ItemEffectResolution applyEquippedItemAbilityResolvedEffects({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility previousAbility,
    required ItemAbilityResolutionContext context,
  }) {
    return ItemEffectDispatcher.resolvePassiveHook(
      owner: owner,
      opponent: opponent,
      hook: ItemEffectHook.abilityResolved,
    );
  }

  BattlerAbilityEffectResolution applyAbilityPatternMatchResolvedEffects({
    required Battler owner,
    required Battler opponent,
    required BattlePatternMatchContext pattern,
  }) {
    final activeAbilityIds =
        BattlerEffectPriorityPolicy.orderAbilityIdsForEvent(
      event: BattlerEffectEvent.patternMatchResolved,
      owner: owner,
      abilityIds:
          owner.abilityIdsForHook(BattlerAbilityHook.patternMatchResolved),
    );
    if (activeAbilityIds.isEmpty) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
    }

    var updatedOwner = owner;
    var updatedOpponent = opponent;

    for (final abilityId in activeAbilityIds) {
      final previousAbility = updatedOwner.abilityById(abilityId);
      final effect = previousAbility?.effect;
      if (previousAbility == null || effect == null) continue;

      final resolution = effect.onPatternMatchResolved(
        owner: updatedOwner,
        opponent: updatedOpponent,
        ability: previousAbility,
        pattern: pattern,
      );
      final debuffPressureBefore = _debuffPressure(updatedOpponent);
      updatedOwner = resolution.owner;
      updatedOpponent = resolution.opponent;
      updatedOwner = _applyRegulatedOverloadCooldownPenalty(
        owner: updatedOwner,
        previousAbility: previousAbility,
      );
      final debuffPressureResolution = _resolveDebuffPressureTriggers(
        owner: updatedOwner,
        opponent: updatedOpponent,
        debuffPressureBefore: debuffPressureBefore,
        skipCadenaNeurotoxica: abilityId == BattlerAbilityId.cadenaNeurotoxica,
      );
      updatedOwner = debuffPressureResolution.owner;
      updatedOpponent = debuffPressureResolution.opponent;

      final itemResolution = applyEquippedItemAbilityResolvedEffects(
        owner: updatedOwner,
        opponent: updatedOpponent,
        previousAbility: previousAbility,
        context: ItemAbilityResolutionContext.patternMatchResolved,
      );
      updatedOwner = itemResolution.owner;
      updatedOpponent = itemResolution.opponent;
    }

    return BattlerAbilityEffectResolution(
      owner: updatedOwner.pruneExpiredStatuses(),
      opponent: updatedOpponent.pruneExpiredStatuses(),
    );
  }

  BattlerAbilityEffectResolution applyAbilityPassiveEffects({
    required Battler owner,
    required Battler opponent,
  }) {
    final activeAbilityIds = List<BattlerAbilityId>.from(
      owner.abilityIdsForHook(BattlerAbilityHook.passive),
    );
    if (activeAbilityIds.isEmpty) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
    }

    var updatedOwner = owner;
    var updatedOpponent = opponent;

    for (final abilityId in activeAbilityIds) {
      final resolvedAbility = updatedOwner.abilityById(abilityId);
      final effect = resolvedAbility?.effect;
      if (resolvedAbility == null || effect == null) continue;

      final resolution = effect.applyPassive(
        owner: updatedOwner,
        opponent: updatedOpponent,
        ability: resolvedAbility,
      );
      updatedOwner = resolution.owner;
      updatedOpponent = resolution.opponent;
    }

    return BattlerAbilityEffectResolution(
      owner: updatedOwner.pruneExpiredStatuses(),
      opponent: updatedOpponent.pruneExpiredStatuses(),
    );
  }

  Battler applyAbilityCombatEndEffects({
    required Battler owner,
  }) {
    final activeAbilityIds = List<BattlerAbilityId>.from(
      owner.abilityIdsForHook(BattlerAbilityHook.combatEnd),
    );
    if (activeAbilityIds.isEmpty) return owner;
    var updatedOwner = owner;

    for (final abilityId in activeAbilityIds) {
      final currentAbility = updatedOwner.abilityById(abilityId);
      final effect = currentAbility?.effect;
      if (currentAbility == null || effect == null) continue;

      updatedOwner = effect.onCombatEnd(
        owner: updatedOwner,
        ability: currentAbility,
      );
    }

    return updatedOwner.pruneExpiredStatuses();
  }

  Battler applyEquippedItemFatalDamageEffects({
    required Battler owner,
    required int incomingDamage,
  }) {
    return owner;
  }

  Battler applyAbilityFatalDamageEffects({
    required Battler owner,
    required int incomingDamage,
  }) {
    var updatedOwner = owner;

    final activeAbilityIds = List<BattlerAbilityId>.from(
      owner.abilityIdsForHook(BattlerAbilityHook.fatalDamage),
    );

    for (final abilityId in activeAbilityIds) {
      final ability = updatedOwner.abilityById(abilityId);
      final effect = ability?.effect;
      if (ability == null || effect == null) continue;

      updatedOwner = effect.onReceiveFatalDamage(
        owner: updatedOwner,
        ability: ability,
        incomingDamage: incomingDamage,
      );
      if (updatedOwner.health > 0) {
        break;
      }
    }

    return updatedOwner.pruneExpiredStatuses();
  }

  BattlerAbilityEffectResolution applyStatusLossBarrierTriggers({
    required Battler ownerBefore,
    required Battler ownerAfter,
    required Battler opponentBefore,
    required Battler opponentAfter,
  }) {
    var updatedOwner = ownerAfter;
    var updatedOpponent = opponentAfter;

    updatedOwner = _applyOpresionTacticaStatusLossTrigger(
      abilityOwnerBefore: ownerBefore,
      abilityOwnerAfter: updatedOwner,
      opponentBefore: opponentBefore,
      opponentAfter: updatedOpponent,
    );
    updatedOpponent = _applyOpresionTacticaStatusLossTrigger(
      abilityOwnerBefore: opponentBefore,
      abilityOwnerAfter: updatedOpponent,
      opponentBefore: ownerBefore,
      opponentAfter: updatedOwner,
    );

    return BattlerAbilityEffectResolution(
      owner: updatedOwner,
      opponent: updatedOpponent,
    );
  }

  BattlerAbilityEffectResolution toggleAbilityActivation({
    required Battler owner,
    required BattlerAbilityId abilityId,
    required BattlerAbilityActivationContext screenContext,
    Battler? opponent,
  }) {
    final currentAbility = owner.abilityById(abilityId);
    final resolvedOpponent = opponent ?? owner;
    if (currentAbility == null || !currentAbility.canToggleOn(screenContext)) {
      return BattlerAbilityEffectResolution(
        owner: owner,
        opponent: resolvedOpponent,
      );
    }

    if (currentAbility.canDeactivateOn(screenContext)) {
      return BattlerAbilityEffectResolution(
        owner: owner.updateAbility(currentAbility.deactivate()),
        opponent: resolvedOpponent,
      );
    }

    if (!currentAbility.canActivateOn(screenContext) ||
        !currentAbility.isImplemented) {
      return BattlerAbilityEffectResolution(
        owner: owner,
        opponent: resolvedOpponent,
      );
    }
    if (!owner.canActivateManualAbilities(screenContext)) {
      return BattlerAbilityEffectResolution(
        owner: owner,
        opponent: resolvedOpponent,
      );
    }

    var activatedOwner = owner.updateAbility(currentAbility.activate());
    if (screenContext == BattlerAbilityActivationContext.battle) {
      activatedOwner = activatedOwner.addCombatFlag(
        Battler.manualAbilityActivatedThisTurnFlag,
      );
    }
    var updatedOpponent = resolvedOpponent;
    var activatedAbility = activatedOwner.abilityById(abilityId);
    if (activatedAbility == null) {
      return BattlerAbilityEffectResolution(
        owner: activatedOwner,
        opponent: updatedOpponent,
      );
    }

    final preparation = applyEquippedItemManualAbilityPreparation(
      owner: activatedOwner,
      opponent: updatedOpponent,
      ability: activatedAbility,
      screenContext: screenContext,
    );
    activatedOwner = preparation.owner;
    updatedOpponent = preparation.opponent;
    activatedAbility = preparation.ability;

    final effect = activatedAbility.effect;
    if (effect == null) {
      final itemResolution = applyEquippedItemAbilityResolvedEffects(
        owner: activatedOwner,
        opponent: updatedOpponent,
        previousAbility: currentAbility,
        context: ItemAbilityResolutionContext.manualActivation,
      );
      return applyStatusLossBarrierTriggers(
        ownerBefore: owner,
        ownerAfter: itemResolution.owner,
        opponentBefore: resolvedOpponent,
        opponentAfter: itemResolution.opponent,
      );
    }

    final abilityResolution = effect.onManualActivation(
      owner: activatedOwner,
      opponent: updatedOpponent,
      ability: activatedAbility,
      screenContext: screenContext,
    );
    final ownerAfterPenalty = _applyRegulatedOverloadCooldownPenalty(
      owner: abilityResolution.owner,
      previousAbility: currentAbility,
    );
    final itemResolution = applyEquippedItemAbilityResolvedEffects(
      owner: ownerAfterPenalty,
      opponent: abilityResolution.opponent,
      previousAbility: currentAbility,
      context: ItemAbilityResolutionContext.manualActivation,
    );

    return applyStatusLossBarrierTriggers(
      ownerBefore: owner,
      ownerAfter: itemResolution.owner,
      opponentBefore: resolvedOpponent,
      opponentAfter: itemResolution.opponent,
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

  Battler _applyRegulatedOverloadCooldownPenalty({
    required Battler owner,
    required BattlerAbility previousAbility,
  }) {
    if (previousAbility.id == BattlerAbilityId.sobrecargaRegulada ||
        previousAbility.manualActivationContext == null ||
        !owner.hasCombatFlag(
          const CombatRuntimeFlag.battler(
            BattlerCombatFlag.sobrecargaReguladaPendingCooldownPenalty,
          ),
        )) {
      return owner;
    }

    final resolvedAbility = owner.abilityById(previousAbility.id);
    if (resolvedAbility == null ||
        !_abilityEnteredCooldown(previousAbility, resolvedAbility)) {
      return owner;
    }

    return owner
        .updateAbility(
          resolvedAbility.copyWith(
            remainingCooldownTurns: resolvedAbility.remainingCooldownTurns + 1,
          ),
        )
        .removeCombatFlag(
          const CombatRuntimeFlag.battler(
            BattlerCombatFlag.sobrecargaReguladaPendingCooldownPenalty,
          ),
        );
  }

  Battler _applyOpresionTacticaStatusLossTrigger({
    required Battler abilityOwnerBefore,
    required Battler abilityOwnerAfter,
    required Battler opponentBefore,
    required Battler opponentAfter,
  }) {
    final ability = abilityOwnerAfter.abilityById(
      BattlerAbilityId.opresionTactica,
    );
    if (ability == null ||
        abilityOwnerAfter.isDefeated ||
        !abilityOwnerAfter.hasCombatFlag(Battler.combatActiveFlag) ||
        abilityOwnerAfter.hasCombatFlag(
          const CombatRuntimeFlag.battler(
            BattlerCombatFlag.opresionTacticaTriggeredThisTurn,
          ),
        )) {
      return abilityOwnerAfter;
    }

    final lostOwnDebuff = _lostStatusMatching(
      before: abilityOwnerBefore,
      after: abilityOwnerAfter,
      predicate: (status) => status.type == BattlerStatusType.debuff,
    );
    final lostEnemyBuff = _lostStatusMatching(
      before: opponentBefore,
      after: opponentAfter,
      predicate: (status) => status.type == BattlerStatusType.buff,
    );
    if (!lostOwnDebuff && !lostEnemyBuff) {
      return abilityOwnerAfter;
    }

    return abilityOwnerAfter
        .addCombatFlag(
          const CombatRuntimeFlag.battler(
            BattlerCombatFlag.opresionTacticaTriggeredThisTurn,
          ),
        )
        .gainCombatBarrier(max(1, ability.currentValue));
  }

  bool _lostStatusMatching({
    required Battler before,
    required Battler after,
    required bool Function(BattlerStatus status) predicate,
  }) {
    return _statusCount(before, predicate) > _statusCount(after, predicate);
  }

  int _statusCount(
    Battler battler,
    bool Function(BattlerStatus status) predicate,
  ) {
    return battler.statuses.where(predicate).length;
  }

  /// Resolves secondary effects that react to newly applied or strengthened
  /// debuffs.
  ///
  /// This keeps debuff-pressure reactions centralized for pattern and attack
  /// events instead of duplicating the Cadena Neurotoxica check in each hook.
  ItemEffectResolution _resolveDebuffPressureTriggers({
    required Battler owner,
    required Battler opponent,
    required int debuffPressureBefore,
    bool skipCadenaNeurotoxica = false,
  }) {
    if (skipCadenaNeurotoxica ||
        _debuffPressure(opponent) <= debuffPressureBefore) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    return _applyCadenaNeurotoxicaDamage(
      owner: owner,
      opponent: opponent,
    );
  }

  ItemEffectResolution _applyCadenaNeurotoxicaDamage({
    required Battler owner,
    required Battler opponent,
  }) {
    final ability = owner.abilityById(BattlerAbilityId.cadenaNeurotoxica);
    if (ability == null) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    return ItemEffectResolution(
      owner: owner,
      opponent: opponent.receiveDirectDamage(
        max(1, ability.currentValue),
        source: owner,
      ),
    );
  }

  int _debuffPressure(Battler battler) {
    return battler.statuses
        .where((status) => status.type == BattlerStatusType.debuff)
        .fold<int>(
          0,
          (total, status) =>
              total +
              max(1, status.value).toInt() +
              max(0, status.remainingTurns).toInt(),
        );
  }

  bool _abilityEnteredCooldown(
    BattlerAbility previousAbility,
    BattlerAbility resolvedAbility,
  ) {
    return !previousAbility.isOnCooldown && resolvedAbility.isOnCooldown;
  }
}

Battler _clearCombatItemAugments(Battler owner) {
  return owner;
}
