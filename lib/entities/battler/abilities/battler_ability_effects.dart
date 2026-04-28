part of '../battler_ability.dart';

/// Hace que el siguiente ataque activo pegue mas y luego entre en cooldown.
class CriticalScannerAbilityEffect extends BattlerAbilityEffect {
  /// Crea un efecto reutilizable para el preset de Escaner critico.
  const CriticalScannerAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.outgoingDamageModifier,
            BattlerAbilityHook.attackResolved,
          },
        );

  @override

  /// Suma el value actual solo mientras la habilidad siga activada.
  int modifyOutgoingDamage({
    required Battler owner,
    required Battler target,
    required BattlerAbility ability,
    required int damage,
  }) {
    if (!ability.isActive) return damage;

    return damage + ability.currentValue;
  }

  @override

  /// Consume la activacion al resolver el golpe y arranca su cooldown.
  BattlerAbilityEffectResolution onAttackResolved({
    required Battler owner,
    required Battler target,
    required BattlerAbility ability,
    required int damageDealt,
  }) {
    if (!ability.isActive || owner.hasPendingBasicAttackFollowUp) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: target);
    }

    return BattlerAbilityEffectResolution(
      owner: owner.updateAbility(ability.startCooldown()),
      opponent: target,
    );
  }
}

/// Premia atacar objetivos ya debilitados con daño extra constante.
class WeaknessHunterAbilityEffect extends BattlerAbilityEffect {
  /// Crea un efecto reutilizable para el preset de Caza de debilidades.
  const WeaknessHunterAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.outgoingDamageModifier,
          },
        );

  @override

  /// Suma daño solo si el objetivo ya tiene al menos un debuff.
  int modifyOutgoingDamage({
    required Battler owner,
    required Battler target,
    required BattlerAbility ability,
    required int damage,
  }) {
    final targetHasDebuff = target.statuses.any(
      (status) => status.type == BattlerStatusType.debuff,
    );
    if (!targetHasDebuff) return damage;

    return damage + ability.currentValue;
  }
}

/// Reduce el daño recibido mientras el portador siga con la vida al maximo.
class GhostMeshAbilityEffect extends BattlerAbilityEffect {
  /// Crea un efecto reutilizable para el preset de Malla Fantasma.
  const GhostMeshAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.incomingDamageModifier,
          },
        );

  @override

  /// Divide el daño entrante por el value cuando el usuario esta intacto.
  int modifyIncomingDamage({
    required Battler owner,
    required Battler source,
    required BattlerAbility ability,
    required int damage,
  }) {
    if (damage <= 0 || owner.health < owner.maxHealth) return damage;

    return (damage / max(1, ability.currentValue)).ceil();
  }
}

/// Mantiene el ritmo del Ciclo con cura de dia y Potencia de noche.
class RitmoCircadianoAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto pasivo de Ritmo Circadiano.
  const RitmoCircadianoAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.turnStart,
          },
        );

  @override
  BattlerAbilityEffectResolution onTurnStart({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required bool isOwnerTurn,
  }) {
    if (!isOwnerTurn) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
    }

    final cycleContext = cycleContextFor(owner);
    final amount = max(1, ability.currentValue);
    var updatedOwner = owner;

    if (cycleContext.isDay) {
      updatedOwner = updatedOwner.heal(amount);
    }
    if (cycleContext.isNight) {
      updatedOwner = updatedOwner.applyStatusFromSource(
        PotenciaStatus(value: amount),
        source: updatedOwner,
      );
    }

    return BattlerAbilityEffectResolution(
      owner: updatedOwner,
      opponent: opponent,
    );
  }
}

/// Activa un relevo defensivo de dia u ofensivo de noche.
class CambioDeGuardiaAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto manual de Cambio de Guardia.
  const CambioDeGuardiaAbilityEffect();

  @override
  BattlerAbilityEffectResolution onManualActivation({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlerAbilityActivationContext screenContext,
  }) {
    final cycleContext = cycleContextFor(owner);
    final amount = max(1, ability.currentValue);
    var updatedOwner = owner;

    if (cycleContext.isDay) {
      updatedOwner = updatedOwner.copyWith(
        currentBarrier: updatedOwner.currentBarrier + (amount * 2),
      );
    }
    if (cycleContext.isNight) {
      updatedOwner = updatedOwner.applyStatusFromSource(
        PotenciaStatus(value: amount),
        source: updatedOwner,
      );
    }

    return BattlerAbilityEffectResolution(
      owner: updatedOwner.updateAbility(ability.startCooldown()),
      opponent: opponent,
    );
  }
}

/// Aplica control distinto al rival dependiendo del momento del Ciclo.
class ToqueDeQuedaAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto manual de Toque de Queda.
  const ToqueDeQuedaAbilityEffect();

  @override
  BattlerAbilityEffectResolution onManualActivation({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlerAbilityActivationContext screenContext,
  }) {
    final cycleContext = cycleContextFor(owner);
    final amount = max(1, ability.currentValue);
    var updatedOpponent = opponent;

    if (cycleContext.isDay) {
      updatedOpponent = updatedOpponent.applyStatusFromSource(
        InterferenciaStatus(remainingTurns: amount),
        source: owner,
      );
    }
    if (cycleContext.isNight) {
      updatedOpponent = updatedOpponent.applyStatusFromSource(
        FragilidadStatus(remainingTurns: amount),
        source: owner,
      );
    }

    return BattlerAbilityEffectResolution(
      owner: owner.updateAbility(ability.startCooldown()),
      opponent: updatedOpponent,
    );
  }
}

/// Protege de dia y anade presion ofensiva de noche.
class TurnoDeNocheAbilityEffect extends BattlerAbilityEffect {
  /// Crea la pasiva de Turno de Noche.
  const TurnoDeNocheAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.outgoingDamageModifier,
            BattlerAbilityHook.incomingDamageModifier,
          },
        );

  @override
  int modifyOutgoingDamage({
    required Battler owner,
    required Battler target,
    required BattlerAbility ability,
    required int damage,
  }) {
    final cycleContext = cycleContextFor(owner);
    if (!cycleContext.isNight) {
      return damage;
    }

    return damage + max(1, ability.currentValue);
  }

  @override
  int modifyIncomingDamage({
    required Battler owner,
    required Battler source,
    required BattlerAbility ability,
    required int damage,
  }) {
    final cycleContext = cycleContextFor(owner);
    if (!cycleContext.isDay) {
      return damage;
    }

    return max(0, damage - max(1, ability.currentValue));
  }
}

/// Fuerza el amanecer del siguiente combate.
class AmanecerSinteticoAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto persistente de Amanecer Sintetico.
  const AmanecerSinteticoAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.combatEnd,
          },
        );

  @override
  BattlerAbilityEffectResolution onManualActivation({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlerAbilityActivationContext screenContext,
  }) {
    return BattlerAbilityEffectResolution(
      owner: _deactivateCycleRouteAbility(
        owner: owner,
        excludedAbilityId: ability.id,
        targetAbilityId: BattlerAbilityId.lunaArtificial,
      ),
      opponent: opponent,
    );
  }

  @override
  Battler onCombatEnd({
    required Battler owner,
    required BattlerAbility ability,
  }) {
    if (!ability.isActive) return owner;

    return owner.updateAbility(ability.startCooldown());
  }
}

/// Fuerza la noche del siguiente combate.
class LunaArtificialAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto persistente de Luna Artificial.
  const LunaArtificialAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.combatEnd,
          },
        );

  @override
  BattlerAbilityEffectResolution onManualActivation({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlerAbilityActivationContext screenContext,
  }) {
    return BattlerAbilityEffectResolution(
      owner: _deactivateCycleRouteAbility(
        owner: owner,
        excludedAbilityId: ability.id,
        targetAbilityId: BattlerAbilityId.amanecerSintetico,
      ),
      opponent: opponent,
    );
  }

  @override
  Battler onCombatEnd({
    required Battler owner,
    required BattlerAbility ability,
  }) {
    if (!ability.isActive) return owner;

    return owner.updateAbility(ability.startCooldown());
  }
}

/// Activa ambas ramas del Ciclo durante un numero corto de turnos.
class EclipseManualAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto de Eclipse Manual.
  const EclipseManualAbilityEffect();

  @override
  BattlerAbilityEffectResolution onManualActivation({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlerAbilityActivationContext screenContext,
  }) {
    final activeTurns = min(3, max(1, ability.currentValue));
    final updatedOwner = owner
        .applyStatusFromSource(
          CicloEclipseStatus(remainingTurns: activeTurns),
          source: owner,
        )
        .updateAbility(ability.startCooldown());

    return BattlerAbilityEffectResolution(
      owner: updatedOwner,
      opponent: opponent,
    );
  }
}

/// Aplica Catalisis Cruel al rival y consume la activacion en combate.
class CruelCatalysisAbilityEffect extends BattlerAbilityEffect {
  /// Crea un efecto reutilizable para el preset de Catalisis Cruel.
  const CruelCatalysisAbilityEffect();

  @override

  /// Coloca el debuff en el rival y pone la habilidad en cooldown.
  BattlerAbilityEffectResolution onManualActivation({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlerAbilityActivationContext screenContext,
  }) {
    final updatedOpponent = opponent.applyStatusFromSource(
      CatalisisCruelStatus(value: max(2, ability.currentValue)),
      source: owner,
    );

    return BattlerAbilityEffectResolution(
      owner: owner.updateAbility(ability.startCooldown()),
      opponent: updatedOpponent,
    );
  }
}

/// Convierte el siguiente ataque en uno mas fuerte a cambio de Quemadura propia.
class VenousOverloadAbilityEffect extends BattlerAbilityEffect {
  /// Crea un efecto reutilizable para el preset de Sobrecarga venosa.
  const VenousOverloadAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.outgoingDamageModifier,
            BattlerAbilityHook.attackResolved,
          },
        );

  @override

  /// Al activarse no cambia nada todavia porque el bonus se consume al atacar.
  BattlerAbilityEffectResolution onManualActivation({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlerAbilityActivationContext screenContext,
  }) {
    return BattlerAbilityEffectResolution(
      owner: owner,
      opponent: opponent,
    );
  }

  @override

  /// Suma el value actual solo mientras la preparacion siga activa.
  int modifyOutgoingDamage({
    required Battler owner,
    required Battler target,
    required BattlerAbility ability,
    required int damage,
  }) {
    if (!ability.isActive) return damage;

    return damage + ability.currentValue;
  }

  @override

  /// Tras pegar, se aplica Quemadura propia y la habilidad entra en cooldown.
  BattlerAbilityEffectResolution onAttackResolved({
    required Battler owner,
    required Battler target,
    required BattlerAbility ability,
    required int damageDealt,
  }) {
    if (!ability.isActive || owner.hasPendingBasicAttackFollowUp) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: target);
    }

    final burnTurns = max(1, ability.currentValue ~/ 2);
    final updatedOwner = owner
        .applyStatusFromSource(
          QuemaduraStatus(remainingTurns: burnTurns),
          source: owner,
        )
        .updateAbility(ability.startCooldown());

    return BattlerAbilityEffectResolution(
      owner: updatedOwner,
      opponent: target,
    );
  }
}

/// Limpia debuffs purgables del usuario y cobra vida en proporcion al value.
class HardResetAbilityEffect extends BattlerAbilityEffect {
  /// Crea un efecto reutilizable para el preset de Reinicio en seco.
  const HardResetAbilityEffect();

  @override

  /// Purga debuffs, luego hace daño propio y finalmente inicia el cooldown.
  BattlerAbilityEffectResolution onManualActivation({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlerAbilityActivationContext screenContext,
  }) {
    var updatedOwner = owner;
    final removableDebuffs = updatedOwner.statuses
        .where(
          (status) =>
              status.type == BattlerStatusType.debuff && status.isPurgeable,
        )
        .take(max(0, ability.currentValue))
        .toList(growable: false);

    for (final debuff in removableDebuffs) {
      updatedOwner = updatedOwner.removeStatusInstance(debuff);
    }

    final selfDamage = max(
      1,
      ((updatedOwner.maxHealth * ability.currentValue) / 10).round(),
    );

    updatedOwner = updatedOwner
        .receiveDamage(selfDamage)
        .updateAbility(ability.startCooldown());

    return BattlerAbilityEffectResolution(
      owner: updatedOwner,
      opponent: opponent,
    );
  }
}

/// Convierte cada nueva hora de la run en una entrada directa de capital.
class CashflowAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto pasivo del Mercante para monetizar el income actual.
  const CashflowAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.hourStart,
          },
        );

  @override
  Battler onHourStart({
    required Battler owner,
    required BattlerAbility ability,
  }) {
    final payout = max(0, owner.income);
    if (payout <= 0) return owner;

    return owner.earnMoney(payout);
  }
}

/// Sostiene un minimo de Barrera al comienzo de cada turno propio.
class PulsoRepLAbilityEffect extends BattlerAbilityEffect {
  /// Crea un efecto reutilizable para Pulso REP-L.
  const PulsoRepLAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.turnStart,
          },
        );

  @override
  BattlerAbilityEffectResolution onTurnStart({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required bool isOwnerTurn,
  }) {
    if (!isOwnerTurn) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
    }

    final targetBarrier = max(0, ability.currentValue);
    if (owner.currentBarrier >= targetBarrier) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
    }

    return BattlerAbilityEffectResolution(
      owner: owner.copyWith(currentBarrier: targetBarrier),
      opponent: opponent,
    );
  }
}

/// Prepara la absorcion de barrera para el siguiente ataque resuelto.
class SustraccionAbilityEffect extends BattlerAbilityEffect {
  /// Crea un efecto reutilizable para Sustraccion.
  const SustraccionAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.attackResolved,
          },
        );

  @override
  BattlerAbilityEffectResolution onManualActivation({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlerAbilityActivationContext screenContext,
  }) {
    return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
  }

  @override
  BattlerAbilityEffectResolution onAttackResolved({
    required Battler owner,
    required Battler target,
    required BattlerAbility ability,
    required int damageDealt,
  }) {
    if (!ability.isActive || owner.hasPendingBasicAttackFollowUp) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: target);
    }

    final drainedBarrier = min(
      max(0, ability.currentValue),
      max(0, target.currentBarrier),
    );
    final updatedTarget = target.copyWith(
      currentBarrier: max(0, target.currentBarrier - drainedBarrier),
    );
    final updatedOwner = owner
        .copyWith(
          currentBarrier: owner.currentBarrier + drainedBarrier,
        )
        .updateAbility(ability.startCooldown());

    return BattlerAbilityEffectResolution(
      owner: updatedOwner,
      opponent: updatedTarget,
    );
  }
}

/// Reduce duracion de buffs rivales una cantidad de veces igual a su value.
class LimpiezaCacheAbilityEffect extends BattlerAbilityEffect {
  /// Crea un efecto reutilizable para Limpieza de Cache.
  const LimpiezaCacheAbilityEffect();

  @override
  BattlerAbilityEffectResolution onManualActivation({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlerAbilityActivationContext screenContext,
  }) {
    var updatedOpponent = opponent;
    final loops = max(0, ability.currentValue);

    for (var index = 0; index < loops; index++) {
      final activeBuffs = updatedOpponent.statuses
          .where((status) => status.type == BattlerStatusType.buff)
          .toList(growable: false);
      if (activeBuffs.isEmpty) break;

      final selectedIndex = _stableSelectionIndex(
        owner: owner,
        opponent: updatedOpponent,
        length: activeBuffs.length,
        salt: index + 101,
      );
      final selectedBuff = activeBuffs[selectedIndex];
      if (selectedBuff.isIndefinite || selectedBuff.remainingTurns <= 1) {
        updatedOpponent = updatedOpponent.removeStatusInstance(selectedBuff);
        continue;
      }

      updatedOpponent = updatedOpponent.replaceStatusInstance(
        currentStatus: selectedBuff,
        replacement: selectedBuff.copyWith(
          remainingTurns: selectedBuff.remainingTurns - 1,
        ),
      );
    }

    return BattlerAbilityEffectResolution(
      owner: owner.updateAbility(ability.startCooldown()),
      opponent: updatedOpponent,
    );
  }
}

/// Cura al portador cada vez que golpea a un enemigo con debuffs.
class HemostasiaAgresivaAbilityEffect extends BattlerAbilityEffect {
  /// Crea un efecto reutilizable para Hemostasia Agresiva.
  const HemostasiaAgresivaAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.attackResolved,
          },
        );

  @override
  BattlerAbilityEffectResolution onAttackResolved({
    required Battler owner,
    required Battler target,
    required BattlerAbility ability,
    required int damageDealt,
  }) {
    if (damageDealt <= 0) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: target);
    }

    final targetHasDebuff = target.statuses.any(
      (status) => status.type == BattlerStatusType.debuff,
    );
    if (!targetHasDebuff) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: target);
    }

    return BattlerAbilityEffectResolution(
      owner: owner.heal(max(0, ability.currentValue)),
      opponent: target,
    );
  }
}

/// Devuelve daño al primer ataque recibido en cada turno del portador.
class MallaReboteAbilityEffect extends BattlerAbilityEffect {
  /// Crea un efecto reutilizable para Malla de Rebote.
  const MallaReboteAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.turnStart,
            BattlerAbilityHook.receiveDamageResolved,
          },
        );

  @override
  BattlerAbilityEffectResolution onTurnStart({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required bool isOwnerTurn,
  }) {
    if (!isOwnerTurn || ability.isActive) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
    }

    return BattlerAbilityEffectResolution(
      owner: owner.updateAbility(ability.activate()),
      opponent: opponent,
    );
  }

  @override
  BattlerAbilityEffectResolution onReceiveDamageResolved({
    required Battler owner,
    required Battler source,
    required BattlerAbility ability,
    required int damageTaken,
  }) {
    if (!ability.isActive) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: source);
    }

    final reflectedDamage = max(0, ability.currentValue);
    final updatedSource = reflectedDamage <= 0
        ? source
        : source.receiveDirectDamage(
            reflectedDamage,
            source: owner,
          );

    return BattlerAbilityEffectResolution(
      owner: owner.updateAbility(ability.deactivate()),
      opponent: updatedSource,
    );
  }
}

/// Aplica Intoxicacion o potencia la que ya tenga el objetivo.
class InyeccionCorrosivaAbilityEffect extends BattlerAbilityEffect {
  /// Crea un efecto reutilizable para Inyeccion Corrosiva.
  const InyeccionCorrosivaAbilityEffect();

  @override
  BattlerAbilityEffectResolution onManualActivation({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlerAbilityActivationContext screenContext,
  }) {
    final poisonValue = max(0, ability.currentValue);
    final currentPoison = opponent.statusById(IntoxicacionStatus.statusId);
    final updatedOpponent = currentPoison is IntoxicacionStatus
        ? opponent.replaceStatusInstance(
            currentStatus: currentPoison,
            replacement: currentPoison.copyWith(
              value: currentPoison.value + poisonValue,
            ),
          )
        : opponent.applyStatusFromSource(
            IntoxicacionStatus(value: max(1, poisonValue)),
            source: owner,
          );

    return BattlerAbilityEffectResolution(
      owner: owner.updateAbility(ability.startCooldown()),
      opponent: updatedOpponent,
    );
  }
}

/// Aumenta el daño al golpear enemigos que tengan buffs activos.
class EscanerRupturaAbilityEffect extends BattlerAbilityEffect {
  /// Crea un efecto reutilizable para Escaner de Ruptura.
  const EscanerRupturaAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.outgoingDamageModifier,
          },
        );

  @override
  int modifyOutgoingDamage({
    required Battler owner,
    required Battler target,
    required BattlerAbility ability,
    required int damage,
  }) {
    final targetHasBuff = target.statuses.any(
      (status) => status.type == BattlerStatusType.buff,
    );
    if (!targetHasBuff) return damage;

    return damage + max(0, ability.currentValue);
  }
}

/// Transfiere turnos de debuffs propios al enemigo.
class ReenrutadoInversoAbilityEffect extends BattlerAbilityEffect {
  /// Crea un efecto reutilizable para Reenrutado Inverso.
  const ReenrutadoInversoAbilityEffect();

  @override
  BattlerAbilityEffectResolution onManualActivation({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlerAbilityActivationContext screenContext,
  }) {
    var updatedOwner = owner;
    var updatedOpponent = opponent;
    final loops = max(0, ability.currentValue);

    for (var index = 0; index < loops; index++) {
      final transferableDebuffs = updatedOwner.statuses
          .where(
            (status) =>
                status.type == BattlerStatusType.debuff &&
                !status.isIndefinite &&
                status.remainingTurns > 0,
          )
          .toList(growable: false);
      if (transferableDebuffs.isEmpty) break;

      final selectedIndex = _stableSelectionIndex(
        owner: updatedOwner,
        opponent: updatedOpponent,
        length: transferableDebuffs.length,
        salt: index + 211,
      );
      final selectedDebuff = transferableDebuffs[selectedIndex];
      final nextRemainingTurns = selectedDebuff.remainingTurns - 1;
      if (nextRemainingTurns <= 0) {
        updatedOwner = updatedOwner.removeStatusInstance(selectedDebuff);
      } else {
        updatedOwner = updatedOwner.replaceStatusInstance(
          currentStatus: selectedDebuff,
          replacement: selectedDebuff.copyWith(
            remainingTurns: nextRemainingTurns,
          ),
        );
      }

      updatedOpponent = updatedOpponent.applyStatus(
        selectedDebuff.copyWith(remainingTurns: 1),
        applyEquipmentModifiers: false,
      );
    }

    return BattlerAbilityEffectResolution(
      owner: updatedOwner.updateAbility(ability.startCooldown()),
      opponent: updatedOpponent,
    );
  }
}

/// Bloquea temporalmente una habilidad manual enemiga.
class JaulaSenalAbilityEffect extends BattlerAbilityEffect {
  /// Crea un efecto reutilizable para Jaula de Senal.
  const JaulaSenalAbilityEffect();

  @override
  BattlerAbilityEffectResolution onManualActivation({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlerAbilityActivationContext screenContext,
  }) {
    final manualAbilities = opponent.abilities
        .where((activeAbility) => activeAbility.manualActivationContext != null)
        .toList(growable: false);

    if (manualAbilities.isEmpty) {
      return BattlerAbilityEffectResolution(
        owner: owner.updateAbility(ability.startCooldown()),
        opponent: opponent,
      );
    }

    final selectedAbility = manualAbilities[_stableSelectionIndex(
      owner: owner,
      opponent: opponent,
      length: manualAbilities.length,
      salt: 317,
    )];
    final updatedTargetAbility = selectedAbility.copyWith(
      isActive: false,
      runtimeValueBonus: 0,
      remainingCooldownTurns:
          selectedAbility.remainingCooldownTurns + max(0, ability.currentValue),
    );

    return BattlerAbilityEffectResolution(
      owner: owner.updateAbility(ability.startCooldown()),
      opponent: opponent.updateAbility(updatedTargetAbility),
    );
  }
}

/// Drena vida en el primer ataque que el portador realice durante su turno.
class NucleoParasitarioAbilityEffect extends BattlerAbilityEffect {
  /// Crea un efecto reutilizable para Nucleo Parasitario.
  const NucleoParasitarioAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.turnStart,
            BattlerAbilityHook.attackResolved,
          },
        );

  @override
  BattlerAbilityEffectResolution onTurnStart({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required bool isOwnerTurn,
  }) {
    if (!isOwnerTurn || ability.isActive) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
    }

    return BattlerAbilityEffectResolution(
      owner: owner.updateAbility(ability.activate()),
      opponent: opponent,
    );
  }

  @override
  BattlerAbilityEffectResolution onAttackResolved({
    required Battler owner,
    required Battler target,
    required BattlerAbility ability,
    required int damageDealt,
  }) {
    if (!ability.isActive || damageDealt <= 0) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: target);
    }

    final drainAmount = max(0, ability.currentValue);
    final updatedTarget = drainAmount <= 0
        ? target
        : target.receiveDirectDamage(
            drainAmount,
            source: owner,
          );

    return BattlerAbilityEffectResolution(
      owner: owner.heal(drainAmount).updateAbility(ability.deactivate()),
      opponent: updatedTarget,
    );
  }
}

/// Reduce el siguiente daño recibido y refleja un contraataque adicional.
class EspejoDolorAbilityEffect extends BattlerAbilityEffect {
  /// Crea un efecto reutilizable para Espejo de Dolor.
  const EspejoDolorAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.incomingDamageModifier,
            BattlerAbilityHook.receiveDamageResolved,
          },
        );

  @override
  BattlerAbilityEffectResolution onManualActivation({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlerAbilityActivationContext screenContext,
  }) {
    return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
  }

  @override
  int modifyIncomingDamage({
    required Battler owner,
    required Battler source,
    required BattlerAbility ability,
    required int damage,
  }) {
    if (!ability.isActive) return damage;

    return max(0, damage - max(0, ability.currentValue));
  }

  @override
  BattlerAbilityEffectResolution onReceiveDamageResolved({
    required Battler owner,
    required Battler source,
    required BattlerAbility ability,
    required int damageTaken,
  }) {
    if (!ability.isActive) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: source);
    }

    final reflectedDamage = max(0, ability.currentValue) * 2;
    final updatedSource = reflectedDamage <= 0
        ? source
        : source.receiveDirectDamage(
            reflectedDamage,
            source: owner,
          );

    return BattlerAbilityEffectResolution(
      owner: owner.updateAbility(ability.startCooldown()),
      opponent: updatedSource,
    );
  }
}

/// Roba buffs enemigos y los aplica al portador.
class ProtocoloUsurpacionAbilityEffect extends BattlerAbilityEffect {
  /// Crea un efecto reutilizable para Protocolo de Usurpacion.
  const ProtocoloUsurpacionAbilityEffect();

  @override
  BattlerAbilityEffectResolution onManualActivation({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlerAbilityActivationContext screenContext,
  }) {
    var updatedOwner = owner;
    var updatedOpponent = opponent;
    final loops = max(0, ability.currentValue);

    for (var index = 0; index < loops; index++) {
      final activeBuffs = updatedOpponent.statuses
          .where((status) => status.type == BattlerStatusType.buff)
          .toList(growable: false);
      if (activeBuffs.isEmpty) break;

      final selectedBuff = activeBuffs[_stableSelectionIndex(
        owner: updatedOwner,
        opponent: updatedOpponent,
        length: activeBuffs.length,
        salt: index + 419,
      )];
      updatedOpponent = updatedOpponent.removeStatusInstance(selectedBuff);
      updatedOwner = updatedOwner.applyStatus(
        selectedBuff.copyWith(),
        applyEquipmentModifiers: false,
      );
    }

    return BattlerAbilityEffectResolution(
      owner: updatedOwner.updateAbility(ability.startCooldown()),
      opponent: updatedOpponent,
    );
  }
}

/// Gasta creditos para forzar un reroll completo de nodos visibles en ruta.
class RefactorizacionTimelineAbilityEffect extends BattlerAbilityEffect {
  /// Crea un efecto reutilizable para Refactorizacion de Timeline.
  const RefactorizacionTimelineAbilityEffect();

  @override
  BattlerAbilityEffectResolution onManualActivation({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlerAbilityActivationContext screenContext,
  }) {
    final price = max(0, ability.currentValue);
    if (!owner.canAfford(price)) {
      return BattlerAbilityEffectResolution(
        owner: owner.updateAbility(ability.deactivate()),
        opponent: opponent,
      );
    }

    return BattlerAbilityEffectResolution(
      owner: owner.spendMoney(price).updateAbility(ability.startCooldown()),
      opponent: opponent,
    );
  }
}

/// Cura al portador al inicio de turno si su catalogo no rompe el monopolio.
class MonopolioAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto pasivo de Monopolio.
  const MonopolioAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.turnStart,
          },
        );

  @override
  BattlerAbilityEffectResolution onTurnStart({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required bool isOwnerTurn,
  }) {
    if (!isOwnerTurn || !_hasOnlyMercanteOrGeneralOwnedItems(owner)) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
    }

    return BattlerAbilityEffectResolution(
      owner: owner.heal(max(0, ability.currentValue)),
      opponent: opponent,
    );
  }
}

/// Compra una preparacion ofensiva que tambien recompone barrera por variedad.
class CompraDeOportunidadAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto manual de Compra de Oportunidad.
  const CompraDeOportunidadAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.outgoingDamageModifier,
            BattlerAbilityHook.attackResolved,
          },
        );

  @override
  BattlerAbilityEffectResolution onManualActivation({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlerAbilityActivationContext screenContext,
  }) {
    final price = max(0, ability.currentValue);
    if (!owner.canAfford(price)) {
      return BattlerAbilityEffectResolution(
        owner: owner.updateAbility(ability.deactivate()),
        opponent: opponent,
      );
    }

    return BattlerAbilityEffectResolution(
      owner: owner.spendMoney(price),
      opponent: opponent,
    );
  }

  @override
  int modifyOutgoingDamage({
    required Battler owner,
    required Battler target,
    required BattlerAbility ability,
    required int damage,
  }) {
    if (!ability.isActive) return damage;

    return damage + max(0, ability.currentValue);
  }

  @override
  BattlerAbilityEffectResolution onAttackResolved({
    required Battler owner,
    required Battler target,
    required BattlerAbility ability,
    required int damageDealt,
  }) {
    if (!ability.isActive || owner.hasPendingBasicAttackFollowUp) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: target);
    }

    final barrierRecovered = _distinctEquippedSpecificArchetypes(owner).length;
    final updatedOwner = owner
        .gainCombatBarrier(barrierRecovered)
        .updateAbility(ability.startCooldown());

    return BattlerAbilityEffectResolution(
      owner: updatedOwner,
      opponent: target,
    );
  }
}

/// Convierte la diversidad no mercante equipada en daño extra estable.
class DiversificacionHostilAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto pasivo de Diversificacion Hostil.
  const DiversificacionHostilAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.outgoingDamageModifier,
          },
        );

  @override
  int modifyOutgoingDamage({
    required Battler owner,
    required Battler target,
    required BattlerAbility ability,
    required int damage,
  }) {
    final foreignArchetypeCount = _distinctEquippedSpecificArchetypes(
      owner,
      includeMercante: false,
    ).length;
    if (foreignArchetypeCount <= 0) return damage;

    return damage + (max(0, ability.currentValue) * foreignArchetypeCount);
  }
}

/// Marca una sustitucion inmediata de nodos por tiendas especiales.
class ConvencionRepentinaAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto manual de Convencion repentina.
  const ConvencionRepentinaAbilityEffect();

  @override
  BattlerAbilityEffectResolution onManualActivation({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlerAbilityActivationContext screenContext,
  }) {
    return BattlerAbilityEffectResolution(
      owner: owner.updateAbility(ability.startCooldown()),
      opponent: opponent,
    );
  }
}

/// Potencia el primer ataque del turno segun la vida maxima que falte.
class FuriaHematicaAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto pasivo de Furia Hematica.
  const FuriaHematicaAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.turnStart,
            BattlerAbilityHook.outgoingDamageModifier,
            BattlerAbilityHook.attackResolved,
          },
        );

  @override
  BattlerAbilityEffectResolution onTurnStart({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required bool isOwnerTurn,
  }) {
    if (!isOwnerTurn || ability.isActive) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
    }

    return BattlerAbilityEffectResolution(
      owner: owner.updateAbility(ability.activate()),
      opponent: opponent,
    );
  }

  @override
  int modifyOutgoingDamage({
    required Battler owner,
    required Battler target,
    required BattlerAbility ability,
    required int damage,
  }) {
    if (!ability.isActive) return damage;

    return damage + _missingHealthStepBonus(owner, ability);
  }

  @override
  BattlerAbilityEffectResolution onAttackResolved({
    required Battler owner,
    required Battler target,
    required BattlerAbility ability,
    required int damageDealt,
  }) {
    if (!ability.isActive || owner.hasPendingBasicAttackFollowUp) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: target);
    }

    return BattlerAbilityEffectResolution(
      owner: owner.updateAbility(ability.deactivate()),
      opponent: target,
    );
  }
}

/// Prepara un mordisco reforzado y cura por parte del daño de la habilidad.
class MordidaDeAceroAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto manual de Mordida de Acero.
  const MordidaDeAceroAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.outgoingDamageModifier,
            BattlerAbilityHook.attackResolved,
          },
        );

  @override
  BattlerAbilityEffectResolution onManualActivation({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlerAbilityActivationContext screenContext,
  }) {
    return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
  }

  @override
  int modifyOutgoingDamage({
    required Battler owner,
    required Battler target,
    required BattlerAbility ability,
    required int damage,
  }) {
    if (!ability.isActive) return damage;

    return damage + max(0, ability.currentValue);
  }

  @override
  BattlerAbilityEffectResolution onAttackResolved({
    required Battler owner,
    required Battler target,
    required BattlerAbility ability,
    required int damageDealt,
  }) {
    if (!ability.isActive || owner.hasPendingBasicAttackFollowUp) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: target);
    }

    final abilityDamage = min(
      max(0, ability.currentValue),
      max(0, damageDealt),
    );
    final updatedOwner =
        owner.heal(abilityDamage ~/ 2).updateAbility(ability.startCooldown());

    return BattlerAbilityEffectResolution(
      owner: updatedOwner,
      opponent: target,
    );
  }
}

/// Convierte el primer daño recibido de cada turno en empuje ofensivo.
class NoHayRetiradaAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto pasivo de No Hay Retirada.
  const NoHayRetiradaAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.turnStart,
            BattlerAbilityHook.receiveDamageResolved,
          },
        );

  @override
  BattlerAbilityEffectResolution onTurnStart({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required bool isOwnerTurn,
  }) {
    if (ability.isActive) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
    }

    return BattlerAbilityEffectResolution(
      owner: owner.updateAbility(ability.activate()),
      opponent: opponent,
    );
  }

  @override
  BattlerAbilityEffectResolution onReceiveDamageResolved({
    required Battler owner,
    required Battler source,
    required BattlerAbility ability,
    required int damageTaken,
  }) {
    if (!ability.isActive || damageTaken <= 0) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: source);
    }

    final amount = max(1, ability.currentValue);
    final hadPotencia = owner.hasStatus(PotenciaStatus.statusId);
    var updatedOwner = owner.applyStatusFromSource(
      PotenciaStatus(value: amount),
      source: owner,
    );
    if (hadPotencia) {
      updatedOwner = _applyOrIncreaseCalentando(
        owner: updatedOwner,
        amount: amount,
      );
    }

    return BattlerAbilityEffectResolution(
      owner: updatedOwner.updateAbility(ability.deactivate()),
      opponent: source,
    );
  }
}

bool _hasOnlyMercanteOrGeneralOwnedItems(Battler owner) {
  final ownedItems = <Item>[
    ...owner.inventoryItems,
    ...owner.equippedItems,
  ];

  return ownedItems.every(
    (item) =>
        item.hasArchetypeAffinity(ItemArchetypeAffinity.general) ||
        item.hasArchetypeAffinity(ItemArchetypeAffinity.mercante),
  );
}

Set<ItemArchetypeAffinity> _distinctEquippedSpecificArchetypes(
  Battler owner, {
  bool includeMercante = true,
}) {
  final archetypes = <ItemArchetypeAffinity>{};

  for (final item in owner.equippedItems) {
    for (final affinity in item.archetypeAffinities) {
      if (!affinity.isSpecific) continue;
      if (!includeMercante && affinity == ItemArchetypeAffinity.mercante) {
        continue;
      }
      archetypes.add(affinity);
    }
  }

  return archetypes;
}

int _missingHealthStepBonus(Battler owner, BattlerAbility ability) {
  if (owner.maxHealth <= 0) return 0;

  final missingHealth = max(0, owner.maxHealth - owner.health);
  final missingPercent = min(90, (missingHealth * 100) ~/ owner.maxHealth);
  final missingSteps = missingPercent ~/ 15;

  return max(0, ability.currentValue) * missingSteps;
}

Battler _applyOrIncreaseCalentando({
  required Battler owner,
  required int amount,
}) {
  final currentStatus = owner.statusById(CalentandoStatus.statusId);
  if (currentStatus is! CalentandoStatus) {
    return owner.applyStatusFromSource(
      CalentandoStatus(value: amount),
      source: owner,
    );
  }

  return owner.applyStatus(
    currentStatus.copyWith(
      value: currentStatus.value + amount,
      remainingTurns: max(
        currentStatus.remainingTurns,
        CalentandoStatus.defaultDuration,
      ),
    ),
    applyEquipmentModifiers: false,
  );
}

Battler _deactivateCycleRouteAbility({
  required Battler owner,
  required BattlerAbilityId excludedAbilityId,
  required BattlerAbilityId targetAbilityId,
}) {
  final targetAbility = owner.abilityById(targetAbilityId);
  if (targetAbility == null ||
      targetAbility.id == excludedAbilityId ||
      !targetAbility.isActive) {
    return owner;
  }

  return owner.updateAbility(targetAbility.deactivate());
}
