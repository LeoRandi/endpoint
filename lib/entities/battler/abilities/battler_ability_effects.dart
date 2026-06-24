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

  /// Suma el value actual solo mientras la habilidad siga activada.
  @override
  int modifyOutgoingDamage({
    required Battler owner,
    required Battler target,
    required BattlerAbility ability,
    required int damage,
  }) {
    if (!ability.isActive) return damage;

    return damage + ability.currentValue;
  }

  /// Consume la activacion al resolver el golpe y arranca su cooldown.
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

  /// Suma daño solo si el objetivo ya tiene al menos un debuff.
  @override
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

  /// Divide el daño entrante por el value cuando el usuario esta intacto.
  @override
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

  /// Resuelve el disparo de inicio de turno de esta habilidad.
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
      updatedOwner = updatedOwner.runtimeApplyStatusFromSource(
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

  /// Resuelve la activacion manual de la habilidad para el contexto actual.
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
      updatedOwner = updatedOwner.gainCombatBarrier(amount * 2);
    }
    if (cycleContext.isNight) {
      updatedOwner = updatedOwner.runtimeApplyStatusFromSource(
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

  /// Resuelve la activacion manual de la habilidad para el contexto actual.
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
    var updatedOpponent = opponent;

    if (cycleContext.isDay) {
      final resolution = _applyAbilityStatusToOpponentFromOwner(
        owner: updatedOwner,
        opponent: updatedOpponent,
        status: ConmocionStatus(value: amount),
      );
      updatedOwner = resolution.owner;
      updatedOpponent = resolution.opponent;
    }
    if (cycleContext.isNight) {
      final resolution = _applyAbilityStatusToOpponentFromOwner(
        owner: updatedOwner,
        opponent: updatedOpponent,
        status: FragilidadStatus(value: amount),
      );
      updatedOwner = resolution.owner;
      updatedOpponent = resolution.opponent;
    }

    return BattlerAbilityEffectResolution(
      owner: updatedOwner.updateAbility(ability.startCooldown()),
      opponent: updatedOpponent,
    );
  }
}

/// Protege de dia y añade presion ofensiva de noche.
class TurnoDeNocheAbilityEffect extends BattlerAbilityEffect {
  /// Crea la pasiva de Turno de Noche.
  const TurnoDeNocheAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.outgoingDamageModifier,
            BattlerAbilityHook.incomingDamageModifier,
          },
        );

  /// Ajusta el daño saliente del portador mientras la habilidad aplique.
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

  /// Ajusta el daño entrante del portador mientras la habilidad aplique.
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

  /// Resuelve la activacion manual de la habilidad para el contexto actual.
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

  /// Limpia o transforma estado temporal de la habilidad al cerrar combate.
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

  /// Resuelve la activacion manual de la habilidad para el contexto actual.
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

  /// Limpia o transforma estado temporal de la habilidad al cerrar combate.
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

  /// Resuelve la activacion manual de la habilidad para el contexto actual.
  @override
  BattlerAbilityEffectResolution onManualActivation({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlerAbilityActivationContext screenContext,
  }) {
    final activeTurns = min(3, max(1, ability.currentValue));
    final updatedOwner = owner
        .runtimeApplyStatusFromSource(
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

  /// Coloca el debuff en el rival y pone la habilidad en cooldown.
  @override
  BattlerAbilityEffectResolution onManualActivation({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlerAbilityActivationContext screenContext,
  }) {
    final resolution = _applyAbilityStatusToOpponentFromOwner(
      owner: owner,
      opponent: opponent,
      status: CatalisisCruelStatus(value: max(2, ability.currentValue)),
    );

    return BattlerAbilityEffectResolution(
      owner: resolution.owner.updateAbility(ability.startCooldown()),
      opponent: resolution.opponent,
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

  /// Al activarse no cambia nada todavia porque el bonus se consume al atacar.
  @override
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

  /// Suma el value actual solo mientras la preparacion siga activa.
  @override
  int modifyOutgoingDamage({
    required Battler owner,
    required Battler target,
    required BattlerAbility ability,
    required int damage,
  }) {
    if (!ability.isActive) return damage;

    return damage + ability.currentValue;
  }

  /// Tras pegar, se aplica Quemadura propia y la habilidad entra en cooldown.
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

    final burnTurns = max(1, ability.currentValue ~/ 2);
    final updatedOwner = owner
        .runtimeApplyStatusFromSource(
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

  /// Purga debuffs, luego hace daño propio y finalmente inicia el cooldown.
  @override
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
        .runtimeReceiveDamage(selfDamage)
        .updateAbility(ability.startCooldown());

    return BattlerAbilityEffectResolution(
      owner: updatedOwner,
      opponent: opponent,
    );
  }
}

/// Convierte cada nueva hora de la run en una entrada directa de capital.
class CashflowAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto pasivo del Mercante para entregar creditos fijos.
  const CashflowAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.hourStart,
          },
        );

  /// Resuelve el disparo pasivo al comenzar una nueva hora de run.
  @override
  Battler onHourStart({
    required Battler owner,
    required BattlerAbility ability,
  }) {
    final payout = max(0, ability.currentValue);
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
            BattlerAbilityHook.turnEnd,
          },
        );

  /// Resuelve el disparo de final de turno de esta habilidad.
  @override
  BattlerAbilityEffectResolution onTurnEnd({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required bool isOwnerTurn,
  }) {
    if (!isOwnerTurn) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
    }

    return BattlerAbilityEffectResolution(
      owner: owner.gainCombatBarrier(max(0, ability.currentValue)),
      opponent: opponent,
    );
  }
}

/// Manual de combate que carga Barrera y Resonancia a la vez.
class PulsoArmonicoAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto de Pulso Armonico.
  const PulsoArmonicoAbilityEffect();

  /// Resuelve la activacion manual de la habilidad para el contexto actual.
  @override
  BattlerAbilityEffectResolution onManualActivation({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlerAbilityActivationContext screenContext,
  }) {
    final amount = max(1, ability.currentValue);
    final updatedOwner = owner
        .gainCombatBarrier(amount)
        .gainResonance(amount)
        .updateAbility(ability.startCooldown());

    return BattlerAbilityEffectResolution(
      owner: updatedOwner,
      opponent: opponent,
    );
  }
}

/// Pasiva que aumenta el daño de Resonancia con Barrera alta.
class MasaCriticaAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto pasivo de Masa Critica.
  const MasaCriticaAbilityEffect();
}

/// Pasiva que añade un impacto basico y activa la dilucion positiva compartida.
class AceleracionFotovoltaicaAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto de Aceleracion Fotovoltaica.
  const AceleracionFotovoltaicaAbilityEffect()
      : super(
          hooks: const {BattlerAbilityHook.basicAttackCountModifier},
        );

  /// Ajusta cuantas veces se resuelve el ataque basico.
  @override
  int modifyBasicAttackCount({
    required Battler owner,
    required BattlerAbility ability,
    required int count,
  }) {
    return count + max(1, ability.currentValue);
  }
}

class B4r3B0n3DAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto de B4r3B0n3D.
  const B4r3B0n3DAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.patternMatchResolved,
          },
        );

  /// Reacciona despues de que el Patron final se resuelva correctamente.
  @override
  BattlerAbilityEffectResolution onPatternMatchResolved({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlePatternMatchContext pattern,
  }) {
    if (pattern.activatedItemEffectCount > 0) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
    }

    final amount = max(1, ability.currentValue);
    return BattlerAbilityEffectResolution(
      owner: owner
          .gainCombatBarrier(amount)
          .applyStatus(PotenciaStatus(value: amount)),
      opponent: opponent,
    );
  }
}

class CompensadorRutaAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto de CompensadorRuta.
  const CompensadorRutaAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.combatStart,
          },
        );

  /// Resuelve el disparo de inicio de combate para este efecto.
  @override
  Battler onCombatStart({
    required Battler owner,
    required BattlerAbility ability,
  }) {
    final stats = <BattlerStat>[
      BattlerStat.health,
      BattlerStat.attack,
      BattlerStat.barrier,
    ];
    const itemTotals = <BattlerStat, int>{};
    final selectedStat = stats.reduce((best, stat) {
      final bestValue = itemTotals[best] ?? 0;
      final nextValue = itemTotals[stat] ?? 0;
      return nextValue < bestValue ? stat : best;
    });

    final amount = max(1, ability.currentValue);
    final updatedOwner = owner.applyStatus(
      CompensadorRutaStatus(
        stat: selectedStat,
        value: amount,
      ),
      applyEquipmentModifiers: false,
    );
    if (selectedStat != BattlerStat.health) return updatedOwner;

    return updatedOwner.heal(amount);
  }
}

class ATodoRiesgoAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto de ATodoRiesgo.
  const ATodoRiesgoAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.incomingDamageEffect,
          },
        );

  /// Intercepta daño entrante antes de que se aplique al portador.
  @override
  BattlerIncomingDamageResolution onIncomingDamage({
    required Battler owner,
    required Battler source,
    required BattlerAbility ability,
    required int damage,
    required DamageKind kind,
  }) {
    const triggeredFlag = CombatRuntimeFlag.battler(
      BattlerCombatFlag.aTodoRiesgoTriggered,
    );
    final hpDamage = kind == DamageKind.debuff
        ? max(0, damage)
        : max(0, damage - owner.currentBarrier);
    if (hpDamage <= 0 || owner.hasCombatFlag(triggeredFlag)) {
      return BattlerIncomingDamageResolution(owner: owner, damage: damage);
    }

    return BattlerIncomingDamageResolution(
      owner: owner
          .addCombatFlag(triggeredFlag)
          .earnMoney(hpDamage + max(1, ability.currentValue)),
      damage: damage,
    );
  }
}

class DeudaSangreAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto de DeudaSangre.
  const DeudaSangreAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.receiveDamageResolved,
          },
        );

  /// Reacciona justo despues de que el portador reciba daño.
  @override
  BattlerAbilityEffectResolution onReceiveDamageResolved({
    required Battler owner,
    required Battler source,
    required BattlerAbility ability,
    required int damageTaken,
  }) {
    const triggeredFlag = CombatRuntimeFlag.battler(
      BattlerCombatFlag.deudaSangreTriggeredThisTurn,
    );
    if (damageTaken <= 0 ||
        owner.healthLostThisHit <= 0 ||
        owner.hasCombatFlag(triggeredFlag)) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: source);
    }

    final missingHp = max(0, owner.maxHealth - owner.health);
    final desafio = min(max(1, ability.currentValue), missingHp ~/ 5);
    final flaggedOwner = owner.addCombatFlag(triggeredFlag);
    return BattlerAbilityEffectResolution(
      owner: desafio <= 0 ? flaggedOwner : flaggedOwner.gainDesafio(desafio),
      opponent: source,
    );
  }
}

class ComisionRiesgoAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto de ComisionRiesgo.
  const ComisionRiesgoAbilityEffect();
}

class FranquiciaTotalAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto de FranquiciaTotal.
  const FranquiciaTotalAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.combatStart,
          },
        );

  /// Resuelve el disparo de inicio de combate para este efecto.
  @override
  Battler onCombatStart({
    required Battler owner,
    required BattlerAbility ability,
  }) {
    final mercanteItemCount = owner.equippedItems
        .where(
          (item) => item.hasArchetypeAffinity(ItemArchetypeAffinity.mercante),
        )
        .length;
    if (mercanteItemCount <= 0) return owner;

    return owner.earnMoney(max(1, ability.currentValue) * mercanteItemCount);
  }
}

class UltimaPiezaAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto de UltimaPieza.
  const UltimaPiezaAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.combatStart,
          },
        );

  /// Resuelve el disparo de inicio de combate para este efecto.
  @override
  Battler onCombatStart({
    required Battler owner,
    required BattlerAbility ability,
  }) {
    if (owner.equippedItems.isEmpty) return owner;

    final selected = owner.equippedItems.reduce((best, item) {
      final bestScore = _itemBonusComplexity(best);
      final nextScore = _itemBonusComplexity(item);
      return nextScore < bestScore ? item : best;
    });
    final amount = max(1, ability.currentValue);
    final boosted = _boostLastPieceItem(item: selected, amount: amount);

    return _replaceEquippedItem(
      owner: owner,
      currentItem: selected,
      replacement: boosted,
    );
  }
}

class GeometriaBolsilloAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto de GeometriaBolsillo.
  const GeometriaBolsilloAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.combatStart,
          },
        );

  /// Resuelve el disparo de inicio de combate para este efecto.
  @override
  Battler onCombatStart({
    required Battler owner,
    required BattlerAbility ability,
  }) {
    final limit = max(1, ability.currentValue);
    var updatedOwner = owner;
    var applied = 0;
    final candidates = owner.equippedItems
        .where((item) => item.patternEffects.isEmpty)
        .toList(growable: false)
      ..sort((a, b) => _stableItemSeed(a).compareTo(_stableItemSeed(b)));

    for (final item in candidates) {
      if (applied >= limit) break;

      final seed = _stableItemSeed(item) + applied;
      final replacement = item.copyWith(
        effects: <Effect, int>{
          ...item.effects,
          PatternEffect(
            patternType: _randomishPatternRequirement(seed),
            actionEffect: ActionEffect(
              actionType:
                  seed.isEven ? ItemActionType.attack : ItemActionType.block,
              value: 1,
            ),
          ): 0,
        },
      );
      updatedOwner = _replaceEquippedItem(
        owner: updatedOwner,
        currentItem: item,
        replacement: replacement,
      );
      applied++;
    }

    return updatedOwner;
  }
}

/// Convierte Barrera activa en una descarga directa de Resonancia.
class DescargaSismicaAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto manual de Descarga Sismica.
  const DescargaSismicaAbilityEffect();

  /// Resuelve la activacion manual de la habilidad para el contexto actual.
  @override
  BattlerAbilityEffectResolution onManualActivation({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlerAbilityActivationContext screenContext,
  }) {
    final availableBarrier = max(0, owner.currentBarrier);
    final consumedBarrier = min(availableBarrier, max(0, ability.currentValue));
    final resonanceDamage =
        consumedBarrier <= 0 ? 0 : owner.resonanceDamageFor(consumedBarrier);
    var updatedOwner = owner.copyWith(
      currentBarrier: max(0, owner.currentBarrier - consumedBarrier),
    );
    var updatedOpponent = resonanceDamage <= 0
        ? opponent
        : opponent.runtimeReceiveDirectDamage(
            resonanceDamage,
            source: updatedOwner,
          );

    if (consumedBarrier > 0 && consumedBarrier >= availableBarrier) {
      final statusResolution = _applyAbilityStatusToOpponentFromOwner(
        owner: updatedOwner,
        opponent: updatedOpponent,
        status: ConmocionStatus(
          value: max(1, ability.currentValue ~/ 2),
        ),
      );
      updatedOwner = statusResolution.owner;
      updatedOpponent = statusResolution.opponent;
    }

    updatedOwner = updatedOwner
        .gainBarrierFromResonanceDamage(resonanceDamage)
        .updateAbility(ability.startCooldown());

    return BattlerAbilityEffectResolution(
      owner: updatedOwner,
      opponent: updatedOpponent,
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

  /// Resuelve la activacion manual de la habilidad para el contexto actual.
  @override
  BattlerAbilityEffectResolution onManualActivation({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlerAbilityActivationContext screenContext,
  }) {
    return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
  }

  /// Reacciona justo despues de que el portador resuelva un ataque.
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
        .gainCombatBarrier(drainedBarrier)
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

  /// Resuelve la activacion manual de la habilidad para el contexto actual.
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

  /// Reacciona justo despues de que el portador resuelva un ataque.
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

  /// Resuelve el disparo de inicio de turno de esta habilidad.
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

  /// Reacciona justo despues de que el portador reciba daño.
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
        : source.runtimeReceiveDirectDamage(
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

  /// Resuelve la activacion manual de la habilidad para el contexto actual.
  @override
  BattlerAbilityEffectResolution onManualActivation({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlerAbilityActivationContext screenContext,
  }) {
    final poisonValue = max(0, ability.currentValue);
    final currentPoison = opponent.statusById(IntoxicacionStatus.statusId);
    if (currentPoison is IntoxicacionStatus) {
      return BattlerAbilityEffectResolution(
        owner: owner.updateAbility(ability.startCooldown()),
        opponent: opponent.replaceStatusInstance(
          currentStatus: currentPoison,
          replacement: currentPoison.copyWith(
            value: currentPoison.value + poisonValue,
          ),
        ),
      );
    }

    final resolution = _applyAbilityStatusToOpponentFromOwner(
      owner: owner,
      opponent: opponent,
      status: IntoxicacionStatus(value: max(1, poisonValue)),
    );

    return BattlerAbilityEffectResolution(
      owner: resolution.owner.updateAbility(ability.startCooldown()),
      opponent: resolution.opponent,
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

  /// Ajusta el daño saliente del portador mientras la habilidad aplique.
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

  /// Resuelve la activacion manual de la habilidad para el contexto actual.
  @override
  BattlerAbilityEffectResolution onManualActivation({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlerAbilityActivationContext screenContext,
  }) {
    var updatedOwner = owner;
    var updatedOpponent = opponent;
    final loops = max(1, ability.currentValue);

    for (var index = 0; index < loops; index++) {
      final transferableIndexes = <int>[];
      for (var statusIndex = 0;
          statusIndex < updatedOwner.statuses.length;
          statusIndex++) {
        final status = updatedOwner.statuses[statusIndex];
        if (status.type != BattlerStatusType.debuff ||
            status.isIndefinite ||
            status.remainingTurns <= 0) {
          continue;
        }
        transferableIndexes.add(statusIndex);
      }
      if (transferableIndexes.isEmpty) break;

      final selectedIndex = _stableSelectionIndex(
        owner: updatedOwner,
        opponent: updatedOpponent,
        length: transferableIndexes.length,
        salt: index + 211,
      );
      final selectedStatusIndex = transferableIndexes[selectedIndex];
      final selectedDebuff = updatedOwner.statuses[selectedStatusIndex];
      final transferredDebuff = selectedDebuff.copyWith(remainingTurns: 1);
      final nextRemainingTurns = selectedDebuff.remainingTurns - 1;

      final updatedStatuses = List<BattlerStatus>.from(updatedOwner.statuses);
      if (nextRemainingTurns <= 0) {
        updatedStatuses.removeAt(selectedStatusIndex);
      } else {
        updatedStatuses[selectedStatusIndex] = selectedDebuff.copyWith(
          remainingTurns: nextRemainingTurns,
        );
      }
      updatedOwner = updatedOwner.copyWith(
        statuses: List<BattlerStatus>.unmodifiable(updatedStatuses),
      );

      updatedOpponent = updatedOpponent.applyStatus(
        transferredDebuff,
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

  /// Resuelve la activacion manual de la habilidad para el contexto actual.
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

  /// Resuelve el disparo de inicio de turno de esta habilidad.
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

  /// Reacciona justo despues de que el portador resuelva un ataque.
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
        : target.runtimeReceiveDirectDamage(
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

  /// Resuelve la activacion manual de la habilidad para el contexto actual.
  @override
  BattlerAbilityEffectResolution onManualActivation({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlerAbilityActivationContext screenContext,
  }) {
    return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
  }

  /// Ajusta el daño entrante del portador mientras la habilidad aplique.
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

  /// Reacciona justo despues de que el portador reciba daño.
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
        : source.runtimeReceiveDirectDamage(
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

  /// Resuelve la activacion manual de la habilidad para el contexto actual.
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

  /// Resuelve la activacion manual de la habilidad para el contexto actual.
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

  /// Resuelve el disparo de inicio de turno de esta habilidad.
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

  /// Resuelve la activacion manual de la habilidad para el contexto actual.
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

  /// Ajusta el daño saliente del portador mientras la habilidad aplique.
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

  /// Reacciona justo despues de que el portador resuelva un ataque.
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

  /// Ajusta el daño saliente del portador mientras la habilidad aplique.
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

  /// Resuelve la activacion manual de la habilidad para el contexto actual.
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

  /// Resuelve el disparo de inicio de turno de esta habilidad.
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

  /// Ajusta el daño saliente del portador mientras la habilidad aplique.
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

  /// Reacciona justo despues de que el portador resuelva un ataque.
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

  /// Resuelve la activacion manual de la habilidad para el contexto actual.
  @override
  BattlerAbilityEffectResolution onManualActivation({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlerAbilityActivationContext screenContext,
  }) {
    return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
  }

  /// Ajusta el daño saliente del portador mientras la habilidad aplique.
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

  /// Reacciona justo despues de que el portador resuelva un ataque.
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

  /// Resuelve el disparo de inicio de turno de esta habilidad.
  @override
  BattlerAbilityEffectResolution onTurnStart({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required bool isOwnerTurn,
  }) {
    if (ability.isActive || owner.combatRound > 1) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
    }

    return BattlerAbilityEffectResolution(
      owner: owner.updateAbility(ability.activate()),
      opponent: opponent,
    );
  }

  /// Reacciona justo despues de que el portador reciba daño.
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
    var updatedOwner = owner.runtimeApplyStatusFromSource(
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

/// Recompensa patrones construidos solo con angulos rectos.
class GeometriaLimpiaAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto de GeometriaLimpia.
  const GeometriaLimpiaAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.patternMatchResolved,
          },
        );

  /// Reacciona despues de que el Patron final se resuelva correctamente.
  @override
  BattlerAbilityEffectResolution onPatternMatchResolved({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlePatternMatchContext pattern,
  }) {
    if (!pattern.hasOnlyRightAngles) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
    }

    final amount = max(1, ability.currentValue);
    return BattlerAbilityEffectResolution(
      owner: owner.gainCombatBarrier(amount).gainResonance(amount),
      opponent: opponent,
    );
  }
}

/// Premia patrones sin angulos agudos ni obtusos.
class PulsoIsometricoAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto de PulsoIsometrico.
  const PulsoIsometricoAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.patternMatchResolved,
          },
        );

  /// Reacciona despues de que el Patron final se resuelva correctamente.
  @override
  BattlerAbilityEffectResolution onPatternMatchResolved({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlePatternMatchContext pattern,
  }) {
    if (!pattern.hasNoAcuteOrObtuseAngles) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
    }

    final amount = max(1, ability.currentValue);
    return BattlerAbilityEffectResolution(
      owner: owner.heal(amount).gainCombatBarrier(amount),
      opponent: opponent,
    );
  }
}

/// Convierte un unico angulo agudo en daño directo adicional.
class CorteTangencialAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto de CorteTangencial.
  const CorteTangencialAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.patternMatchResolved,
          },
        );

  /// Reacciona despues de que el Patron final se resuelva correctamente.
  @override
  BattlerAbilityEffectResolution onPatternMatchResolved({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlePatternMatchContext pattern,
  }) {
    if (!pattern.hasExactlyOneAcuteAngle) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
    }

    final damage =
        (max(1, ability.currentValue) + max(0, pattern.attackBonus)).toInt();
    return BattlerAbilityEffectResolution(
      owner: owner,
      opponent: opponent.runtimeReceiveDirectDamage(damage, source: owner),
    );
  }
}

/// Convierte cada angulo agudo del Patron en Potencia para el ataque.
class CortesAgudosAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto de CortesAgudos.
  const CortesAgudosAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.patternMatchResolved,
          },
        );

  /// Reacciona despues de que el Patron final se resuelva correctamente.
  @override
  BattlerAbilityEffectResolution onPatternMatchResolved({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlePatternMatchContext pattern,
  }) {
    final count = pattern.acuteAngleCount;
    if (count <= 0) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
    }

    return BattlerAbilityEffectResolution(
      owner: owner.applyStatus(
        PotenciaStatus(value: max(1, ability.currentValue) * count),
        applyEquipmentModifiers: false,
      ),
      opponent: opponent,
    );
  }
}

/// Convierte cada rotor de 90 grados del Patron en Barrera inmediata.
class RotoresDefensivosAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto de RotoresDefensivos.
  const RotoresDefensivosAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.patternMatchResolved,
          },
        );

  /// Reacciona despues de que el Patron final se resuelva correctamente.
  @override
  BattlerAbilityEffectResolution onPatternMatchResolved({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlePatternMatchContext pattern,
  }) {
    final count = pattern.rightAngleCount;
    if (count <= 0) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
    }

    return BattlerAbilityEffectResolution(
      owner: owner.gainCombatBarrier(max(1, ability.currentValue) * count),
      opponent: opponent,
    );
  }
}

/// Reequilibra el Patron convirtiendo parte del bonus mayor hacia el menor.
class PolarizacionAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto de Polarizacion.
  const PolarizacionAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.patternMatchResolved,
          },
        );

  /// Reacciona despues de que el Patron final se resuelva correctamente.
  @override
  BattlerAbilityEffectResolution onPatternMatchResolved({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlePatternMatchContext pattern,
  }) {
    final amount = max(1, ability.currentValue);
    final attackBonus = max(0, pattern.attackBonus);
    final barrierBonus = max(0, pattern.barrierBonus);
    if (attackBonus == barrierBonus) {
      return BattlerAbilityEffectResolution(
        owner: owner.gainCombatBarrier(amount).applyStatus(
              PotenciaStatus(value: amount),
              applyEquipmentModifiers: false,
            ),
        opponent: opponent,
      );
    }
    if (attackBonus > barrierBonus) {
      return BattlerAbilityEffectResolution(
        owner: owner.gainCombatBarrier(min(amount, attackBonus)),
        opponent: opponent,
      );
    }

    return BattlerAbilityEffectResolution(
      owner: owner.applyStatus(
        PotenciaStatus(value: min(amount, barrierBonus)),
        applyEquipmentModifiers: false,
      ),
      opponent: opponent,
    );
  }
}

/// Duplica el peso defensivo de patrones amplios y estables.
class ArquitecturaPesadaAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto de ArquitecturaPesada.
  const ArquitecturaPesadaAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.patternMatchResolved,
          },
        );

  /// Reacciona despues de que el Patron final se resuelva correctamente.
  @override
  BattlerAbilityEffectResolution onPatternMatchResolved({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlePatternMatchContext pattern,
  }) {
    if (!pattern.hasNoAcuteAngles) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
    }

    final amount = max(1, ability.currentValue);
    return BattlerAbilityEffectResolution(
      owner: owner
          .gainCombatBarrier(max(0, pattern.barrierBonus))
          .gainResonance(amount),
      opponent: opponent,
    );
  }
}

/// Premia patrones que activan equipamiento de otro arquetipo.
class RutaContrabandoAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto de RutaContrabando.
  const RutaContrabandoAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.patternMatchResolved,
          },
        );

  /// Reacciona despues de que el Patron final se resuelva correctamente.
  @override
  BattlerAbilityEffectResolution onPatternMatchResolved({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlePatternMatchContext pattern,
  }) {
    final count = max(0, pattern.otherArchetypeItemCount);
    if (count <= 0) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
    }

    final amount = max(1, ability.currentValue);
    return BattlerAbilityEffectResolution(
      owner:
          owner.earnMoney(amount * count).gainCombatBarrier(amount).applyStatus(
                PotenciaStatus(value: amount),
                applyEquipmentModifiers: false,
              ),
      opponent: opponent,
    );
  }
}

/// Repite el bonus dominante cuando el patron tiene simetria.
class EcoSimetriaAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto de EcoSimetria.
  const EcoSimetriaAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.patternMatchResolved,
          },
        );

  /// Reacciona despues de que el Patron final se resuelva correctamente.
  @override
  BattlerAbilityEffectResolution onPatternMatchResolved({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlePatternMatchContext pattern,
  }) {
    if (!pattern.isSymmetric) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
    }

    final reduction = max(0, ability.currentValue);
    final strongest = max(pattern.attackBonus, pattern.barrierBonus);
    final repeatedBonus = max(0, strongest - reduction);
    if (repeatedBonus <= 0) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
    }

    var updatedOwner = owner;
    if (pattern.attackBonus >= pattern.barrierBonus) {
      updatedOwner = updatedOwner.applyStatus(
        PotenciaStatus(
          value: repeatedBonus <= 0 ? 0 : max(1, repeatedBonus ~/ 2),
        ),
        applyEquipmentModifiers: false,
      );
    }
    if (pattern.barrierBonus >= pattern.attackBonus) {
      updatedOwner = updatedOwner.gainCombatBarrier(repeatedBonus);
    }

    return BattlerAbilityEffectResolution(
      owner: updatedOwner,
      opponent: opponent,
    );
  }
}

/// Convierte un Patron perfecto en una descarga completa de Resonancia.
class PatronPerfectoAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto de PatronPerfecto.
  const PatronPerfectoAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.patternMatchResolved,
          },
        );

  /// Reacciona despues de que el Patron final se resuelva correctamente.
  @override
  BattlerAbilityEffectResolution onPatternMatchResolved({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlePatternMatchContext pattern,
  }) {
    if (!pattern.hasPerfectPattern || owner.resonanceValue <= 0) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
    }

    final resonanceDamage = owner.resonanceDamageFor(owner.resonanceValue);
    final updatedOwner = owner.gainBarrierFromResonanceDamage(resonanceDamage);
    return BattlerAbilityEffectResolution(
      owner: updatedOwner,
      opponent: opponent.runtimeReceiveDirectDamage(
        resonanceDamage,
        source: updatedOwner,
      ),
    );
  }
}

/// Convierte Calentando entrante en una curacion proporcional.
class EncendidoBrutalAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto de EncendidoBrutal.
  const EncendidoBrutalAbilityEffect();
}

/// Abre el primer item usado en Patron con una carga de Calentando.
class CombustionDirigidaAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto de CombustionDirigida.
  const CombustionDirigidaAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.patternMatchResolved,
          },
        );

  /// Reacciona despues de que el Patron final se resuelva correctamente.
  @override
  BattlerAbilityEffectResolution onPatternMatchResolved({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlePatternMatchContext pattern,
  }) {
    if (pattern.usedItemPointCount <= 0 ||
        owner.hasCombatFlag(
          const CombatRuntimeFlag.battler(
            BattlerCombatFlag.combustionDirigidaTriggered,
          ),
        )) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
    }

    final baseAmount = max(1, ability.currentValue);
    final amount =
        pattern.firstUsedItemHasAttackBonus ? baseAmount * 2 : baseAmount;
    return BattlerAbilityEffectResolution(
      owner: _applyOrIncreaseCalentando(
        owner: owner.addCombatFlag(
          const CombatRuntimeFlag.battler(
            BattlerCombatFlag.combustionDirigidaTriggered,
          ),
        ),
        amount: amount,
      ),
      opponent: opponent,
    );
  }
}

/// Convierte Calentando acumulado en Desafio y una Quemadura propia.
class PuntoIgnicionAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto de PuntoIgnicion.
  const PuntoIgnicionAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.patternMatchResolved,
          },
        );

  /// Reacciona despues de que el Patron final se resuelva correctamente.
  @override
  BattlerAbilityEffectResolution onPatternMatchResolved({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlePatternMatchContext pattern,
  }) {
    final calentando = owner.statusById(CalentandoStatus.statusId);
    if (pattern.usedItemPointCount < 3 || calentando is! CalentandoStatus) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
    }

    final resolvedCalentando = calentando.resolved(owner);
    final desafio = max(1, (max(1, resolvedCalentando.value) / 2).ceil());
    final burnTurns = max(1, ability.currentValue);
    return BattlerAbilityEffectResolution(
      owner: owner.gainDesafio(desafio).runtimeApplyStatusFromSource(
            QuemaduraStatus(remainingTurns: burnTurns),
            source: owner,
          ),
      opponent: opponent,
    );
  }
}

/// Vende una ruta repetida de Patron una vez por combate.
class ReventaCircularAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto de ReventaCircular.
  const ReventaCircularAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.patternMatchResolved,
          },
        );

  /// Reacciona despues de que el Patron final se resuelva correctamente.
  @override
  BattlerAbilityEffectResolution onPatternMatchResolved({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlePatternMatchContext pattern,
  }) {
    if (pattern.repeatedItemPointCount <= 0 ||
        owner.hasCombatFlag(
          const CombatRuntimeFlag.battler(
            BattlerCombatFlag.reventaCircularTriggered,
          ),
        )) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
    }

    return BattlerAbilityEffectResolution(
      owner: owner
          .addCombatFlag(
            const CombatRuntimeFlag.battler(
              BattlerCombatFlag.reventaCircularTriggered,
            ),
          )
          .earnMoney(max(1, ability.currentValue)),
      opponent: opponent,
    );
  }
}

/// Marca la mejora de reuso que resuelve la pipeline de items usados.
class ContratoReusoAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto de ContratoReuso.
  const ContratoReusoAbilityEffect();
}

/// Convierte creditos en daño por cada punto de item repetido.
class MercadoRecursivoAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto de MercadoRecursivo.
  const MercadoRecursivoAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.patternMatchResolved,
          },
        );

  /// Reacciona despues de que el Patron final se resuelva correctamente.
  @override
  BattlerAbilityEffectResolution onPatternMatchResolved({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlePatternMatchContext pattern,
  }) {
    var updatedOwner = owner;
    var updatedOpponent = opponent;
    final maxCreditsPerPoint = max(1, ability.currentValue);

    for (var index = 0; index < pattern.repeatedItemPointCount; index++) {
      final spent = min(maxCreditsPerPoint, updatedOwner.money);
      if (spent <= 0) break;
      updatedOwner = updatedOwner.spendMoney(spent);
      updatedOpponent = updatedOpponent.runtimeReceiveDirectDamage(
        spent,
        source: updatedOwner,
      );
    }

    return BattlerAbilityEffectResolution(
      owner: updatedOwner,
      opponent: updatedOpponent,
    );
  }
}

/// Aplica un debuff pseudoaleatorio al primer item usado en el Patron.
class AgujaToxicaAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto de AgujaToxica.
  const AgujaToxicaAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.patternMatchResolved,
          },
        );

  /// Reacciona despues de que el Patron final se resuelva correctamente.
  @override
  BattlerAbilityEffectResolution onPatternMatchResolved({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlePatternMatchContext pattern,
  }) {
    if (pattern.usedItemPointCount <= 0) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
    }

    final amount = max(1, ability.currentValue);
    final options = <BattlerStatus>[
      IntoxicacionStatus(value: amount),
      FragilidadStatus(value: amount),
      ConmocionStatus(value: amount),
      QuemaduraStatus(remainingTurns: amount),
    ];
    final selected = options[_stableSelectionIndex(
      owner: owner,
      opponent: opponent,
      length: options.length,
      salt: pattern.usedItemPointCount + pattern.attackBonus,
    )];

    return _applyAbilityStatusToOpponentFromOwner(
      owner: owner,
      opponent: opponent,
      status: selected,
    );
  }
}

/// Premia patrones largos de items con Fragilidad creciente.
class RastroInestableAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto de RastroInestable.
  const RastroInestableAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.patternMatchResolved,
          },
        );

  /// Reacciona despues de que el Patron final se resuelva correctamente.
  @override
  BattlerAbilityEffectResolution onPatternMatchResolved({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlePatternMatchContext pattern,
  }) {
    final amount = max(1, ability.currentValue);
    if (pattern.usedItemPointCount < amount + 1) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
    }

    final hasDifferentDebuff = opponent.statuses.any(
      (status) =>
          status.type == BattlerStatusType.debuff &&
          status.id != FragilidadStatus.statusId,
    );
    return _applyAbilityStatusToOpponentFromOwner(
      owner: owner,
      opponent: opponent,
      status: FragilidadStatus(value: hasDifferentDebuff ? amount * 2 : amount),
    );
  }
}

/// Marca el payoff de debuffs que resuelve la pipeline al detectar debuffs.
class CadenaNeurotoxicaAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto de CadenaNeurotoxica.
  const CadenaNeurotoxicaAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.patternMatchResolved,
          },
        );
}

/// Marca el ajuste de Patron que resuelve el servicio de patrones.
class AdaptacionAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto de Adaptacion.
  const AdaptacionAbilityEffect();
}

/// Quema a ambos combatientes al comienzo del turno del portador.
class HornoSimetricoAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto de HornoSimetrico.
  const HornoSimetricoAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.turnStart,
          },
        );

  /// Resuelve el disparo de inicio de turno para el portador.
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

    final amount = max(1, ability.currentValue);
    return BattlerAbilityEffectResolution(
      owner: owner.runtimeApplyStatusFromSource(
        QuemaduraStatus(remainingTurns: amount),
        source: owner,
      ),
      opponent: opponent.runtimeApplyStatusFromSource(
        QuemaduraStatus(remainingTurns: amount),
        source: owner,
      ),
    );
  }
}

/// Ignora debuffs entrantes limitados por combate y convierte el bloqueo en Barrera.
class CortafuegosPortatilAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto pasivo de Cortafuegos Portatil.
  const CortafuegosPortatilAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.incomingStatusModifier,
          },
        );

  /// Intercepta un estado entrante antes de que se aplique al portador.
  @override
  BattlerAbilityIncomingStatusResolution onIncomingStatus({
    required Battler owner,
    required Battler source,
    required BattlerAbility ability,
    required BattlerStatus status,
  }) {
    final maxBlocks = max(1, ability.currentValue);
    final usedBlocks = owner.battlerCombatFlagUseCount(
      BattlerCombatFlag.cortafuegosPortatilBlockedDebuff,
    );
    if (status.type != BattlerStatusType.debuff ||
        usedBlocks >= maxBlocks ||
        !owner.hasCombatFlag(Battler.combatActiveFlag)) {
      return BattlerAbilityIncomingStatusResolution(
        owner: owner,
        source: source,
        status: status,
      );
    }

    final updatedOwner = owner
        .addBattlerCombatFlagUse(
          BattlerCombatFlag.cortafuegosPortatilBlockedDebuff,
        )
        .gainCombatBarrier(2);
    return BattlerAbilityIncomingStatusResolution(
      owner: updatedOwner,
      source: source,
      status: null,
    );
  }
}

/// Acumula Fragilidad y castiga objetivos limpios con un ataque inmediato.
class MarcaDeCazaAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto manual de Marca de Caza.
  const MarcaDeCazaAbilityEffect();

  /// Resuelve la activacion manual de la habilidad para el contexto actual.
  @override
  BattlerAbilityEffectResolution onManualActivation({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlerAbilityActivationContext screenContext,
  }) {
    final amount = max(1, ability.currentValue);
    final fragilityResolution = _applyAbilityStatusToOpponentFromOwner(
      owner: owner,
      opponent: opponent,
      status: FragilidadStatus(value: amount),
    );
    final updatedOwner = fragilityResolution.owner;
    final updatedOpponent = fragilityResolution.opponent;

    final resolvedAbility = updatedOwner.abilityById(ability.id) ?? ability;
    return BattlerAbilityEffectResolution(
      owner: updatedOwner.updateAbility(resolvedAbility.startCooldown()),
      opponent: updatedOpponent,
    );
  }
}

/// Reduce el siguiente impacto recibido y luego entra en cooldown.
class ExtrabloqueoAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto manual de Extrabloqueo.
  const ExtrabloqueoAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.incomingDamageModifier,
            BattlerAbilityHook.receiveDamageResolved,
          },
        );

  /// Ajusta el daño entrante del portador mientras la habilidad aplique.
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

  /// Reacciona justo despues de que el portador reciba daño.
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

    return BattlerAbilityEffectResolution(
      owner: owner.updateAbility(ability.startCooldown()),
      opponent: source,
    );
  }
}

/// Cura en peligro o convierte esa curacion en reduccion de debuffs propios.
class TriageAutomaticoAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto pasivo de Triage Automatico.
  const TriageAutomaticoAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.turnStart,
          },
        );

  /// Resuelve el disparo de inicio de turno de esta habilidad.
  @override
  BattlerAbilityEffectResolution onTurnStart({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required bool isOwnerTurn,
  }) {
    if (!isOwnerTurn ||
        owner.maxHealth <= 0 ||
        owner.health * 2 >= owner.maxHealth) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
    }

    final amount = max(1, ability.currentValue);
    final reduction = _reducePurgeableDebuffsWithHealingBudget(
      owner: owner,
      opponent: opponent,
      budget: amount,
    );
    final updatedOwner = reduction.owner.heal(amount - reduction.spentBudget);

    return BattlerAbilityEffectResolution(
      owner: updatedOwner,
      opponent: opponent,
    );
  }
}

/// Gana Potencia y deja preparada una penalizacion para el siguiente cooldown manual.
class SobrecargaReguladaAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto manual de Sobrecarga Regulada.
  const SobrecargaReguladaAbilityEffect();

  /// Resuelve la activacion manual de la habilidad para el contexto actual.
  @override
  BattlerAbilityEffectResolution onManualActivation({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlerAbilityActivationContext screenContext,
  }) {
    final amount = max(1, ability.currentValue);
    final updatedOwner = owner
        .runtimeApplyStatusFromSource(
          PotenciaStatus(value: amount),
          source: owner,
        )
        .addCombatFlag(
          const CombatRuntimeFlag.battler(
            BattlerCombatFlag.sobrecargaReguladaPendingCooldownPenalty,
          ),
        )
        .updateAbility(ability.startCooldown());

    return BattlerAbilityEffectResolution(
      owner: updatedOwner,
      opponent: opponent,
    );
  }
}

/// Evita una muerte por ataque una vez por combate.
class CopiaDeSeguridadAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto pasivo de Copia de Seguridad.
  const CopiaDeSeguridadAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.fatalDamage,
          },
        );

  /// Intercepta daño fatal antes de que el portador quede derrotado.
  @override
  Battler onReceiveFatalDamage({
    required Battler owner,
    required BattlerAbility ability,
    required int incomingDamage,
  }) {
    final alreadyUsed = owner.battlerCombatFlagUseCount(
      BattlerCombatFlag.copiaSeguridadUsed,
    );
    if (owner.health > 0 || alreadyUsed > 0) return owner;

    return owner
        .copyWith(health: 1)
        .addBattlerCombatFlagUse(BattlerCombatFlag.copiaSeguridadUsed)
        .gainCombatBarrier(max(1, ability.currentValue));
  }
}

/// Aplica una ventana en la que los ataques enemigos fallan contra el portador.
class PuntoCiegoAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto manual de Punto Ciego.
  const PuntoCiegoAbilityEffect();

  /// Resuelve la activacion manual de la habilidad para el contexto actual.
  @override
  BattlerAbilityEffectResolution onManualActivation({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlerAbilityActivationContext screenContext,
  }) {
    final turns = max(1, ability.currentValue);
    final updatedOwner = owner
        .runtimeApplyStatusFromSource(
          PuntoCiegoStatus(
            remainingTurns: turns + 1,
            value: turns,
          ),
          source: owner,
        )
        .updateAbility(ability.startCooldown());

    return BattlerAbilityEffectResolution(
      owner: updatedOwner,
      opponent: opponent,
    );
  }
}

/// Manual que acumula Desafio para el siguiente ataque.
class ProvocacionFrontalAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto de Provocacion Frontal.
  const ProvocacionFrontalAbilityEffect();

  /// Resuelve la activacion manual de la habilidad para el contexto actual.
  @override
  BattlerAbilityEffectResolution onManualActivation({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlerAbilityActivationContext screenContext,
  }) {
    return BattlerAbilityEffectResolution(
      owner: owner.gainDesafio(max(1, ability.currentValue)).updateAbility(
            ability.startCooldown(),
          ),
      opponent: opponent,
    );
  }
}

/// Manual que prepara Desafio y deja al controlador resolver el ataque inmediato.
class CargaTemerariaAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto de Carga Temeraria.
  const CargaTemerariaAbilityEffect();

  /// Resuelve la activacion manual de la habilidad para el contexto actual.
  @override
  BattlerAbilityEffectResolution onManualActivation({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlerAbilityActivationContext screenContext,
  }) {
    return BattlerAbilityEffectResolution(
      owner: owner.gainDesafio(max(1, ability.currentValue)).updateAbility(
            ability.startCooldown(),
          ),
      opponent: opponent,
    );
  }
}

/// Pasiva que abre combate con Desafio y evita el primer contraataque por turno.
class MandatoColiseoAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto de Mandato de Coliseo.
  const MandatoColiseoAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.combatStart,
          },
        );

  /// Resuelve el disparo de inicio de turno de esta habilidad.
  @override
  Battler onCombatStart({
    required Battler owner,
    required BattlerAbility ability,
  }) {
    if (owner.hasCombatFlag(
      const CombatRuntimeFlag.battler(
        BattlerCombatFlag.mandatoColiseoOpeningGranted,
      ),
    )) {
      return owner;
    }

    return owner
        .addCombatFlag(
          const CombatRuntimeFlag.battler(
            BattlerCombatFlag.mandatoColiseoOpeningGranted,
          ),
        )
        .gainDesafio(max(1, ability.currentValue));
  }
}

class ArmaBiologicaAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto de ArmaBiologica.
  const ArmaBiologicaAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.contagioValueLost,
          },
        );

  /// Reacciona cuando Contagio pierde valor durante el combate.
  @override
  BattlerAbilityEffectResolution onContagioValueLost({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required int lostValue,
    required bool isOwnerContagioCarrier,
    required bool wasRemoved,
    required BattlerStatus triggerStatus,
  }) {
    if (isOwnerContagioCarrier) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
    }

    return BattlerAbilityEffectResolution(
      owner: owner,
      opponent: opponent.runtimeReceiveDirectDamage(
        max(1, ability.currentValue),
        source: owner,
      ),
    );
  }
}

class InmunizacionAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto de Inmunizacion.
  const InmunizacionAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.contagioValueLost,
          },
        );

  /// Reacciona cuando Contagio pierde valor durante el combate.
  @override
  BattlerAbilityEffectResolution onContagioValueLost({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required int lostValue,
    required bool isOwnerContagioCarrier,
    required bool wasRemoved,
    required BattlerStatus triggerStatus,
  }) {
    if (!isOwnerContagioCarrier) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
    }

    return BattlerAbilityEffectResolution(
      owner: owner.heal(max(1, ability.currentValue)),
      opponent: opponent,
    );
  }
}

class CargaViricaAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto de CargaVirica.
  const CargaViricaAbilityEffect();
}

class EpidemiologiaTacticaAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto de EpidemiologiaTactica.
  const EpidemiologiaTacticaAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.patternMatchResolved,
          },
        );

  /// Reacciona despues de que el Patron final se resuelva correctamente.
  @override
  BattlerAbilityEffectResolution onPatternMatchResolved({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlePatternMatchContext pattern,
  }) {
    final usedPointKeys =
        pattern.patternPoints.map((point) => point.key).toSet();
    final debuffItemCount = owner.equippedItems.where((item) {
      final itemKey = item.instanceId ?? item.catalogKey;
      final pointKey = owner.patternItemPointKeys[itemKey] ??
          owner.patternItemPointKeys[item.catalogKey];
      return pointKey != null &&
          usedPointKeys.contains(pointKey) &&
          item.hasTag(EntityTag.debuff);
    }).length;
    if (debuffItemCount < 2) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
    }

    final resolution = opponent.runtimeApplyStatusFromSourceResolved(
      ContagioStatus(value: max(1, ability.currentValue)),
      source: owner,
    );
    return BattlerAbilityEffectResolution(
      owner: resolution.source,
      opponent: resolution.owner,
    );
  }
}

class SintomasCruzadosAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto de SintomasCruzados.
  const SintomasCruzadosAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.contagioValueLost,
          },
        );

  /// Reacciona cuando Contagio pierde valor durante el combate.
  @override
  BattlerAbilityEffectResolution onContagioValueLost({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required int lostValue,
    required bool isOwnerContagioCarrier,
    required bool wasRemoved,
    required BattlerStatus triggerStatus,
  }) {
    if (isOwnerContagioCarrier) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
    }

    final BattlerStatus? followUpStatus = switch (triggerStatus) {
      QuemaduraStatus() => const IntoxicacionStatus(value: 1),
      IntoxicacionStatus() => const QuemaduraStatus(remainingTurns: 1),
      _ => null,
    };
    if (followUpStatus == null) {
      return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
    }

    final resolution = opponent.runtimeApplyStatusFromSourceResolved(
      followUpStatus,
      source: owner,
    );
    return BattlerAbilityEffectResolution(
      owner: resolution.source,
      opponent: resolution.owner,
    );
  }
}

class PacienteCeroAbilityEffect extends BattlerAbilityEffect {
  /// Crea el efecto de PacienteCero.
  const PacienteCeroAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.combatStartOpponent,
          },
        );

  /// Resuelve el disparo de inicio de combate aplicado desde el rival.
  @override
  BattlerAbilityEffectResolution onCombatStartOpponent({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
  }) {
    final velozItemCount = owner.equippedItems
        .where((item) => item.hasArchetypeAffinity(ItemArchetypeAffinity.veloz))
        .length;
    final amount = max(max(1, ability.currentValue), velozItemCount);
    final resolution = opponent.runtimeApplyStatusFromSourceResolved(
      ContagioStatus(value: amount),
      source: owner,
    );
    return BattlerAbilityEffectResolution(
      owner: resolution.source,
      opponent: resolution.owner,
    );
  }
}

class _DebuffBudgetReduction {
  final Battler owner;
  final int spentBudget;

  /// Crea el resultado de gastar presupuesto curativo reduciendo debuffs.
  const _DebuffBudgetReduction({
    required this.owner,
    required this.spentBudget,
  });
}

/// Invierte presupuesto de curacion en reducir debuffs purgables del owner.
_DebuffBudgetReduction _reducePurgeableDebuffsWithHealingBudget({
  required Battler owner,
  required Battler opponent,
  required int budget,
}) {
  var updatedOwner = owner;
  var spentBudget = 0;

  for (var index = 0; index < max(0, budget); index++) {
    final debuffs = _purgeableDebuffs(updatedOwner);
    if (debuffs.isEmpty) break;

    final selectedIndex = _stableSelectionIndex(
      owner: updatedOwner,
      opponent: opponent,
      length: debuffs.length,
      salt: index + spentBudget,
    );
    final selectedDebuff = debuffs[selectedIndex];
    if (selectedDebuff.isIndefinite ||
        selectedDebuff is IntoxicacionStatus ||
        selectedDebuff is FragilidadStatus) {
      final reducedValue = max(0, selectedDebuff.value - 1);
      if (reducedValue <= 0) {
        updatedOwner = updatedOwner.removeStatusInstance(selectedDebuff);
      } else {
        updatedOwner = updatedOwner.replaceStatusInstance(
          currentStatus: selectedDebuff,
          replacement: selectedDebuff.copyWith(value: reducedValue),
        );
      }
      spentBudget++;
      continue;
    }

    final reducedTurns = max(0, selectedDebuff.remainingTurns - 1);
    if (reducedTurns <= 0) {
      updatedOwner = updatedOwner.removeStatusInstance(selectedDebuff);
    } else {
      updatedOwner = updatedOwner.replaceStatusInstance(
        currentStatus: selectedDebuff,
        replacement: selectedDebuff.copyWith(remainingTurns: reducedTurns),
      );
    }
    spentBudget++;
  }

  return _DebuffBudgetReduction(
    owner: updatedOwner.pruneExpiredStatuses(),
    spentBudget: spentBudget,
  );
}

/// Devuelve debuffs que pueden ser reducidos o eliminados por efectos normales.
List<BattlerStatus> _purgeableDebuffs(Battler battler) {
  return battler.statuses
      .where(
        (status) =>
            status.type == BattlerStatusType.debuff && status.isPurgeable,
      )
      .toList(growable: false);
}

/// Indica si el inventario/equipo solo contiene items generalistas o Mercante.
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

/// Extrae las afinidades especificas presentes en el equipo actual.
Set<ItemArchetypeAffinity> _distinctEquippedSpecificArchetypes(
  Battler owner, {
  bool includeMercante = true,
}) {
  final archetypes = <ItemArchetypeAffinity>{};

  for (final item in owner.equippedItems) {
    final affinity = item.affinity;
    if (!affinity.isSpecific) continue;
    if (!includeMercante && affinity == ItemArchetypeAffinity.mercante) {
      continue;
    }
    archetypes.add(affinity);
  }

  return archetypes;
}

/// Calcula el bonus por tramos de vida faltante usado por habilidades Imparables.
int _missingHealthStepBonus(Battler owner, BattlerAbility ability) {
  if (owner.maxHealth <= 0) return 0;

  final missingHealth = max(0, owner.maxHealth - owner.health);
  final missingPercent = min(90, (missingHealth * 100) ~/ owner.maxHealth);
  final missingSteps = missingPercent ~/ 15;

  return max(0, ability.currentValue) * missingSteps;
}

/// Aplica Calentando o refuerza la copia ya activa sin duplicarla.
Battler _applyOrIncreaseCalentando({
  required Battler owner,
  required int amount,
}) {
  final currentStatus = owner.statusById(CalentandoStatus.statusId);
  if (currentStatus is! CalentandoStatus) {
    return owner.runtimeApplyStatusFromSource(
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

/// Reemplaza una instancia equipada conservando su posicion actual.
Battler _replaceEquippedItem({
  required Battler owner,
  required Item currentItem,
  required Item replacement,
}) {
  final equippedIndex = owner.equippedItems.indexOf(currentItem);
  if (equippedIndex < 0) return owner;

  final updatedEquippedItems = List<Item>.from(owner.equippedItems);
  updatedEquippedItems[equippedIndex] = replacement;
  return owner.copyWith(
    equippedItems: List<Item>.unmodifiable(updatedEquippedItems),
  );
}

/// Puntua cuantas vias de bonus trae un item para priorizar mejoras temporales.
int _itemBonusComplexity(Item item) {
  return item.effects.keys.where((effect) => effect.value > 0).length;
}

/// Mejora temporalmente las partes positivas de un item elegido por Last Piece.
Item _boostLastPieceItem({
  required Item item,
  required int amount,
}) {
  return item.copyWith(
    effects: <Effect, int>{
      for (final entry in item.effects.entries)
        entry.key.value > 0
            ? entry.key.withValue(entry.key.value + amount)
            : entry.key: entry.value,
    },
  );
}

/// Genera una semilla estable para decisiones visualmente aleatorias de un item.
int _stableItemSeed(Item item) {
  final instanceHash = item.instanceId?.hashCode ?? 0;
  return Object.hash(item.catalogKey, item.tier, instanceHash).abs();
}

/// Traduce una semilla estable a un requisito de Patron pseudoaleatorio.
OperativePatternRequirement _randomishPatternRequirement(int seed) {
  return switch (seed % 5) {
    0 => const OperativePatternRequirement.first(),
    1 => const OperativePatternRequirement.middle(),
    2 => const OperativePatternRequirement.last(),
    3 => const OperativePatternRequirement.rightAngle(),
    _ => const OperativePatternRequirement.straightAngle(),
  };
}
