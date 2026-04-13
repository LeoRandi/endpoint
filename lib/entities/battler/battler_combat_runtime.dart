part of 'battler.dart';

extension BattlerCombatRuntime on Battler {
  /// Comprueba si una flag de combate concreta sigue activa.
  bool hasCombatFlag(CombatRuntimeFlag flag) => combatFlags.contains(flag);

  /// Indica si el ataque basico actual todavia tiene impactos pendientes.
  bool get hasPendingBasicAttackFollowUp {
    return hasCombatFlag(Battler.pendingBasicAttackFollowUpFlag);
  }

  /// Calcula el dano base de un ataque directo usando solo el ataque total del portador.
  int calculateDamageAgainst(Battler target) {
    // TODO: Apply thorns, damage reduction, and vampirism when their combat rules are defined.
    return max(1, calculatedStat(BattlerStat.attack));
  }

  /// Recibe un ataque basico de otro battler y resuelve dano directo.
  Battler receiveAttack(Battler attacker) {
    return receiveDirectDamage(
      attacker.calculateDamageAgainst(this),
      source: attacker,
    );
  }

  /// Consume primero Barrera activa y despues vida, disparando protecciones letales si procede.
  Battler receiveDamage(int damage) {
    final safeDamage = max(0, damage);
    if (safeDamage <= 0) return this;

    final absorbedByBarrier = min(currentBarrier, safeDamage);
    final ownerAfterBarrier = absorbedByBarrier <= 0
        ? this
        : copyWith(currentBarrier: currentBarrier - absorbedByBarrier);
    final remainingDamage = max(0, safeDamage - absorbedByBarrier);
    if (remainingDamage <= 0) {
      return ownerAfterBarrier;
    }

    final damagedOwner = ownerAfterBarrier.copyWith(
      health: max(0, ownerAfterBarrier.health - remainingDamage),
    );
    if (damagedOwner.health > 0) {
      return damagedOwner;
    }

    return damagedOwner.applyEquippedItemFatalDamageEffects(
      incomingDamage: remainingDamage,
    );
  }

  /// Procesa un impacto directo con hooks defensivos antes de restar vida.
  Battler receiveDirectDamage(
    int damage, {
    required Battler source,
  }) {
    return Battler._effectPipeline.receiveDirectDamage(
      owner: this,
      damage: damage,
      source: source,
    );
  }

  /// Procesa dano de debuff con hooks defensivos antes de restar vida.
  Battler receiveDebuffDamage(
    int damage, {
    required Battler source,
  }) {
    return Battler._effectPipeline.receiveDebuffDamage(
      owner: this,
      damage: damage,
      source: source,
    );
  }

  /// Cura vida sin superar la vida maxima calculada actual.
  Battler heal(int amount) {
    final safeAmount = max(0, amount);
    return copyWith(health: min(maxHealth, health + safeAmount));
  }

  /// Activa el estado runtime de combate y rellena la Barrera temporal inicial.
  Battler prepareForCombat() {
    final preparedOwner = materializeOwnedItems().clearCombatFlags();
    return preparedOwner.copyWith(
      combatFlags: <CombatRuntimeFlag>{
        Battler.combatActiveFlag,
      },
      currentBarrier: preparedOwner.maxBarrier,
    );
  }

  /// Ejecuta todos los hooks de inicio de turno de los estados activos.
  Battler applyStatusTurnStart({
    required Battler opponent,
    required bool isOwnerTurn,
    RunRandomizer? randomizer,
  }) {
    return Battler._effectPipeline.applyStatusTurnStart(
      owner: this,
      opponent: opponent,
      isOwnerTurn: isOwnerTurn,
      randomizer: randomizer,
    );
  }

  /// Ejecuta todos los hooks de final de turno de los estados activos.
  Battler applyStatusTurnEnd({
    required Battler opponent,
    required bool isOwnerTurn,
    RunRandomizer? randomizer,
  }) {
    return Battler._effectPipeline.applyStatusTurnEnd(
      owner: this,
      opponent: opponent,
      isOwnerTurn: isOwnerTurn,
      randomizer: randomizer,
    );
  }

  /// Aplica a un dano saliente todos los modificadores provenientes de estados.
  int applyOutgoingDamageModifiers({
    required Battler target,
    required int damage,
  }) {
    return Battler._effectPipeline.applyOutgoingDamageModifiers(
      owner: this,
      target: target,
      damage: damage,
    );
  }

  /// Aplica a un dano saliente todos los modificadores de items equipados.
  int applyEquippedItemOutgoingDamageModifiers({
    required Battler target,
    required int damage,
  }) {
    return Battler._effectPipeline.applyEquippedItemOutgoingDamageModifiers(
      owner: this,
      target: target,
      damage: damage,
    );
  }

  /// Permite a los items equipados alterar o cancelar un estado que se va a aplicar.
  BattlerStatus? applyEquippedItemOutgoingStatusModifiers({
    required Battler target,
    required BattlerStatus status,
  }) {
    return Battler._effectPipeline.applyEquippedItemOutgoingStatusModifiers(
      owner: this,
      target: target,
      status: status,
    );
  }

  /// Aplica a un dano entrante todos los modificadores provenientes de estados.
  int applyIncomingDamageModifiers({
    required Battler source,
    required int damage,
  }) {
    return Battler._effectPipeline.applyIncomingDamageModifiers(
      owner: this,
      source: source,
      damage: damage,
    );
  }

  /// Ejecuta hooks defensivos complejos de estados sobre un dano entrante.
  BattlerIncomingDamageResolution applyIncomingDamageEffects({
    required Battler source,
    required int damage,
    required DamageKind kind,
  }) {
    return Battler._effectPipeline.applyIncomingDamageEffects(
      owner: this,
      source: source,
      damage: damage,
      kind: kind,
    );
  }

  /// Aplica a un dano entrante todos los modificadores de items equipados.
  int applyEquippedItemIncomingDamageModifiers({
    required Battler source,
    required int damage,
  }) {
    return Battler._effectPipeline.applyEquippedItemIncomingDamageModifiers(
      owner: this,
      source: source,
      damage: damage,
    );
  }

  /// Permite a los items equipados alterar o cancelar un estado recibido.
  BattlerStatus? applyEquippedItemIncomingStatusModifiers({
    required Battler source,
    required BattlerStatus status,
  }) {
    return Battler._effectPipeline.applyEquippedItemIncomingStatusModifiers(
      owner: this,
      source: source,
      status: status,
    );
  }

  /// Ejecuta efectos de estados que reaccionan despues de que el portador ataque.
  Battler applyAttackResolvedEffects({
    required Battler target,
    required int damageDealt,
  }) {
    return Battler._effectPipeline.applyAttackResolvedEffects(
      owner: this,
      target: target,
      damageDealt: damageDealt,
    );
  }

  /// Ejecuta efectos de items equipados que reaccionan despues de atacar.
  ItemEffectResolution applyEquippedItemAttackResolvedEffects({
    required Battler target,
    required int damageDealt,
  }) {
    return Battler._effectPipeline.applyEquippedItemAttackResolvedEffects(
      owner: this,
      target: target,
      damageDealt: damageDealt,
    );
  }

  /// Ejecuta efectos de estados que reaccionan despues de recibir dano.
  Battler applyReceiveDamageResolvedEffects({
    required Battler source,
    required int damageTaken,
  }) {
    return Battler._effectPipeline.applyReceiveDamageResolvedEffects(
      owner: this,
      source: source,
      damageTaken: damageTaken,
    );
  }

  /// Ejecuta efectos de items equipados que reaccionan despues de recibir dano.
  ItemEffectResolution applyEquippedItemReceiveDamageResolvedEffects({
    required Battler source,
    required int damageTaken,
  }) {
    return Battler._effectPipeline.applyEquippedItemReceiveDamageResolvedEffects(
      owner: this,
      source: source,
      damageTaken: damageTaken,
    );
  }

  /// Ejecuta efectos de inicio de turno para todos los items equipados.
  ItemEffectResolution applyEquippedItemTurnStartEffects({
    required Battler opponent,
    required bool isOwnerTurn,
  }) {
    return Battler._effectPipeline.applyEquippedItemTurnStartEffects(
      owner: this,
      opponent: opponent,
      isOwnerTurn: isOwnerTurn,
    );
  }

  /// Ejecuta efectos de final de turno para todos los items equipados.
  ItemEffectResolution applyEquippedItemTurnEndEffects({
    required Battler opponent,
    required bool isOwnerTurn,
  }) {
    return Battler._effectPipeline.applyEquippedItemTurnEndEffects(
      owner: this,
      opponent: opponent,
      isOwnerTurn: isOwnerTurn,
    );
  }

  /// Ejecuta efectos pasivos de todos los items equipados.
  ItemEffectResolution applyEquippedItemPassiveEffects({
    required Battler opponent,
  }) {
    return Battler._effectPipeline.applyEquippedItemPassiveEffects(
      owner: this,
      opponent: opponent,
    );
  }

  /// Permite que los items modifiquen una habilidad justo antes de activarla manualmente.
  ItemAbilityPreparationResolution applyEquippedItemManualAbilityPreparation({
    required Battler opponent,
    required BattlerAbility ability,
    required BattlerAbilityActivationContext screenContext,
  }) {
    return Battler._effectPipeline.applyEquippedItemManualAbilityPreparation(
      owner: this,
      opponent: opponent,
      ability: ability,
      screenContext: screenContext,
    );
  }

  /// Ejecuta reacciones de items cuando una habilidad ya se ha resuelto.
  ItemEffectResolution applyEquippedItemAbilityResolvedEffects({
    required Battler opponent,
    required BattlerAbility previousAbility,
    required ItemAbilityResolutionContext context,
  }) {
    return Battler._effectPipeline.applyEquippedItemAbilityResolvedEffects(
      owner: this,
      opponent: opponent,
      previousAbility: previousAbility,
      context: context,
    );
  }

  /// Ejecuta todos los hooks de fin de combate antes de limpiar estado runtime.
  Battler applyCombatEndEffects() {
    return Battler._effectPipeline.applyCombatEndEffects(owner: this);
  }

  /// Permite a los items equipados interceptar un golpe letal antes de morir.
  Battler applyEquippedItemFatalDamageEffects({
    required int incomingDamage,
  }) {
    return Battler._effectPipeline.applyEquippedItemFatalDamageEffects(
      owner: this,
      incomingDamage: incomingDamage,
    );
  }

  /// Anade una flag de combate sin duplicarla.
  Battler addCombatFlag(CombatRuntimeFlag flag) {
    if (combatFlags.contains(flag)) return this;

    return copyWith(
      combatFlags: Set<CombatRuntimeFlag>.unmodifiable({
        ...combatFlags,
        flag,
      }),
    );
  }

  /// Elimina una flag de combate concreta si estaba activa.
  Battler removeCombatFlag(CombatRuntimeFlag flag) {
    if (!combatFlags.contains(flag)) return this;

    final updatedFlags = Set<CombatRuntimeFlag>.from(combatFlags)..remove(flag);
    return copyWith(
      combatFlags: Set<CombatRuntimeFlag>.unmodifiable(updatedFlags),
    );
  }

  /// Limpia todas las flags temporales de combate.
  Battler clearCombatFlags() {
    if (combatFlags.isEmpty) return this;

    return copyWith(combatFlags: const <CombatRuntimeFlag>{});
  }

  /// Cierra el estado de combate una sola vez y deja el battler listo para volver a ruta.
  Battler finalizeCombatState() {
    final ownerAfterHooks =
        hasCombatFlag(Battler.combatActiveFlag) ? applyCombatEndEffects() : this;

    return ownerAfterHooks
        .clearCombatStatuses()
        .resetAbilitiesForContext(
          BattlerAbilityActivationContext.battle,
        )
        .copyWith(currentBarrier: 0)
        .clearCombatFlags();
  }
}
