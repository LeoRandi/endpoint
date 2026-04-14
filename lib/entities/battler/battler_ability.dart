import '../_imports.dart';

/// Enumera los ids estables usados para guardar y resolver presets de habilidades.
enum BattlerAbilityId {
  criticalScanner,
  weaknessHunter,
  ghostMesh,
  cruelCatalysis,
  venousOverload,
  hardReset,
  cashflow,
  pulsoRepL,
  sustraccion,
  limpiezaCache,
  hemostasiaAgresiva,
  mallaRebote,
  inyeccionCorrosiva,
  escanerRuptura,
  reenrutadoInverso,
  jaulaSenal,
  nucleoParasitario,
  espejoDolor,
  protocoloUsurpacion,
  refactorizacionTimeline,
}

/// Define en que pantalla puede activarse manualmente una habilidad.
enum BattlerAbilityActivationContext {
  battle,
  pathSelection,
  shop;

  /// Devuelve la etiqueta corta que usa la UI para mostrar este contexto.
  String get label {
    switch (this) {
      case BattlerAbilityActivationContext.battle:
        return 'Combate';
      case BattlerAbilityActivationContext.pathSelection:
        return 'Ruta';
      case BattlerAbilityActivationContext.shop:
        return 'Tienda';
    }
  }
}

/// Enumera los puntos del ciclo de combate en los que una habilidad puede aportar hooks.
enum BattlerAbilityHook {
  hourStart,
  turnStart,
  turnEnd,
  combatEnd,
  outgoingDamageModifier,
  incomingDamageModifier,
  attackResolved,
  receiveDamageResolved,
  passive,
}

const _ataqueAbilityTags = <EntityTag>[
  EntityTag.ataque,
];
const _ataqueDebuffAbilityTags = <EntityTag>[
  EntityTag.ataque,
  EntityTag.debuff,
];
const _vidaBarreraAbilityTags = <EntityTag>[
  EntityTag.vida,
  EntityTag.barrera,
];
const _debuffAbilityTags = <EntityTag>[
  EntityTag.debuff,
];
const _ataqueQuemaduraAbilityTags = <EntityTag>[
  EntityTag.ataque,
  EntityTag.debuff,
  EntityTag.quemadura,
];
const _vidaDebuffAbilityTags = <EntityTag>[
  EntityTag.vida,
  EntityTag.debuff,
];
const _economiaAbilityTags = <EntityTag>[
  EntityTag.economia,
];
const _buffBarreraAbilityTags = <EntityTag>[
  EntityTag.buff,
  EntityTag.barrera,
];
const _ataqueBarreraAbilityTags = <EntityTag>[
  EntityTag.ataque,
  EntityTag.barrera,
];
const _vidaAtaqueAbilityTags = <EntityTag>[
  EntityTag.vida,
  EntityTag.ataque,
];
const _intoxicacionDebuffAbilityTags = <EntityTag>[
  EntityTag.intoxicacion,
  EntityTag.debuff,
];
const _buffAtaqueAbilityTags = <EntityTag>[
  EntityTag.buff,
  EntityTag.ataque,
];
const _buffDebuffAbilityTags = <EntityTag>[
  EntityTag.buff,
  EntityTag.debuff,
];

/// Devuelve un indice pseudoaleatorio estable para efectos que piden elegir objetivos aleatorios.
int _stableSelectionIndex({
  required Battler owner,
  required Battler opponent,
  required int length,
  int salt = 0,
}) {
  if (length <= 1) return 0;

  final seed = owner.health * 31 +
      owner.currentBarrier * 17 +
      owner.money * 13 +
      owner.abilities.length * 11 +
      owner.statuses.length * 7 +
      opponent.health * 5 +
      opponent.currentBarrier * 3 +
      opponent.abilities.length * 2 +
      opponent.statuses.length +
      salt;

  return seed.abs() % length;
}

/// Agrupa el estado final del usuario y del rival tras resolver un efecto de habilidad.
class BattlerAbilityEffectResolution {
  final Battler owner;
  final Battler opponent;

  /// Crea una resolucion inmutable con ambos combatientes ya actualizados.
  const BattlerAbilityEffectResolution({
    required this.owner,
    required this.opponent,
  });
}

/// Sirve como base comun para los hooks de habilidades activas y pasivas.
abstract class BattlerAbilityEffect {
  final Set<BattlerAbilityHook> hooks;

  /// Construye un efecto sin estado propio para reutilizarlo en presets const.
  const BattlerAbilityEffect({
    this.hooks = const <BattlerAbilityHook>{},
  });

  /// Resuelve lo que pasa al activar manualmente la habilidad.
  BattlerAbilityEffectResolution onManualActivation({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required BattlerAbilityActivationContext screenContext,
  }) {
    return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
  }

  /// Resuelve efectos pasivos que deben dispararse al comenzar una nueva hora.
  Battler onHourStart({
    required Battler owner,
    required BattlerAbility ability,
  }) {
    return owner;
  }

  /// Resuelve efectos que deben dispararse al inicio de turno.
  BattlerAbilityEffectResolution onTurnStart({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required bool isOwnerTurn,
  }) {
    return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
  }

  /// Resuelve efectos que deben dispararse al final de turno.
  BattlerAbilityEffectResolution onTurnEnd({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
    required bool isOwnerTurn,
  }) {
    return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
  }

  /// Resuelve efectos puntuales al terminar el combate antes de resetear runtime.
  Battler onCombatEnd({
    required Battler owner,
    required BattlerAbility ability,
  }) {
    return owner;
  }

  /// Ajusta el dano que el portador va a infligir antes de aplicarlo.
  int modifyOutgoingDamage({
    required Battler owner,
    required Battler target,
    required BattlerAbility ability,
    required int damage,
  }) {
    return damage;
  }

  /// Ajusta el dano que el portador va a recibir antes de aplicarlo.
  int modifyIncomingDamage({
    required Battler owner,
    required Battler source,
    required BattlerAbility ability,
    required int damage,
  }) {
    return damage;
  }

  /// Resuelve efectos posteriores a que el portador complete un ataque.
  BattlerAbilityEffectResolution onAttackResolved({
    required Battler owner,
    required Battler target,
    required BattlerAbility ability,
    required int damageDealt,
  }) {
    return BattlerAbilityEffectResolution(owner: owner, opponent: target);
  }

  /// Resuelve efectos posteriores a que el portador reciba dano.
  BattlerAbilityEffectResolution onReceiveDamageResolved({
    required Battler owner,
    required Battler source,
    required BattlerAbility ability,
    required int damageTaken,
  }) {
    return BattlerAbilityEffectResolution(owner: owner, opponent: source);
  }

  /// Aplica efectos pasivos que deben reevaluarse sin necesidad de un evento puntual.
  BattlerAbilityEffectResolution applyPassive({
    required Battler owner,
    required Battler opponent,
    required BattlerAbility ability,
  }) {
    return BattlerAbilityEffectResolution(owner: owner, opponent: opponent);
  }
}

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

/// Premia atacar objetivos ya debilitados con dano extra constante.
class WeaknessHunterAbilityEffect extends BattlerAbilityEffect {
  /// Crea un efecto reutilizable para el preset de Caza de debilidades.
  const WeaknessHunterAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.outgoingDamageModifier,
          },
        );

  @override

  /// Suma dano solo si el objetivo ya tiene al menos un debuff.
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

/// Reduce el dano recibido mientras el portador siga con la vida al maximo.
class GhostMeshAbilityEffect extends BattlerAbilityEffect {
  /// Crea un efecto reutilizable para el preset de Malla Fantasma.
  const GhostMeshAbilityEffect()
      : super(
          hooks: const {
            BattlerAbilityHook.incomingDamageModifier,
          },
        );

  @override

  /// Divide el dano entrante por el value cuando el usuario esta intacto.
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
    final updatedOpponent = opponent.applyStatus(
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
        .applyStatus(
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

  /// Purga debuffs, luego hace dano propio y finalmente inicia el cooldown.
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

/// Devuelve dano al primer ataque recibido en cada turno del portador.
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
        : opponent.applyStatus(
            IntoxicacionStatus(value: max(1, poisonValue)),
            source: owner,
          );

    return BattlerAbilityEffectResolution(
      owner: owner.updateAbility(ability.startCooldown()),
      opponent: updatedOpponent,
    );
  }
}

/// Aumenta el dano al golpear enemigos que tengan buffs activos.
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

/// Reduce el siguiente dano recibido y refleja un contraataque adicional.
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

/// Describe una habilidad completa, incluyendo su estado runtime y su efecto.
class BattlerAbility {
  final BattlerAbilityId id;
  final RarityTier rarity;
  final List<EntityTag> tags;
  final String name;
  final String description;
  final IconData icon;
  final int cooldownTurns;
  final int remainingCooldownTurns;
  final int value;
  final int upgradeValue;
  final int runtimeValueBonus;
  final bool isActive;
  final BattlerAbilityActivationContext? manualActivationContext;
  final BattlerAbilityEffect? effect;
  final bool isImplemented;

  /// Crea una habilidad inmutable lista para usarse como preset o como instancia runtime.
  const BattlerAbility({
    required this.id,
    this.rarity = RarityTier.gray,
    this.tags = const [],
    required this.name,
    required this.description,
    required this.icon,
    this.cooldownTurns = 0,
    this.remainingCooldownTurns = 0,
    this.value = 0,
    this.upgradeValue = 0,
    this.runtimeValueBonus = 0,
    this.isActive = false,
    this.manualActivationContext,
    this.effect,
    this.isImplemented = true,
  })  : assert(cooldownTurns >= 0),
        assert(remainingCooldownTurns >= 0);

  /// Indica si esta habilidad tiene hooks propios que deben ejecutarse.
  bool get hasEffect => effect != null;

  /// Expone los hooks activos del efecto para que el battler pueda indexarlos.
  Set<BattlerAbilityHook> get hookBindings =>
      effect?.hooks ?? const <BattlerAbilityHook>{};

  /// Indica si la habilidad tiene al menos una tag visible o filtrable.
  bool get hasTags => tags.isNotEmpty;

  /// Comprueba si esta habilidad pertenece a una tag concreta.
  bool hasTag(EntityTag tag) => tags.contains(tag);

  /// Reexpone el color de rareza para que la UI no tenga que duplicar este lookup.
  Color get accent => rarity.accent;

  /// Indica si la habilidad puede activarse desde alguna pantalla.
  bool get canManuallyActivate => manualActivationContext != null;

  /// Indica si la habilidad es pasiva y no requiere ninguna pantalla para activarse.
  bool get isPassive => manualActivationContext == null;

  /// Indica si la habilidad sigue esperando a que termine su cooldown.
  bool get isOnCooldown => remainingCooldownTurns > 0;

  /// Devuelve el value base mas los bonus temporales ganados en combate.
  int get currentValue => value + runtimeValueBonus;

  /// Indica si esta habilidad todavia puede escalar un tier mas.
  bool get canUpgrade {
    final baseAbility = presetForId(id);
    final resolvedUpgradeValue =
        upgradeValue > 0 ? upgradeValue : baseAbility.upgradeValue;

    return resolvedUpgradeValue > 0 && !rarity.isMaxTier;
  }

  /// Indica cuantas mejoras visibles lleva esta habilidad respecto a su preset.
  int get upgradeCount {
    final baseAbility = presetForId(id);
    final resolvedUpgradeValue =
        upgradeValue > 0 ? upgradeValue : baseAbility.upgradeValue;
    if (resolvedUpgradeValue <= 0 || value <= baseAbility.value) {
      return 0;
    }

    return max(0, (value - baseAbility.value) ~/ resolvedUpgradeValue);
  }

  /// Devuelve el nombre visible de la habilidad sin marcadores extras de mejora.
  String get displayName => name;

  /// Devuelve el cooldown base en un formato corto para la interfaz.
  String get cooldownLabel {
    if (cooldownTurns <= 0) return 'Sin cooldown';
    if (cooldownTurns == 1) return '1 turno';
    return '$cooldownTurns turnos';
  }

  /// Devuelve el estado actual del cooldown en un formato corto para la interfaz.
  String get remainingCooldownLabel {
    if (!isOnCooldown) return 'Disponible';
    if (remainingCooldownTurns == 1) return '1 turno';
    return '$remainingCooldownTurns turnos';
  }

  /// Comprueba si esta habilidad pertenece al contexto manual indicado.
  bool canToggleOn(BattlerAbilityActivationContext screenContext) {
    return manualActivationContext == screenContext;
  }

  /// Indica si esta habilidad debe mostrarse en la interfaz del contexto indicado.
  bool appearsInContext(BattlerAbilityActivationContext screenContext) {
    return isPassive || canToggleOn(screenContext);
  }

  /// Comprueba si puede activarse ahora mismo sin estar activa ni en cooldown.
  bool canActivateOn(BattlerAbilityActivationContext screenContext) {
    return canToggleOn(screenContext) && !isActive && !isOnCooldown;
  }

  /// Comprueba si puede apagarse manualmente en el contexto actual.
  bool canDeactivateOn(BattlerAbilityActivationContext screenContext) {
    return canToggleOn(screenContext) && isActive;
  }

  /// Devuelve una version mejorada subiendo tier y valor hasta el limite amarillo.
  BattlerAbility upgraded() {
    final upgradeTemplate = canUpgrade ? this : presetForId(id);
    if (!upgradeTemplate.canUpgrade) return this;

    return copyWith(
      rarity: rarity.nextTier,
      tags: upgradeTemplate.tags,
      name: upgradeTemplate.name,
      description: upgradeTemplate.description,
      icon: upgradeTemplate.icon,
      cooldownTurns: upgradeTemplate.cooldownTurns,
      value: value + upgradeTemplate.upgradeValue,
      upgradeValue: upgradeTemplate.upgradeValue,
      manualActivationContext: upgradeTemplate.manualActivationContext,
      effect: upgradeTemplate.effect,
      isImplemented: upgradeTemplate.isImplemented,
    );
  }

  /// Marca la habilidad como activa sin tocar todavia su cooldown.
  BattlerAbility activate() => copyWith(isActive: true);

  /// Desactiva la habilidad y limpia cualquier bonus temporal asociado.
  BattlerAbility deactivate() => copyWith(
        isActive: false,
        runtimeValueBonus: 0,
      );

  /// Entra en cooldown, se desactiva y limpia los bonus temporales.
  BattlerAbility startCooldown() {
    return copyWith(
      isActive: false,
      remainingCooldownTurns: cooldownTurns,
      runtimeValueBonus: 0,
    );
  }

  /// Reduce en uno el cooldown al inicio de turno cuando proceda.
  BattlerAbility tickCooldown() {
    if (!isOnCooldown || isActive) return this;

    return copyWith(
      remainingCooldownTurns: max(0, remainingCooldownTurns - 1),
    );
  }

  /// Devuelve la habilidad a su estado limpio para salir de combate o resetear.
  BattlerAbility resetState() {
    return copyWith(
      isActive: false,
      remainingCooldownTurns: 0,
      runtimeValueBonus: 0,
    );
  }

  /// Acumula un bonus temporal al value sin alterar el preset base.
  BattlerAbility addRuntimeValueBonus(int amount) {
    if (amount == 0) return this;

    return copyWith(runtimeValueBonus: runtimeValueBonus + amount);
  }

  /// Reduce el cooldown restante sin permitir valores negativos.
  BattlerAbility reduceCooldown(int amount) {
    if (amount <= 0 || !isOnCooldown) return this;

    return copyWith(
      remainingCooldownTurns: max(0, remainingCooldownTurns - amount),
    );
  }

  /// Clona la habilidad permitiendo cambiar cualquier parte de su estado.
  BattlerAbility copyWith({
    RarityTier? rarity,
    List<EntityTag>? tags,
    String? name,
    String? description,
    IconData? icon,
    int? cooldownTurns,
    int? remainingCooldownTurns,
    int? value,
    int? upgradeValue,
    int? runtimeValueBonus,
    bool? isActive,
    BattlerAbilityActivationContext? manualActivationContext,
    bool clearManualActivationContext = false,
    BattlerAbilityEffect? effect,
    bool clearEffect = false,
    bool? isImplemented,
  }) {
    return BattlerAbility(
      id: id,
      rarity: rarity ?? this.rarity,
      tags: tags ?? this.tags,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      cooldownTurns: max(0, cooldownTurns ?? this.cooldownTurns),
      remainingCooldownTurns: max(
        0,
        remainingCooldownTurns ?? this.remainingCooldownTurns,
      ),
      value: value ?? this.value,
      upgradeValue: upgradeValue ?? this.upgradeValue,
      runtimeValueBonus: runtimeValueBonus ?? this.runtimeValueBonus,
      isActive: isActive ?? this.isActive,
      manualActivationContext: clearManualActivationContext
          ? null
          : manualActivationContext ?? this.manualActivationContext,
      effect: clearEffect ? null : effect ?? this.effect,
      isImplemented: isImplemented ?? this.isImplemented,
    );
  }

  /// Devuelve el preset canonico asociado a un id de habilidad.
  static BattlerAbility presetForId(BattlerAbilityId id) {
    switch (id) {
      case BattlerAbilityId.criticalScanner:
        return criticalScannerAbility;
      case BattlerAbilityId.weaknessHunter:
        return weaknessHunterAbility;
      case BattlerAbilityId.ghostMesh:
        return ghostMeshAbility;
      case BattlerAbilityId.cruelCatalysis:
        return cruelCatalysisAbility;
      case BattlerAbilityId.venousOverload:
        return venousOverloadAbility;
      case BattlerAbilityId.hardReset:
        return hardResetAbility;
      case BattlerAbilityId.cashflow:
        return cashflowAbility;
      case BattlerAbilityId.pulsoRepL:
        return pulsoRepLAbility;
      case BattlerAbilityId.sustraccion:
        return sustraccionAbility;
      case BattlerAbilityId.limpiezaCache:
        return limpiezaCacheAbility;
      case BattlerAbilityId.hemostasiaAgresiva:
        return hemostasiaAgresivaAbility;
      case BattlerAbilityId.mallaRebote:
        return mallaReboteAbility;
      case BattlerAbilityId.inyeccionCorrosiva:
        return inyeccionCorrosivaAbility;
      case BattlerAbilityId.escanerRuptura:
        return escanerRupturaAbility;
      case BattlerAbilityId.reenrutadoInverso:
        return reenrutadoInversoAbility;
      case BattlerAbilityId.jaulaSenal:
        return jaulaSenalAbility;
      case BattlerAbilityId.nucleoParasitario:
        return nucleoParasitarioAbility;
      case BattlerAbilityId.espejoDolor:
        return espejoDolorAbility;
      case BattlerAbilityId.protocoloUsurpacion:
        return protocoloUsurpacionAbility;
      case BattlerAbilityId.refactorizacionTimeline:
        return refactorizacionTimelineAbility;
    }
  }

  /// Ajusta la rareza visual de habilidades legacy segun sus mejoras ya guardadas.
  BattlerAbility normalizeUpgradeTier() {
    final preset = presetForId(id);
    final inferredRarity = preset.rarity.advanceBy(upgradeCount);
    if (rarity.index >= inferredRarity.index) return this;

    return copyWith(rarity: inferredRarity);
  }
}

/// Preset que prepara un siguiente ataque potenciado y luego entra en cooldown.
const criticalScannerAbility = BattlerAbility(
  id: BattlerAbilityId.criticalScanner,
  rarity: RarityTier.blue,
  tags: _ataqueAbilityTags,
  name: 'Escaner critico',
  description:
      'Activacion manual en combate. El siguiente ataque inflige dano adicional igual a su value.',
  icon: Icons.radar_rounded,
  cooldownTurns: 3,
  value: 3,
  upgradeValue: 2,
  manualActivationContext: BattlerAbilityActivationContext.battle,
  effect: CriticalScannerAbilityEffect(),
  isImplemented: true,
);

/// Preset pasivo que castiga a los enemigos que ya tienen algun debuff.
const weaknessHunterAbility = BattlerAbility(
  id: BattlerAbilityId.weaknessHunter,
  tags: _ataqueDebuffAbilityTags,
  name: 'Caza de debilidades',
  description:
      'Pasiva. Tus ataques infligen dano adicional si el objetivo ya tiene al menos un debuff.',
  icon: Icons.track_changes_rounded,
  value: 2,
  upgradeValue: 2,
  effect: WeaknessHunterAbilityEffect(),
  isImplemented: true,
);

/// Preset pasivo defensivo que protege mientras la vida siga llena.
const ghostMeshAbility = BattlerAbility(
  id: BattlerAbilityId.ghostMesh,
  tags: _vidaBarreraAbilityTags,
  name: 'Malla Fantasma',
  description:
      'Pasiva. Si tu vida esta al maximo, el dano recibido por ataques se reduce a la mitad, redondeando hacia arriba.',
  icon: Icons.security_rounded,
  value: 2,
  effect: GhostMeshAbilityEffect(),
  isImplemented: true,
);

/// Preset manual que duplica la siguiente desventaja recibida por el objetivo.
const cruelCatalysisAbility = BattlerAbility(
  id: BattlerAbilityId.cruelCatalysis,
  rarity: RarityTier.yellow,
  tags: _debuffAbilityTags,
  name: 'Catalisis Cruel',
  description:
      'Activacion manual en combate. Aplica al enemigo un debuff que duplica el valor de la siguiente desventaja que reciba.',
  icon: Icons.biotech_rounded,
  cooldownTurns: 2,
  value: 2,
  manualActivationContext: BattlerAbilityActivationContext.battle,
  effect: CruelCatalysisAbilityEffect(),
  isImplemented: true,
);

/// Preset manual que potencia un golpe y aplica Quemadura al propio usuario.
const venousOverloadAbility = BattlerAbility(
  id: BattlerAbilityId.venousOverload,
  tags: _ataqueQuemaduraAbilityTags,
  name: 'Sobrecarga venosa',
  description:
      'Activacion manual en combate. El siguiente ataque inflige dano adicional igual a su value, pero te aplica Quemadura por value/2 turnos.',
  icon: Icons.flash_on_rounded,
  value: 4,
  upgradeValue: 2,
  manualActivationContext: BattlerAbilityActivationContext.battle,
  effect: VenousOverloadAbilityEffect(),
  isImplemented: true,
);

/// Preset manual de ruta que purga debuffs purgables a cambio de vida.
const hardResetAbility = BattlerAbility(
  id: BattlerAbilityId.hardReset,
  tags: _vidaDebuffAbilityTags,
  name: 'Reinicio en seco',
  description:
      'Activacion manual en ruta. Elimina debuffs propios y luego te inflige dano igual al 10% de tu vida maxima por cada punto de value.',
  icon: Icons.refresh_rounded,
  value: 1,
  upgradeValue: 1,
  manualActivationContext: BattlerAbilityActivationContext.pathSelection,
  effect: HardResetAbilityEffect(),
  isImplemented: true,
);

/// Preset pasivo economico que entrega creditos al comienzo de cada hora.
const cashflowAbility = BattlerAbility(
  id: BattlerAbilityId.cashflow,
  rarity: RarityTier.green,
  tags: _economiaAbilityTags,
  name: 'Flujo de Caja',
  description:
      'Pasiva. Al comienzo de cada hora, ganas creditos iguales a tu income actual.',
  icon: Icons.payments_rounded,
  value: 1,
  effect: CashflowAbilityEffect(),
  isImplemented: true,
);

/// Preset pasivo de barrera minima al inicio de cada turno propio.
const pulsoRepLAbility = BattlerAbility(
  id: BattlerAbilityId.pulsoRepL,
  rarity: RarityTier.green,
  tags: _buffBarreraAbilityTags,
  name: 'Pulso REP-L',
  description:
      'Pasiva. Al inicio de tu turno, si tienes menos barrera que value, subes tu barrera hasta value.',
  icon: Icons.shield_rounded,
  value: 4,
  upgradeValue: 2,
  effect: PulsoRepLAbilityEffect(),
  isImplemented: true,
);

/// Preset manual de combate que roba barrera tras el siguiente ataque.
const sustraccionAbility = BattlerAbility(
  id: BattlerAbilityId.sustraccion,
  tags: _ataqueBarreraAbilityTags,
  name: 'Sustraccion',
  description:
      'Activacion manual en combate. Tras el siguiente ataque, absorbes hasta value de barrera del objetivo.',
  icon: Icons.swap_horiz_rounded,
  cooldownTurns: 3,
  value: 4,
  upgradeValue: 2,
  manualActivationContext: BattlerAbilityActivationContext.battle,
  effect: SustraccionAbilityEffect(),
  isImplemented: true,
);

/// Preset manual de combate que elimina turnos de buffs enemigos.
const limpiezaCacheAbility = BattlerAbility(
  id: BattlerAbilityId.limpiezaCache,
  tags: _debuffAbilityTags,
  name: 'Limpieza de Cache',
  description:
      'Activacion manual en combate. Elimina 1 turno de un buff enemigo aleatorio, value veces.',
  icon: Icons.cleaning_services_rounded,
  cooldownTurns: 2,
  value: 1,
  upgradeValue: 1,
  manualActivationContext: BattlerAbilityActivationContext.battle,
  effect: LimpiezaCacheAbilityEffect(),
  isImplemented: true,
);

/// Preset pasivo amarillo que convierte debuffs enemigos en curacion.
const hemostasiaAgresivaAbility = BattlerAbility(
  id: BattlerAbilityId.hemostasiaAgresiva,
  rarity: RarityTier.yellow,
  tags: _vidaAtaqueAbilityTags,
  name: 'Hemostasia Agresiva',
  description:
      'Pasiva. Al golpear a un objetivo con debuff, te curas value de vida.',
  icon: Icons.favorite_rounded,
  value: 5,
  upgradeValue: 0,
  effect: HemostasiaAgresivaAbilityEffect(),
  isImplemented: true,
);

/// Preset pasivo morado que refleja dano del primer impacto de cada turno.
const mallaReboteAbility = BattlerAbility(
  id: BattlerAbilityId.mallaRebote,
  rarity: RarityTier.purple,
  tags: _buffBarreraAbilityTags,
  name: 'Malla de Rebote',
  description:
      'Pasiva. El primer ataque que recibes cada turno devuelve value de dano al atacante.',
  icon: Icons.sync_alt_rounded,
  value: 4,
  upgradeValue: 4,
  effect: MallaReboteAbilityEffect(),
  isImplemented: true,
);

/// Preset manual de combate centrado en Intoxicacion acumulativa.
const inyeccionCorrosivaAbility = BattlerAbility(
  id: BattlerAbilityId.inyeccionCorrosiva,
  rarity: RarityTier.green,
  tags: _intoxicacionDebuffAbilityTags,
  name: 'Inyeccion Corrosiva',
  description:
      'Activacion manual en combate. Aplica Intoxicacion con value de potencia al objetivo, o aumenta en value si el objetivo ya tiene Intoxicacion.',
  icon: Icons.science_rounded,
  cooldownTurns: 2,
  value: 2,
  upgradeValue: 1,
  manualActivationContext: BattlerAbilityActivationContext.battle,
  effect: InyeccionCorrosivaAbilityEffect(),
  isImplemented: true,
);

/// Preset pasivo que explota buffs activos del enemigo para infligir dano extra.
const escanerRupturaAbility = BattlerAbility(
  id: BattlerAbilityId.escanerRuptura,
  rarity: RarityTier.blue,
  tags: _buffAtaqueAbilityTags,
  name: 'Escaner de Ruptura',
  description:
      'Pasiva. Tus ataques infligen +value dano si el objetivo tiene al menos un buff.',
  icon: Icons.radar_rounded,
  value: 3,
  upgradeValue: 2,
  effect: EscanerRupturaAbilityEffect(),
  isImplemented: true,
);

/// Preset manual que traslada debuffs propios al rival.
const reenrutadoInversoAbility = BattlerAbility(
  id: BattlerAbilityId.reenrutadoInverso,
  rarity: RarityTier.blue,
  tags: _debuffAbilityTags,
  name: 'Reenrutado Inverso',
  description:
      'Activacion manual en combate. Transfiere 1 turno de un debuff aleatorio tuyo al enemigo, value veces.',
  icon: Icons.alt_route_rounded,
  cooldownTurns: 3,
  value: 2,
  upgradeValue: 1,
  manualActivationContext: BattlerAbilityActivationContext.battle,
  effect: ReenrutadoInversoAbilityEffect(),
  isImplemented: true,
);

/// Preset manual de control que fuerza cooldown sobre habilidades manuales rivales.
const jaulaSenalAbility = BattlerAbility(
  id: BattlerAbilityId.jaulaSenal,
  rarity: RarityTier.blue,
  tags: _debuffAbilityTags,
  name: 'Jaula de Senal',
  description:
      'Activacion manual en combate. Una habilidad manual del enemigo se desactiva y gana +value turnos de cooldown.',
  icon: Icons.wifi_lock_rounded,
  cooldownTurns: 3,
  value: 1,
  upgradeValue: 1,
  manualActivationContext: BattlerAbilityActivationContext.battle,
  effect: JaulaSenalAbilityEffect(),
  isImplemented: true,
);

/// Preset pasivo que drena vida en el primer ataque de cada turno propio.
const nucleoParasitarioAbility = BattlerAbility(
  id: BattlerAbilityId.nucleoParasitario,
  rarity: RarityTier.purple,
  tags: _vidaAtaqueAbilityTags,
  name: 'Nucleo Parasitario',
  description:
      'Pasiva. En el primer ataque durante tu turno, drenas value de vida al objetivo.',
  icon: Icons.bloodtype_rounded,
  value: 4,
  upgradeValue: 1,
  effect: NucleoParasitarioAbilityEffect(),
  isImplemented: true,
);

/// Preset manual morado defensivo con contraataque reflejado.
const espejoDolorAbility = BattlerAbility(
  id: BattlerAbilityId.espejoDolor,
  rarity: RarityTier.purple,
  tags: _vidaBarreraAbilityTags,
  name: 'Espejo de Dolor',
  description:
      'Activacion manual en combate. El siguiente ataque recibido reduce su dano en value y refleja el dano prevenido + value.',
  icon: Icons.health_and_safety_rounded,
  cooldownTurns: 3,
  value: 4,
  upgradeValue: 2,
  manualActivationContext: BattlerAbilityActivationContext.battle,
  effect: EspejoDolorAbilityEffect(),
  isImplemented: true,
);

/// Preset manual verde que roba buffs activos del rival.
const protocoloUsurpacionAbility = BattlerAbility(
  id: BattlerAbilityId.protocoloUsurpacion,
  rarity: RarityTier.green,
  tags: _buffDebuffAbilityTags,
  name: 'Protocolo de Usurpacion',
  description:
      'Activacion manual en combate. Robas hasta value buffs activos del enemigo y te los aplicas.',
  icon: Icons.call_split_rounded,
  cooldownTurns: 4,
  value: 2,
  upgradeValue: 1,
  manualActivationContext: BattlerAbilityActivationContext.battle,
  effect: ProtocoloUsurpacionAbilityEffect(),
  isImplemented: true,
);

/// Preset manual de ruta que paga creditos para rerolear nodos visibles.
const refactorizacionTimelineAbility = BattlerAbility(
  id: BattlerAbilityId.refactorizacionTimeline,
  rarity: RarityTier.green,
  tags: _economiaAbilityTags,
  name: 'Refactorizacion de Timeline',
  description:
      'Activacion manual en ruta. A cambio de value creditos, cambias todos los nodos visibles por otros distintos.',
  icon: Icons.timeline_rounded,
  cooldownTurns: 4,
  value: 20,
  upgradeValue: -3,
  manualActivationContext: BattlerAbilityActivationContext.pathSelection,
  effect: RefactorizacionTimelineAbilityEffect(),
  isImplemented: true,
);

/// Pool canonica de habilidades que pueden usarse como recompensa o mutacion.
const abilityPresets = <BattlerAbility>[
  criticalScannerAbility,
  weaknessHunterAbility,
  ghostMeshAbility,
  cruelCatalysisAbility,
  venousOverloadAbility,
  hardResetAbility,
  cashflowAbility,
  pulsoRepLAbility,
  sustraccionAbility,
  limpiezaCacheAbility,
  hemostasiaAgresivaAbility,
  mallaReboteAbility,
  inyeccionCorrosivaAbility,
  escanerRupturaAbility,
  reenrutadoInversoAbility,
  jaulaSenalAbility,
  nucleoParasitarioAbility,
  espejoDolorAbility,
  protocoloUsurpacionAbility,
  refactorizacionTimelineAbility,
];
