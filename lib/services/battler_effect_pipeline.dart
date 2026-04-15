import '_imports.dart';

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
  }) {
    final resolution = applyIncomingDamageEffects(
      owner: owner,
      source: source,
      damage: damage,
      kind: DamageKind.debuff,
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
    return applyAbilityCombatEndEffects(
      owner: ownerAfterItems,
    );
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

    for (final status in activeStatuses) {
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
      final effect = item.effect;
      if (effect == null) continue;

      updatedDamage = effect.modifyOutgoingDamage(
        owner: owner,
        target: target,
        item: item,
        damage: updatedDamage,
      );
    }

    return max(0, updatedDamage);
  }

  BattlerStatus? applyEquippedItemOutgoingStatusModifiers({
    required Battler owner,
    required Battler target,
    required BattlerStatus status,
  }) {
    BattlerStatus? updatedStatus = status;

    for (final item
        in owner.equippedItemsForHook(ItemEffectHook.outgoingStatusModifier)) {
      final effect = item.effect;
      if (effect == null || updatedStatus == null) continue;

      updatedStatus = effect.modifyOutgoingStatus(
        owner: owner,
        target: target,
        item: item,
        status: updatedStatus,
      );
    }

    return updatedStatus;
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
      final effect = item.effect;
      if (effect == null) continue;

      updatedDamage = effect.modifyIncomingDamage(
        owner: owner,
        source: source,
        item: item,
        damage: updatedDamage,
      );
    }

    return max(0, updatedDamage);
  }

  BattlerStatus? applyEquippedItemIncomingStatusModifiers({
    required Battler owner,
    required Battler source,
    required BattlerStatus status,
  }) {
    BattlerStatus? updatedStatus = status;

    for (final item
        in owner.equippedItemsForHook(ItemEffectHook.incomingStatusModifier)) {
      final effect = item.effect;
      if (effect == null || updatedStatus == null) continue;

      updatedStatus = effect.modifyIncomingStatus(
        owner: owner,
        source: source,
        item: item,
        status: updatedStatus,
      );
    }

    return updatedStatus;
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
    var updatedOwner = owner;
    var updatedTarget = target;

    final activeItems = List<Item>.from(
      owner.equippedItemsForHook(ItemEffectHook.attackResolved),
    );

    for (final item in activeItems) {
      final effect = item.effect;
      if (effect == null) continue;

      final resolution = effect.onAttackResolved(
        owner: updatedOwner,
        target: updatedTarget,
        item: item,
        damageDealt: damageDealt,
      );
      updatedOwner = resolution.owner;
      updatedTarget = resolution.opponent;
    }

    return ItemEffectResolution(
      owner: updatedOwner.pruneExpiredStatuses(),
      opponent: updatedTarget.pruneExpiredStatuses(),
    );
  }

  BattlerAbilityEffectResolution applyAbilityAttackResolvedEffects({
    required Battler owner,
    required Battler target,
    required int damageDealt,
  }) {
    final activeAbilityIds = List<BattlerAbilityId>.from(
      owner.abilityIdsForHook(BattlerAbilityHook.attackResolved),
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
    var updatedOwner = owner;
    var updatedSource = source;

    final activeItems = List<Item>.from(
      owner.equippedItemsForHook(ItemEffectHook.receiveDamageResolved),
    );

    for (final item in activeItems) {
      final effect = item.effect;
      if (effect == null) continue;

      final resolution = effect.onReceiveDamageResolved(
        owner: updatedOwner,
        source: updatedSource,
        item: item,
        damageTaken: damageTaken,
      );
      updatedOwner = resolution.owner;
      updatedSource = resolution.opponent;
    }

    return ItemEffectResolution(
      owner: updatedOwner.pruneExpiredStatuses(),
      opponent: updatedSource.pruneExpiredStatuses(),
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
    var updatedOwner = owner;
    var updatedOpponent = opponent;

    final activeItems = List<Item>.from(
      owner.equippedItemsForHook(ItemEffectHook.turnStart),
    );

    for (final item in activeItems) {
      final effect = item.effect;
      if (effect == null) continue;

      final resolution = effect.onTurnStart(
        owner: updatedOwner,
        opponent: updatedOpponent,
        item: item,
        isOwnerTurn: isOwnerTurn,
        randomizer: randomizer,
      );
      updatedOwner = resolution.owner;
      updatedOpponent = resolution.opponent;
    }

    return ItemEffectResolution(
      owner: updatedOwner.pruneExpiredStatuses(),
      opponent: updatedOpponent.pruneExpiredStatuses(),
    );
  }

  ItemEffectResolution applyEquippedItemTurnEndEffects({
    required Battler owner,
    required Battler opponent,
    required bool isOwnerTurn,
    RunRandomizer? randomizer,
  }) {
    var updatedOwner = owner;
    var updatedOpponent = opponent;

    final activeItems = List<Item>.from(
      owner.equippedItemsForHook(ItemEffectHook.turnEnd),
    );

    for (final item in activeItems) {
      final effect = item.effect;
      if (effect == null) continue;

      final resolution = effect.onTurnEnd(
        owner: updatedOwner,
        opponent: updatedOpponent,
        item: item,
        isOwnerTurn: isOwnerTurn,
        randomizer: randomizer,
      );
      updatedOwner = resolution.owner;
      updatedOpponent = resolution.opponent;
    }

    return ItemEffectResolution(
      owner: updatedOwner.pruneExpiredStatuses(),
      opponent: updatedOpponent.pruneExpiredStatuses(),
    );
  }

  ItemEffectResolution applyEquippedItemDefendResolvedEffects({
    required Battler owner,
    required Battler opponent,
  }) {
    var updatedOwner = owner;
    var updatedOpponent = opponent;

    final activeItems = List<Item>.from(
      owner.equippedItemsForHook(ItemEffectHook.defendResolved),
    );

    for (final item in activeItems) {
      final effect = item.effect;
      if (effect == null) continue;

      final resolution = effect.onDefendResolved(
        owner: updatedOwner,
        opponent: updatedOpponent,
        item: item,
      );
      updatedOwner = resolution.owner;
      updatedOpponent = resolution.opponent;
    }

    return ItemEffectResolution(
      owner: updatedOwner.pruneExpiredStatuses(),
      opponent: updatedOpponent.pruneExpiredStatuses(),
    );
  }

  Battler applyEquippedItemCombatEndEffects({
    required Battler owner,
  }) {
    var updatedOwner = owner;

    final activeItems = List<Item>.from(
      owner.equippedItemsForHook(ItemEffectHook.combatEnd),
    );

    for (final item in activeItems) {
      final effect = item.effect;
      if (effect == null) continue;

      updatedOwner = effect.onCombatEnd(
        owner: updatedOwner,
        item: item,
      );
    }

    return updatedOwner.pruneExpiredStatuses();
  }

  ItemEffectResolution applyEquippedItemPassiveEffects({
    required Battler owner,
    required Battler opponent,
  }) {
    var updatedOwner = owner;
    var updatedOpponent = opponent;

    final activeItems = List<Item>.from(
      owner.equippedItemsForHook(ItemEffectHook.passive),
    );

    for (final item in activeItems) {
      final effect = item.effect;
      if (effect == null) continue;

      final resolution = effect.applyPassive(
        owner: updatedOwner,
        opponent: updatedOpponent,
        item: item,
      );
      updatedOwner = resolution.owner;
      updatedOpponent = resolution.opponent;
    }

    return ItemEffectResolution(
      owner: updatedOwner.pruneExpiredStatuses(),
      opponent: updatedOpponent.pruneExpiredStatuses(),
    );
  }

  ItemAbilityPreparationResolution applyEquippedItemManualAbilityPreparation({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlerAbilityActivationContext screenContext,
  }) {
    var updatedOwner = owner;
    var updatedOpponent = opponent;
    var updatedAbility = ability;

    final activeItems = List<Item>.from(
      owner.equippedItemsForHook(ItemEffectHook.manualAbilityPreparation),
    );

    for (final item in activeItems) {
      final effect = item.effect;
      if (effect == null) continue;

      final syncedAbility =
          updatedOwner.abilityById(updatedAbility.id) ?? updatedAbility;
      final resolution = effect.onManualAbilityPreparing(
        owner: updatedOwner,
        opponent: updatedOpponent,
        item: item,
        ability: syncedAbility,
        screenContext: screenContext,
      );
      updatedOwner = resolution.owner;
      updatedOpponent = resolution.opponent;
      updatedAbility = resolution.ability;
    }

    return ItemAbilityPreparationResolution(
      owner: updatedOwner.pruneExpiredStatuses(),
      opponent: updatedOpponent.pruneExpiredStatuses(),
      ability: updatedAbility,
    );
  }

  ItemEffectResolution applyEquippedItemAbilityResolvedEffects({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility previousAbility,
    required ItemAbilityResolutionContext context,
  }) {
    var updatedOwner = owner;
    var updatedOpponent = opponent;

    final activeItems = List<Item>.from(
      owner.equippedItemsForHook(ItemEffectHook.abilityResolved),
    );

    for (final item in activeItems) {
      final effect = item.effect;
      if (effect == null) continue;

      final resolvedAbility =
          updatedOwner.abilityById(previousAbility.id) ?? previousAbility;
      final resolution = effect.onAbilityResolved(
        owner: updatedOwner,
        opponent: updatedOpponent,
        item: item,
        previousAbility: previousAbility,
        resolvedAbility: resolvedAbility,
        context: context,
      );
      updatedOwner = resolution.owner;
      updatedOpponent = resolution.opponent;
    }

    return ItemEffectResolution(
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
    var updatedOwner = owner;

    final activeItems = List<Item>.from(
      owner.equippedItemsForHook(ItemEffectHook.fatalDamage),
    );

    for (final item in activeItems) {
      final effect = item.effect;
      if (effect == null) continue;

      updatedOwner = effect.onReceiveFatalDamage(
        owner: updatedOwner,
        item: item,
        incomingDamage: incomingDamage,
      );
      if (updatedOwner.health > 0) {
        break;
      }
    }

    return updatedOwner.pruneExpiredStatuses();
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
      return BattlerAbilityEffectResolution(
        owner: itemResolution.owner,
        opponent: itemResolution.opponent,
      );
    }

    final abilityResolution = effect.onManualActivation(
      owner: activatedOwner,
      opponent: updatedOpponent,
      ability: activatedAbility,
      screenContext: screenContext,
    );
    final itemResolution = applyEquippedItemAbilityResolvedEffects(
      owner: abilityResolution.owner,
      opponent: abilityResolution.opponent,
      previousAbility: currentAbility,
      context: ItemAbilityResolutionContext.manualActivation,
    );

    return BattlerAbilityEffectResolution(
      owner: itemResolution.owner,
      opponent: itemResolution.opponent,
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
