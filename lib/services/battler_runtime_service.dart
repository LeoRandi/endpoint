import 'dart:math';

import '../entities/_exports.dart';
import 'battler_effect_pipeline.dart';
import 'run_randomizer.dart';
import 'run_hour_snapshot.dart';

const BattlerEffectPipeline _battlerEffectPipeline = BattlerEffectPipeline();

class BattlerStatusFromSourceResolution {
  final Battler owner;
  final Battler source;

  const BattlerStatusFromSourceResolution({
    required this.owner,
    required this.source,
  });
}

/// Ejecuta hooks runtime de combate y habilidades fuera del modelo inmutable.
extension BattlerRuntimeService on Battler {
  /// Recibe un ataque basico de otro battler y resuelve daño directo.
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

    final ownerBeforeDamage = removeCombatFlagsFor(
      BattlerCombatFlag.barrierBrokenThisHit,
    )
        .removeCombatFlagsFor(BattlerCombatFlag.barrierLostThisHit)
        .removeCombatFlagsFor(BattlerCombatFlag.healthLostThisHit)
        .removeCombatFlagsFor(BattlerCombatFlag.fragilidadTriggeredThisHit);
    final absorbedByBarrier = min(ownerBeforeDamage.currentBarrier, safeDamage);
    final ownerAfterBarrier = absorbedByBarrier <= 0
        ? ownerBeforeDamage
        : ownerBeforeDamage.copyWith(
            currentBarrier:
                ownerBeforeDamage.currentBarrier - absorbedByBarrier,
          );
    var resolvedOwnerAfterBarrier = ownerAfterBarrier;
    if (absorbedByBarrier > 0) {
      resolvedOwnerAfterBarrier = resolvedOwnerAfterBarrier.addCombatFlag(
        CombatRuntimeFlag.battler(
          BattlerCombatFlag.barrierLostThisHit,
          secondaryValue: absorbedByBarrier,
        ),
      );
    }
    if (ownerBeforeDamage.currentBarrier > 0 &&
        absorbedByBarrier > 0 &&
        ownerAfterBarrier.currentBarrier <= 0) {
      resolvedOwnerAfterBarrier = resolvedOwnerAfterBarrier.addCombatFlag(
        Battler.barrierBrokenThisHitFlag,
      );
    }
    final remainingDamage = max(0, safeDamage - absorbedByBarrier);
    if (remainingDamage <= 0) {
      return resolvedOwnerAfterBarrier;
    }

    final damagedOwner = resolvedOwnerAfterBarrier
        .copyWith(
          health: max(0, resolvedOwnerAfterBarrier.health - remainingDamage),
        )
        .addCombatFlag(
          CombatRuntimeFlag.battler(
            BattlerCombatFlag.healthLostThisHit,
            secondaryValue: remainingDamage,
          ),
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
    return _battlerEffectPipeline.receiveDirectDamage(
      owner: this,
      damage: damage,
      source: source,
    );
  }

  /// Procesa daño de debuff con hooks defensivos antes de restar vida.
  Battler receiveDebuffDamage(
    int damage, {
    required Battler source,
  }) {
    return _battlerEffectPipeline.receiveDebuffDamage(
      owner: this,
      damage: damage,
      source: source,
    );
  }

  /// Activa el estado runtime de combate y rellena la Barrera temporal inicial.
  Battler prepareForCombat({
    RunHourPhase phase = RunHourPhase.day,
  }) {
    final preparedOwner = materializeOwnedItems().clearCombatFlags();
    final cycleFlags = switch (phase) {
      RunHourPhase.day || RunHourPhase.sunrise => <CombatRuntimeFlag>{
          Battler.cycleDayContextFlag,
        },
      RunHourPhase.dusk || RunHourPhase.night => <CombatRuntimeFlag>{
          Battler.cycleNightContextFlag,
        },
    };

    return preparedOwner.copyWith(
      combatFlags: <CombatRuntimeFlag>{
        Battler.combatActiveFlag,
        ...cycleFlags,
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
    return _battlerEffectPipeline.applyStatusTurnStart(
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
    return _battlerEffectPipeline.applyStatusTurnEnd(
      owner: this,
      opponent: opponent,
      isOwnerTurn: isOwnerTurn,
      randomizer: randomizer,
    );
  }

  /// Aplica a un daño saliente todos los modificadores provenientes de estados.
  int applyOutgoingDamageModifiers({
    required Battler target,
    required int damage,
  }) {
    return _battlerEffectPipeline.applyOutgoingDamageModifiers(
      owner: this,
      target: target,
      damage: damage,
    );
  }

  /// Aplica a un daño saliente todos los modificadores de items equipados.
  int applyEquippedItemOutgoingDamageModifiers({
    required Battler target,
    required int damage,
  }) {
    return _battlerEffectPipeline.applyEquippedItemOutgoingDamageModifiers(
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
    return _battlerEffectPipeline.applyEquippedItemOutgoingStatusModifiers(
      owner: this,
      target: target,
      status: status,
    );
  }

  /// Aplica a un daño entrante todos los modificadores provenientes de estados.
  int applyIncomingDamageModifiers({
    required Battler source,
    required int damage,
  }) {
    return _battlerEffectPipeline.applyIncomingDamageModifiers(
      owner: this,
      source: source,
      damage: damage,
    );
  }

  /// Ejecuta hooks defensivos complejos de estados sobre un daño entrante.
  BattlerIncomingDamageResolution applyIncomingDamageEffects({
    required Battler source,
    required int damage,
    required DamageKind kind,
  }) {
    return _battlerEffectPipeline.applyIncomingDamageEffects(
      owner: this,
      source: source,
      damage: damage,
      kind: kind,
    );
  }

  /// Aplica a un daño entrante todos los modificadores de items equipados.
  int applyEquippedItemIncomingDamageModifiers({
    required Battler source,
    required int damage,
  }) {
    return _battlerEffectPipeline.applyEquippedItemIncomingDamageModifiers(
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
    return _battlerEffectPipeline.applyEquippedItemIncomingStatusModifiers(
      owner: this,
      source: source,
      status: status,
    );
  }

  /// Aplica un estado a partir de una fuente externa ejecutando primero los modificadores de equipo.
  Battler applyStatusFromSource(
    BattlerStatus status, {
    required Battler source,
    bool applyEquipmentModifiers = true,
  }) {
    return applyStatusFromSourceResolved(
      status,
      source: source,
      applyEquipmentModifiers: applyEquipmentModifiers,
    ).owner;
  }

  /// Aplica un estado y devuelve tambien la fuente por si el equipo lo redirige.
  BattlerStatusFromSourceResolution applyStatusFromSourceResolved(
    BattlerStatus status, {
    required Battler source,
    bool applyEquipmentModifiers = true,
  }) {
    var updatedOwner = this;
    var updatedSource = source;
    BattlerStatus? instancedStatus = status.copyWith();
    if (applyEquipmentModifiers) {
      instancedStatus =
          _battlerEffectPipeline.applyEquippedItemOutgoingStatusModifiers(
        owner: updatedSource,
        target: updatedOwner,
        status: instancedStatus,
      );
      if (instancedStatus != null) {
        final abilityIncomingResolution =
            _battlerEffectPipeline.applyAbilityIncomingStatusEffects(
          owner: updatedOwner,
          source: updatedSource,
          status: instancedStatus,
        );
        updatedOwner = abilityIncomingResolution.owner;
        updatedSource = abilityIncomingResolution.source;
        instancedStatus = abilityIncomingResolution.status;
      }
      if (instancedStatus != null) {
        final incomingResolution =
            _battlerEffectPipeline.applyEquippedItemIncomingStatusEffects(
          owner: updatedOwner,
          source: updatedSource,
          status: instancedStatus,
        );
        updatedOwner = incomingResolution.owner;
        updatedSource = incomingResolution.source;
        instancedStatus = incomingResolution.status;
      }
    }

    if (instancedStatus == null || instancedStatus.isExpired) {
      return BattlerStatusFromSourceResolution(
        owner: updatedOwner,
        source: updatedSource,
      );
    }

    return BattlerStatusFromSourceResolution(
      owner: updatedOwner.applyStatus(
        instancedStatus,
        applyEquipmentModifiers: false,
      ),
      source: updatedSource,
    );
  }

  /// Ejecuta efectos de estados que reaccionan despues de que el portador ataque.
  Battler applyAttackResolvedEffects({
    required Battler target,
    required int damageDealt,
  }) {
    return _battlerEffectPipeline.applyAttackResolvedEffects(
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
    return _battlerEffectPipeline.applyEquippedItemAttackResolvedEffects(
      owner: this,
      target: target,
      damageDealt: damageDealt,
    );
  }

  /// Ejecuta efectos de items equipados que reaccionan tras completar una defensa.
  ItemEffectResolution applyEquippedItemDefendResolvedEffects({
    required Battler opponent,
  }) {
    return _battlerEffectPipeline.applyEquippedItemDefendResolvedEffects(
      owner: this,
      opponent: opponent,
    );
  }

  /// Ejecuta efectos de estados que reaccionan despues de recibir daño.
  Battler applyReceiveDamageResolvedEffects({
    required Battler source,
    required int damageTaken,
  }) {
    return _battlerEffectPipeline.applyReceiveDamageResolvedEffects(
      owner: this,
      source: source,
      damageTaken: damageTaken,
    );
  }

  /// Ejecuta efectos de items equipados que reaccionan despues de recibir daño.
  ItemEffectResolution applyEquippedItemReceiveDamageResolvedEffects({
    required Battler source,
    required int damageTaken,
  }) {
    return _battlerEffectPipeline.applyEquippedItemReceiveDamageResolvedEffects(
      owner: this,
      source: source,
      damageTaken: damageTaken,
    );
  }

  /// Ejecuta efectos de inicio de turno para todos los items equipados.
  ItemEffectResolution applyEquippedItemTurnStartEffects({
    required Battler opponent,
    required bool isOwnerTurn,
    RunRandomizer? randomizer,
  }) {
    return _battlerEffectPipeline.applyEquippedItemTurnStartEffects(
      owner: this,
      opponent: opponent,
      isOwnerTurn: isOwnerTurn,
      randomizer: randomizer,
    );
  }

  /// Ejecuta efectos de final de turno para todos los items equipados.
  ItemEffectResolution applyEquippedItemTurnEndEffects({
    required Battler opponent,
    required bool isOwnerTurn,
    RunRandomizer? randomizer,
  }) {
    return _battlerEffectPipeline.applyEquippedItemTurnEndEffects(
      owner: this,
      opponent: opponent,
      isOwnerTurn: isOwnerTurn,
      randomizer: randomizer,
    );
  }

  /// Ejecuta efectos pasivos de todos los items equipados.
  ItemEffectResolution applyEquippedItemPassiveEffects({
    required Battler opponent,
  }) {
    return _battlerEffectPipeline.applyEquippedItemPassiveEffects(
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
    return _battlerEffectPipeline.applyEquippedItemManualAbilityPreparation(
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
    return _battlerEffectPipeline.applyEquippedItemAbilityResolvedEffects(
      owner: this,
      opponent: opponent,
      previousAbility: previousAbility,
      context: context,
    );
  }

  /// Ejecuta todos los hooks de inicio de turno de las habilidades activas.
  BattlerAbilityEffectResolution applyAbilityTurnStartEffects({
    required Battler opponent,
    required bool isOwnerTurn,
  }) {
    return _battlerEffectPipeline.applyAbilityTurnStartEffects(
      owner: this,
      opponent: opponent,
      isOwnerTurn: isOwnerTurn,
    );
  }

  /// Ejecuta todos los hooks de final de turno de las habilidades activas.
  BattlerAbilityEffectResolution applyAbilityTurnEndEffects({
    required Battler opponent,
    required bool isOwnerTurn,
  }) {
    return _battlerEffectPipeline.applyAbilityTurnEndEffects(
      owner: this,
      opponent: opponent,
      isOwnerTurn: isOwnerTurn,
    );
  }

  /// Aplica a un daño saliente todos los modificadores provenientes de habilidades.
  int applyAbilityOutgoingDamageModifiers({
    required Battler target,
    required int damage,
  }) {
    return _battlerEffectPipeline.applyAbilityOutgoingDamageModifiers(
      owner: this,
      target: target,
      damage: damage,
    );
  }

  /// Aplica a un daño entrante todos los modificadores provenientes de habilidades.
  int applyAbilityIncomingDamageModifiers({
    required Battler source,
    required int damage,
  }) {
    return _battlerEffectPipeline.applyAbilityIncomingDamageModifiers(
      owner: this,
      source: source,
      damage: damage,
    );
  }

  /// Ejecuta efectos de habilidades que reaccionan despues de atacar.
  BattlerAbilityEffectResolution applyAbilityAttackResolvedEffects({
    required Battler target,
    required int damageDealt,
  }) {
    return _battlerEffectPipeline.applyAbilityAttackResolvedEffects(
      owner: this,
      target: target,
      damageDealt: damageDealt,
    );
  }

  /// Ejecuta efectos de habilidades que reaccionan despues de recibir daño.
  BattlerAbilityEffectResolution applyAbilityReceiveDamageResolvedEffects({
    required Battler source,
    required int damageTaken,
  }) {
    return _battlerEffectPipeline.applyAbilityReceiveDamageResolvedEffects(
      owner: this,
      source: source,
      damageTaken: damageTaken,
    );
  }

  /// Ejecuta efectos de habilidades que reaccionan a la figura final de Patron.
  BattlerAbilityEffectResolution applyAbilityPatternMatchResolvedEffects({
    required Battler opponent,
    required BattlePatternMatchContext pattern,
  }) {
    return _battlerEffectPipeline.applyAbilityPatternMatchResolvedEffects(
      owner: this,
      opponent: opponent,
      pattern: pattern,
    );
  }

  /// Ejecuta efectos de habilidades que se disparan al comenzar una nueva hora.
  Battler applyAbilityHourStartEffects() {
    return _battlerEffectPipeline.applyAbilityHourStartEffects(
      owner: this,
    );
  }

  /// Ejecuta todos los efectos pasivos de habilidades activas o presentes.
  BattlerAbilityEffectResolution applyAbilityPassiveEffects({
    required Battler opponent,
  }) {
    return _battlerEffectPipeline.applyAbilityPassiveEffects(
      owner: this,
      opponent: opponent,
    );
  }

  /// Activa o desactiva una habilidad manual y resuelve sus hooks asociados.
  BattlerAbilityEffectResolution toggleAbilityActivation({
    required BattlerAbilityId abilityId,
    required BattlerAbilityActivationContext screenContext,
    Battler? opponent,
  }) {
    return _battlerEffectPipeline.toggleAbilityActivation(
      owner: this,
      abilityId: abilityId,
      screenContext: screenContext,
      opponent: opponent,
    );
  }

  /// Ejecuta todos los hooks de fin de combate antes de limpiar estado runtime.
  Battler applyCombatEndEffects() {
    return _battlerEffectPipeline.applyCombatEndEffects(owner: this);
  }

  /// Permite a los items equipados interceptar un golpe letal antes de morir.
  Battler applyEquippedItemFatalDamageEffects({
    required int incomingDamage,
  }) {
    return _battlerEffectPipeline.applyEquippedItemFatalDamageEffects(
      owner: this,
      incomingDamage: incomingDamage,
    );
  }

  /// Cierra el estado de combate una sola vez y deja el battler listo para volver a ruta.
  Battler finalizeCombatState() {
    final ownerAfterHooks = hasCombatFlag(Battler.combatActiveFlag)
        ? applyCombatEndEffects()
        : this;

    return ownerAfterHooks
        .clearCombatStatuses()
        .resetAbilitiesForContext(
          BattlerAbilityActivationContext.battle,
        )
        .copyWith(currentBarrier: 0)
        .clearCombatFlags();
  }
}
