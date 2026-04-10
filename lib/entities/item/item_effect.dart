import '../_imports.dart';

/// Agrupa el estado final del portador y del rival tras resolver un efecto de item.
class ItemEffectResolution {
  final Battler owner;
  final Battler opponent;

  /// Crea una resolucion inmutable con ambos combatientes ya actualizados.
  const ItemEffectResolution({
    required this.owner,
    required this.opponent,
  });
}

/// Enumera los momentos en los que un item puede reaccionar a una habilidad.
enum ItemAbilityResolutionContext {
  manualActivation,
  attackResolved,
  receiveDamageResolved,
  turnStart,
  turnEnd,
}

/// Enumera los puntos del ciclo de combate en los que un item equipado puede intervenir.
enum ItemEffectHook {
  turnStart,
  turnEnd,
  combatEnd,
  outgoingDamageModifier,
  incomingDamageModifier,
  calculatedStatModifier,
  basicAttackCountModifier,
  attackResolved,
  receiveDamageResolved,
  passive,
  manualAbilityPreparation,
  abilityResolved,
  outgoingStatusModifier,
  incomingStatusModifier,
  fatalDamage,
}

/// Devuelve el estado resultante cuando un item modifica una activacion manual.
class ItemAbilityPreparationResolution {
  final Battler owner;
  final Battler opponent;
  final BattlerAbility ability;

  /// Crea una resolucion con el usuario, el rival y la habilidad ya ajustados.
  const ItemAbilityPreparationResolution({
    required this.owner,
    required this.opponent,
    required this.ability,
  });
}

/// Sirve como base comun para todos los hooks reactivos de los objetos equipados.
abstract class ItemEffect {
  final String description;
  final Set<ItemEffectHook> hooks;

  /// Crea un efecto reutilizable con la descripcion base del item.
  const ItemEffect({
    required this.description,
    this.hooks = const <ItemEffectHook>{},
  });

  /// Devuelve la descripcion mostrada por la UI, pudiendo usar el value del item.
  String descriptionFor(Item item) => description;

  /// Resuelve el efecto del item al inicio de turno.
  ItemEffectResolution onTurnStart({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required bool isOwnerTurn,
  }) {
    return ItemEffectResolution(owner: owner, opponent: opponent);
  }

  /// Resuelve el efecto del item al final de turno.
  ItemEffectResolution onTurnEnd({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required bool isOwnerTurn,
  }) {
    return ItemEffectResolution(owner: owner, opponent: opponent);
  }

  /// Resuelve efectos puntuales al terminar el combate antes de limpiar flags y cooldowns.
  Battler onCombatEnd({
    required Battler owner,
    required Item item,
  }) {
    return owner;
  }

  /// Ajusta el dano saliente del portador antes de que se aplique.
  int modifyOutgoingDamage({
    required Battler owner,
    required Battler target,
    required Item item,
    required int damage,
  }) {
    return damage;
  }

  /// Ajusta el dano entrante del portador antes de que se aplique.
  int modifyIncomingDamage({
    required Battler owner,
    required Battler source,
    required Item item,
    required int damage,
  }) {
    return damage;
  }

  /// Ajusta una stat ya calculada del portador para efectos persistentes de equipo.
  int modifyCalculatedStat({
    required Battler owner,
    required Item item,
    required BattlerStat stat,
    required int value,
  }) {
    return value;
  }

  /// Ajusta cuantas veces se resuelve una accion de ataque basico.
  int modifyBasicAttackCount({
    required Battler owner,
    required Item item,
    required int count,
  }) {
    return count;
  }

  /// Resuelve efectos posteriores a que el portador termine un ataque.
  ItemEffectResolution onAttackResolved({
    required Battler owner,
    required Battler target,
    required Item item,
    required int damageDealt,
  }) {
    return ItemEffectResolution(owner: owner, opponent: target);
  }

  /// Resuelve efectos posteriores a que el portador reciba dano.
  ItemEffectResolution onReceiveDamageResolved({
    required Battler owner,
    required Battler source,
    required Item item,
    required int damageTaken,
  }) {
    return ItemEffectResolution(owner: owner, opponent: source);
  }

  /// Aplica efectos pasivos que deben reevaluarse sin un disparador puntual.
  ItemEffectResolution applyPassive({
    required Battler owner,
    required Battler opponent,
    required Item item,
  }) {
    return ItemEffectResolution(owner: owner, opponent: opponent);
  }

  /// Permite modificar una habilidad justo antes de su activacion manual real.
  ItemAbilityPreparationResolution onManualAbilityPreparing({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required BattlerAbility ability,
    required BattlerAbilityActivationContext screenContext,
  }) {
    return ItemAbilityPreparationResolution(
      owner: owner,
      opponent: opponent,
      ability: ability,
    );
  }

  /// Reacciona a una habilidad ya resuelta para aplicar efectos posteriores.
  ItemEffectResolution onAbilityResolved({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required BattlerAbility previousAbility,
    required BattlerAbility resolvedAbility,
    required ItemAbilityResolutionContext context,
  }) {
    return ItemEffectResolution(owner: owner, opponent: opponent);
  }

  /// Permite alterar o cancelar un estado antes de aplicarlo al objetivo.
  BattlerStatus? modifyOutgoingStatus({
    required Battler owner,
    required Battler target,
    required Item item,
    required BattlerStatus status,
  }) {
    return status;
  }

  /// Permite alterar o cancelar un estado recibido antes de que se aplique.
  BattlerStatus? modifyIncomingStatus({
    required Battler owner,
    required Battler source,
    required Item item,
    required BattlerStatus status,
  }) {
    return status;
  }

  /// Permite interceptar un golpe letal justo antes de que el portador muera.
  Battler onReceiveFatalDamage({
    required Battler owner,
    required Item item,
    required int incomingDamage,
  }) {
    return owner;
  }
}

/// Convierte el ataque basico en un doble golpe a cambio de reducir el ATK total.
class SunglassesItemEffect extends ItemEffect {
  /// Crea un efecto reutilizable para las Gafas de Sol.
  const SunglassesItemEffect()
      : super(
          description:
              'Tu ATK total se reduce a la mitad, redondeado hacia arriba y con minimo 1. A cambio, cada accion de ataque basico se resuelve dos veces.',
          hooks: const {
            ItemEffectHook.calculatedStatModifier,
            ItemEffectHook.basicAttackCountModifier,
          },
        );

  @override

  /// Reduce el ATK final del portador para equilibrar el doble golpe.
  int modifyCalculatedStat({
    required Battler owner,
    required Item item,
    required BattlerStat stat,
    required int value,
  }) {
    if (stat != BattlerStat.attack) return value;

    return max(1, (value + 1) ~/ 2);
  }

  @override

  /// Anade un ataque extra a cada accion de ataque basico.
  int modifyBasicAttackCount({
    required Battler owner,
    required Item item,
    required int count,
  }) {
    return count + 1;
  }
}

/// Aplica Intoxicacion al objetivo o refuerza la que ya tenga.
class IntoxicarOnAttackItemEffect extends ItemEffect {
  final int amount;

  /// Crea un efecto reutilizable que intoxica al golpear.
  const IntoxicarOnAttackItemEffect({
    this.amount = 1,
  }) : super(
          description:
              'Al atacar: intoxica el enemigo en 1, o aumenta su valor de Intoxicacion en 1.',
          hooks: const {
            ItemEffectHook.attackResolved,
          },
        );

  @override

  /// Genera la descripcion final usando el valor actual del objeto equipado.
  String descriptionFor(Item item) {
    final resolvedAmount = max(1, item.value > 0 ? item.value : amount);
    return 'Al atacar: aplica o aumenta Intoxicacion en $resolvedAmount.';
  }

  @override

  /// Tras atacar, suma Intoxicacion existente o crea una nueva instancia.
  ItemEffectResolution onAttackResolved({
    required Battler owner,
    required Battler target,
    required Item item,
    required int damageDealt,
  }) {
    final resolvedAmount = max(1, item.value > 0 ? item.value : amount);
    final currentPoison = target.statusById(IntoxicacionStatus.statusId);
    final updatedTarget = currentPoison is IntoxicacionStatus
        ? target.applyStatus(
            currentPoison.copyWith(
              value: currentPoison.value + resolvedAmount,
            ),
            source: owner,
          )
        : target.applyStatus(
            IntoxicacionStatus(value: resolvedAmount),
            source: owner,
          );

    return ItemEffectResolution(
      owner: owner,
      opponent: updatedTarget,
    );
  }
}

/// Cura al portador al inicio de cada turno propio mientras siga equipado.
class RegenerativeShieldItemEffect extends ItemEffect {
  /// Crea un efecto reutilizable para escudos con regeneracion pasiva.
  const RegenerativeShieldItemEffect()
      : super(
          description:
              'Al inicio de tu turno, te curas una cantidad fija de vida.',
          hooks: const {
            ItemEffectHook.turnStart,
          },
        );

  @override

  /// Genera la descripcion final usando el value real del item equipado.
  String descriptionFor(Item item) {
    return 'Al inicio de tu turno, recuperas ${item.value} HP.';
  }

  @override

  /// Cura al portador al comenzar su propio turno.
  ItemEffectResolution onTurnStart({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required bool isOwnerTurn,
  }) {
    if (!isOwnerTurn) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    return ItemEffectResolution(
      owner: owner.heal(item.value),
      opponent: opponent,
    );
  }
}

/// Recupera barrera al inicio del turno propio con una cantidad fija.
class RecoverBarrierOnTurnStartItemEffect extends ItemEffect {
  final int amount;

  /// Crea un efecto reutilizable para objetos que regeneran barrera de combate.
  const RecoverBarrierOnTurnStartItemEffect({
    required this.amount,
  }) : super(
          description:
              'Al inicio de tu turno, recuperas una cantidad fija de barrera.',
          hooks: const {
            ItemEffectHook.turnStart,
          },
        );

  @override

  /// Genera la descripcion final usando la cantidad configurada para este item.
  String descriptionFor(Item item) {
    return 'Al inicio de tu turno, recuperas $amount de Barrera.';
  }

  @override

  /// Restaura barrera sin sobrepasar la barrera maxima calculada del portador.
  ItemEffectResolution onTurnStart({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required bool isOwnerTurn,
  }) {
    if (!isOwnerTurn) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    return ItemEffectResolution(
      owner: owner.copyWith(
        currentBarrier: min(
          owner.maxBarrier,
          owner.currentBarrier + amount,
        ),
      ),
      opponent: opponent,
    );
  }
}

/// Cura un poco al portador cuando deja al objetivo en rango de remate.
class RescueBladeItemEffect extends ItemEffect {
  /// Crea el efecto propio de la Cuchilla de Rescate.
  const RescueBladeItemEffect()
      : super(
          description:
              'Si el objetivo queda al 50% de HP o menos, recuperas vida.',
          hooks: const {
            ItemEffectHook.attackResolved,
          },
        );

  @override
  String descriptionFor(Item item) {
    return 'Al atacar, si el objetivo queda al 50% de HP o menos, recuperas ${item.value} HP.';
  }

  @override
  ItemEffectResolution onAttackResolved({
    required Battler owner,
    required Battler target,
    required Item item,
    required int damageDealt,
  }) {
    if (target.maxHealth <= 0 || target.health * 2 > target.maxHealth) {
      return ItemEffectResolution(owner: owner, opponent: target);
    }

    return ItemEffectResolution(
      owner: owner.heal(item.value),
      opponent: target,
    );
  }
}

/// Castiga al agresor si el portador consigue mantener parte de su barrera.
class ShockMeshItemEffect extends ItemEffect {
  /// Crea el efecto propio de la Malla de Choque.
  const ShockMeshItemEffect()
      : super(
          description:
              'Al recibir dano mientras sigues teniendo barrera, aplicas Conmocion al agresor.',
          hooks: const {
            ItemEffectHook.receiveDamageResolved,
          },
        );

  @override
  String descriptionFor(Item item) {
    return 'Al recibir dano mientras conservas Barrera, aplicas Conmocion (-${item.value} dano) al agresor.';
  }

  @override
  ItemEffectResolution onReceiveDamageResolved({
    required Battler owner,
    required Battler source,
    required Item item,
    required int damageTaken,
  }) {
    if (damageTaken <= 0 || owner.currentBarrier <= 0) {
      return ItemEffectResolution(owner: owner, opponent: source);
    }

    return ItemEffectResolution(
      owner: owner,
      opponent: source.applyStatus(
        ConmocionStatus(value: max(1, item.value)),
        source: owner,
      ),
    );
  }
}

/// Mezcla veneno y remate ligero cuando el objetivo ya esta intoxicado.
class ToxicScalpelItemEffect extends ItemEffect {
  /// Crea el efecto propio del Bisturi Toxico.
  const ToxicScalpelItemEffect()
      : super(
          description:
              'Al atacar aplica Intoxicacion y castiga extra a objetivos ya intoxicados.',
          hooks: const {
            ItemEffectHook.attackResolved,
          },
        );

  @override
  String descriptionFor(Item item) {
    final resolvedAmount = max(1, item.value);
    return 'Al atacar: aplica o aumenta Intoxicacion en $resolvedAmount. Si el objetivo ya estaba intoxicado, infliges $resolvedAmount dano directo extra.';
  }

  @override
  ItemEffectResolution onAttackResolved({
    required Battler owner,
    required Battler target,
    required Item item,
    required int damageDealt,
  }) {
    final resolvedAmount = max(1, item.value);
    final currentPoison = target.statusById(IntoxicacionStatus.statusId);
    final hadPoison = currentPoison is IntoxicacionStatus;

    var updatedTarget = hadPoison
        ? target.applyStatus(
            currentPoison.copyWith(
              value: currentPoison.value + resolvedAmount,
            ),
            source: owner,
          )
        : target.applyStatus(
            IntoxicacionStatus(value: resolvedAmount),
            source: owner,
          );

    if (hadPoison) {
      updatedTarget = updatedTarget.receiveDirectDamage(
        resolvedAmount,
        source: owner,
      );
    }

    return ItemEffectResolution(
      owner: owner,
      opponent: updatedTarget,
    );
  }
}

/// Convierte el turno sin barrera en un blindaje temporal minimo.
class DeflectiveCapacitorItemEffect extends ItemEffect {
  /// Crea el efecto propio del Condensador Deflectivo.
  const DeflectiveCapacitorItemEffect()
      : super(
          description:
              'Si empiezas tu turno sin barrera, recuperas Blindaje Temporal.',
          hooks: const {
            ItemEffectHook.turnStart,
          },
        );

  @override
  String descriptionFor(Item item) {
    return 'Al inicio de tu turno, si estas a 0 de Barrera, recuperas Blindaje Temporal (${max(1, item.value)} de absorcion).';
  }

  @override
  ItemEffectResolution onTurnStart({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required bool isOwnerTurn,
  }) {
    if (!isOwnerTurn || owner.currentBarrier > 0) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    return ItemEffectResolution(
      owner: _refreshMinimumBlindajeTemporal(
        owner: owner,
        value: item.value,
      ),
      opponent: opponent,
    );
  }
}

/// Aplica interferencia y erosiona barrera si el objetivo ya estaba bloqueado.
class InterferenceCannonItemEffect extends ItemEffect {
  /// Crea el efecto propio del Canon de Interferencia.
  const InterferenceCannonItemEffect()
      : super(
          description:
              'Al atacar aplica Interferencia y castiga barreras ya comprometidas.',
          hooks: const {
            ItemEffectHook.attackResolved,
          },
        );

  @override
  String descriptionFor(Item item) {
    return 'Al atacar: aplica Interferencia durante ${max(1, item.value)} turnos. Si el objetivo ya la tenia, ademas pierde 1 de Barrera.';
  }

  @override
  ItemEffectResolution onAttackResolved({
    required Battler owner,
    required Battler target,
    required Item item,
    required int damageDealt,
  }) {
    final resolvedDuration = max(1, item.value);
    final hadInterference = target.hasStatus(InterferenciaStatus.statusId);
    var updatedTarget = target.applyStatus(
      InterferenciaStatus(remainingTurns: resolvedDuration),
      source: owner,
    );

    if (hadInterference && updatedTarget.currentBarrier > 0) {
      updatedTarget = updatedTarget.copyWith(
        currentBarrier: max(0, updatedTarget.currentBarrier - 1),
      );
    }

    return ItemEffectResolution(
      owner: owner,
      opponent: updatedTarget,
    );
  }
}

/// Premia los turnos en los que el portador sale ileso.
class ResponseFrameItemEffect extends ItemEffect {
  /// Crea el efecto propio del Bastidor de Respuesta.
  const ResponseFrameItemEffect()
      : super(
          description:
              'Si no recibes dano durante tu turno, recuperas barrera al final.',
          hooks: const {
            ItemEffectHook.turnStart,
            ItemEffectHook.turnEnd,
            ItemEffectHook.receiveDamageResolved,
          },
        );

  @override
  String descriptionFor(Item item) {
    return 'Al final de tu turno, si no has recibido dano, recuperas ${max(1, item.value)} de Barrera.';
  }

  @override
  ItemEffectResolution onTurnStart({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required bool isOwnerTurn,
  }) {
    if (!isOwnerTurn) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    final damagedFlag = _itemCombatFlag(
      item,
      ItemCombatFlagKind.responseFrameDamagedThisTurn,
    );
    return ItemEffectResolution(
      owner: owner.removeCombatFlag(damagedFlag),
      opponent: opponent,
    );
  }

  @override
  ItemEffectResolution onReceiveDamageResolved({
    required Battler owner,
    required Battler source,
    required Item item,
    required int damageTaken,
  }) {
    if (damageTaken <= 0) {
      return ItemEffectResolution(owner: owner, opponent: source);
    }

    final damagedFlag = _itemCombatFlag(
      item,
      ItemCombatFlagKind.responseFrameDamagedThisTurn,
    );
    return ItemEffectResolution(
      owner: owner.addCombatFlag(damagedFlag),
      opponent: source,
    );
  }

  @override
  ItemEffectResolution onTurnEnd({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required bool isOwnerTurn,
  }) {
    if (!isOwnerTurn) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    final damagedFlag = _itemCombatFlag(
      item,
      ItemCombatFlagKind.responseFrameDamagedThisTurn,
    );
    if (owner.hasCombatFlag(damagedFlag)) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    return ItemEffectResolution(
      owner: _recoverBarrier(
        owner: owner,
        amount: item.value,
      ),
      opponent: opponent,
    );
  }
}

/// Convierte una ofensiva sobrecalentada en aguante extra.
class OverloadAnchorItemEffect extends ItemEffect {
  /// Crea el efecto propio del Ancla de Sobrecarga.
  const OverloadAnchorItemEffect()
      : super(
          description:
              'Al final de tu turno, si tienes Calentando, recuperas barrera.',
          hooks: const {
            ItemEffectHook.turnEnd,
          },
        );

  @override
  String descriptionFor(Item item) {
    return 'Al final de tu turno, si tienes Calentando, recuperas ${max(1, item.value)} de Barrera.';
  }

  @override
  ItemEffectResolution onTurnEnd({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required bool isOwnerTurn,
  }) {
    if (!isOwnerTurn || !owner.hasStatus(CalentandoStatus.statusId)) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    return ItemEffectResolution(
      owner: _recoverBarrier(
        owner: owner,
        amount: item.value,
      ),
      opponent: opponent,
    );
  }
}

/// Solo castiga el primer golpe recibido en cada turno propio.
class ReboundLensItemEffect extends ItemEffect {
  /// Crea el efecto propio de la Lente de Rebote.
  const ReboundLensItemEffect()
      : super(
          description:
              'La primera vez que recibes dano cada turno, aplicas Fragilidad al agresor.',
          hooks: const {
            ItemEffectHook.turnStart,
            ItemEffectHook.receiveDamageResolved,
          },
        );

  @override
  String descriptionFor(Item item) {
    return 'La primera vez que recibes dano cada turno, aplicas Fragilidad (+${max(1, item.value)} dano recibido en el siguiente ataque) al agresor.';
  }

  @override
  ItemEffectResolution onTurnStart({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required bool isOwnerTurn,
  }) {
    if (!isOwnerTurn) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    final triggeredFlag = _itemCombatFlag(
      item,
      ItemCombatFlagKind.reboundLensTriggeredThisTurn,
    );
    return ItemEffectResolution(
      owner: owner.removeCombatFlag(triggeredFlag),
      opponent: opponent,
    );
  }

  @override
  ItemEffectResolution onReceiveDamageResolved({
    required Battler owner,
    required Battler source,
    required Item item,
    required int damageTaken,
  }) {
    if (damageTaken <= 0) {
      return ItemEffectResolution(owner: owner, opponent: source);
    }

    final triggeredFlag = _itemCombatFlag(
      item,
      ItemCombatFlagKind.reboundLensTriggeredThisTurn,
    );
    if (owner.hasCombatFlag(triggeredFlag)) {
      return ItemEffectResolution(owner: owner, opponent: source);
    }

    return ItemEffectResolution(
      owner: owner.addCombatFlag(triggeredFlag),
      opponent: source.applyStatus(
        FragilidadStatus(remainingTurns: max(1, item.value)),
        source: owner,
      ),
    );
  }
}

/// Duplica el motor de Inercia generando ambas reservas al arrancar turno.
class InertiaCrownItemEffect extends ItemEffect {
  /// Crea el efecto propio de la Corona de Inercia.
  const InertiaCrownItemEffect()
      : super(
          description:
              'Si tienes Inercia al inicio del turno, ganas ambas reservas.',
          hooks: const {
            ItemEffectHook.turnStart,
          },
        );

  @override
  String descriptionFor(Item item) {
    return 'Al inicio de tu turno, si tienes Inercia, ganas Reserva de Inercia: ATK (+${max(1, item.value)}) y Reserva de Inercia: Barrera (+${max(1, item.value)}).';
  }

  @override
  ItemEffectResolution onTurnStart({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required bool isOwnerTurn,
  }) {
    if (!isOwnerTurn || !owner.hasStatus(InerciaStatus.statusId)) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    final resolvedValue = max(1, item.value);
    final ownerWithAttackReserve = owner.applyStatus(
      InerciaAtaqueStatus(value: resolvedValue),
      source: owner,
    );
    return ItemEffectResolution(
      owner: ownerWithAttackReserve.applyStatus(
        InerciaBarreraStatus(value: resolvedValue),
        source: ownerWithAttackReserve,
      ),
      opponent: opponent,
    );
  }
}

/// Consume Quemadura para convertirla en dano directo inmediato.
class SunExecutionBladeItemEffect extends ItemEffect {
  /// Crea el efecto propio de la Hoja de Ejecucion Solar.
  const SunExecutionBladeItemEffect()
      : super(
          description:
              'Consume la Quemadura del objetivo para infligir dano directo extra.',
          hooks: const {
            ItemEffectHook.attackResolved,
          },
        );

  @override
  String descriptionFor(Item item) {
    return 'Si el objetivo tiene Quemadura, la consume e inflige dano directo extra igual a su dano actual total + ${max(1, item.value)}.';
  }

  @override
  ItemEffectResolution onAttackResolved({
    required Battler owner,
    required Battler target,
    required Item item,
    required int damageDealt,
  }) {
    final burnStatuses = target
        .statusesById(QuemaduraStatus.statusId)
        .whereType<QuemaduraStatus>()
        .toList(growable: false);
    if (burnStatuses.isEmpty) {
      return ItemEffectResolution(owner: owner, opponent: target);
    }

    final totalBurnDamage = burnStatuses.fold<int>(
      0,
      (sum, status) => sum + status.currentDamage(target),
    );
    final updatedTarget =
        target.removeStatus(QuemaduraStatus.statusId).receiveDirectDamage(
              totalBurnDamage + max(1, item.value),
              source: owner,
            );

    return ItemEffectResolution(
      owner: owner,
      opponent: updatedTarget,
    );
  }
}

/// Aplica Quemadura al objetivo cada vez que el portador conecta un ataque.
class QuemaduraOnAttackItemEffect extends ItemEffect {
  final int duration;

  /// Crea un efecto reutilizable que anade Quemadura al atacar.
  const QuemaduraOnAttackItemEffect({
    this.duration = QuemaduraStatus.defaultDuration,
  }) : super(
          description:
              'Al atacar: anade un efecto de Quemadura de 3 turnos de duracion.',
          hooks: const {
            ItemEffectHook.attackResolved,
          },
        );

  @override

  /// Genera la descripcion final usando la duracion actual del objeto equipado.
  String descriptionFor(Item item) {
    final resolvedDuration = max(1, item.value > 0 ? item.value : duration);
    return 'Al atacar: anade Quemadura durante $resolvedDuration turnos.';
  }

  @override

  /// Tras atacar, aplica una Quemadura nueva con la duracion configurada.
  ItemEffectResolution onAttackResolved({
    required Battler owner,
    required Battler target,
    required Item item,
    required int damageDealt,
  }) {
    final resolvedDuration = max(1, item.value > 0 ? item.value : duration);
    return ItemEffectResolution(
      owner: owner,
      opponent: target.applyStatus(
        QuemaduraStatus(remainingTurns: resolvedDuration),
        source: owner,
      ),
    );
  }
}

/// Devuelve Quemadura al atacante cuando el portador recibe un golpe.
class QuemaduraOnHitReceivedItemEffect extends ItemEffect {
  final int duration;

  /// Crea un efecto reutilizable que castiga al rival al recibir dano.
  const QuemaduraOnHitReceivedItemEffect({
    this.duration = 4,
  }) : super(
          description:
              'Al recibir un ataque: anade un efecto de Quemadura de 4 turnos de duracion.',
          hooks: const {
            ItemEffectHook.receiveDamageResolved,
          },
        );

  @override

  /// Genera la descripcion final usando la duracion actual del objeto equipado.
  String descriptionFor(Item item) {
    final resolvedDuration = max(1, item.value > 0 ? item.value : duration);
    return 'Al recibir un ataque: anade Quemadura al agresor durante $resolvedDuration turnos.';
  }

  @override

  /// Tras recibir un golpe, aplica Quemadura al enemigo que lo causo.
  ItemEffectResolution onReceiveDamageResolved({
    required Battler owner,
    required Battler source,
    required Item item,
    required int damageTaken,
  }) {
    final resolvedDuration = max(1, item.value > 0 ? item.value : duration);
    return ItemEffectResolution(
      owner: owner,
      opponent: source.applyStatus(
        QuemaduraStatus(remainingTurns: resolvedDuration),
        source: owner,
      ),
    );
  }
}

/// Reduce el cooldown de la primera habilidad manual resuelta en cada combate.
class CrackedBatteryItemEffect extends ItemEffect {
  /// Crea un efecto reutilizable para la Bateria Rajada.
  const CrackedBatteryItemEffect()
      : super(
          description:
              'La primera habilidad manual que se resuelve en combate reduce su cooldown restante.',
          hooks: const {
            ItemEffectHook.abilityResolved,
          },
        );

  @override

  /// Genera la descripcion final usando el value real del item equipado.
  String descriptionFor(Item item) {
    return 'La primera habilidad manual que se resuelve en combate reduce su cooldown en ${item.value}.';
  }

  @override

  /// Detecta la primera entrada en cooldown y la acorta una sola vez por combate.
  ItemEffectResolution onAbilityResolved({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required BattlerAbility previousAbility,
    required BattlerAbility resolvedAbility,
    required ItemAbilityResolutionContext context,
  }) {
    if (!owner.hasCombatFlag(Battler.combatActiveFlag)) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }
    if (resolvedAbility.manualActivationContext !=
        BattlerAbilityActivationContext.battle) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }
    if (!_enteredCooldown(previousAbility, resolvedAbility)) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    final usedFlag = _itemCombatFlag(
      item,
      ItemCombatFlagKind.crackedBatteryUsed,
    );
    if (owner.hasCombatFlag(usedFlag)) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    final updatedAbility = resolvedAbility.reduceCooldown(item.value);
    return ItemEffectResolution(
      owner: owner.updateAbility(updatedAbility).addCombatFlag(usedFlag),
      opponent: opponent,
    );
  }
}

/// Aumenta el dano si el objetivo no tiene ningun buff activo.
class ImpactGlovesItemEffect extends ItemEffect {
  /// Crea un efecto reutilizable para los Guantes de Impacto.
  const ImpactGlovesItemEffect()
      : super(
          description:
              'Tus ataques infligen dano adicional si el objetivo no tiene buffs.',
          hooks: const {
            ItemEffectHook.outgoingDamageModifier,
          },
        );

  @override

  /// Genera la descripcion final usando el value real del item equipado.
  String descriptionFor(Item item) {
    return 'Tus ataques infligen ${item.value} de dano adicional si el objetivo no tiene buffs.';
  }

  @override

  /// Suma dano solo cuando el objetivo esta completamente sin buffs.
  int modifyOutgoingDamage({
    required Battler owner,
    required Battler target,
    required Item item,
    required int damage,
  }) {
    final targetHasBuff = target.statuses.any(
      (status) => status.type == BattlerStatusType.buff,
    );
    if (targetHasBuff) return damage;

    return damage + item.value;
  }
}

/// Reduce la potencia de Quemadura e Intoxicacion al recibirlas.
class ChemicalFilterItemEffect extends ItemEffect {
  /// Crea un efecto reutilizable para el Filtro Quimico.
  const ChemicalFilterItemEffect()
      : super(
          description:
              'Reduce la Quemadura e Intoxicacion recibidas al aplicarse.',
          hooks: const {
            ItemEffectHook.incomingStatusModifier,
          },
        );

  @override

  /// Genera la descripcion final usando el value real del item equipado.
  String descriptionFor(Item item) {
    return 'Reduce la Quemadura e Intoxicacion recibidas en ${item.value} al aplicarse.';
  }

  @override

  /// Resta duracion o value al estado recibido y puede cancelarlo si llega a cero.
  BattlerStatus? modifyIncomingStatus({
    required Battler owner,
    required Battler source,
    required Item item,
    required BattlerStatus status,
  }) {
    if (status is QuemaduraStatus) {
      final nextTurns = max(0, status.remainingTurns - item.value);
      if (nextTurns <= 0) return null;

      return status.copyWith(remainingTurns: nextTurns);
    }

    if (status is IntoxicacionStatus) {
      final nextValue = max(0, status.value - item.value);
      if (nextValue <= 0) return null;

      return status.copyWith(value: nextValue);
    }

    return status;
  }
}

/// Solo cambia stats del item, asi que aqui solo personaliza la descripcion.
class BillingModuleItemEffect extends ItemEffect {
  /// Crea un efecto reutilizable para el Modulo de Cobro.
  const BillingModuleItemEffect()
      : super(
          description: 'Aumenta los ingresos, pero reduce la vida maxima.',
        );

  @override

  /// Explica a la UI cuanto income gana y cuanto HP maximo pierde el portador.
  String descriptionFor(Item item) {
    final healthPenalty = item.maxHealthPercentModifier.abs();
    final incomeGain = item.incomeModifier;
    final sign = item.maxHealthPercentModifier > 0 ? '+' : '-';

    return '+$incomeGain INCOME mientras este equipado. $sign$healthPenalty% HP MAX mientras este equipado.';
  }
}

/// Alarga las Quemaduras aplicadas y a cambio quema al propio portador al final de turno.
class PortableOvenItemEffect extends ItemEffect {
  /// Crea un efecto reutilizable para el Horno Portatil.
  const PortableOvenItemEffect()
      : super(
          description:
              'Tus Quemaduras duran mas, pero te quemas al final de tu turno.',
          hooks: const {
            ItemEffectHook.turnEnd,
            ItemEffectHook.outgoingStatusModifier,
          },
        );

  @override

  /// Genera la descripcion final usando el value real del item equipado.
  String descriptionFor(Item item) {
    return 'Las Quemaduras que aplicas duran ${item.value} turno mas. Al final de tu turno te aplicas Quemadura (${item.value}).';
  }

  @override

  /// Extiende solo las Quemaduras que el portador aplica a otros objetivos.
  BattlerStatus? modifyOutgoingStatus({
    required Battler owner,
    required Battler target,
    required Item item,
    required BattlerStatus status,
  }) {
    if (status is! QuemaduraStatus) return status;

    return status.copyWith(
      remainingTurns: status.remainingTurns + item.value,
    );
  }

  @override

  /// Al cerrar el turno propio, aplica una Quemadura al usuario.
  ItemEffectResolution onTurnEnd({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required bool isOwnerTurn,
  }) {
    if (!isOwnerTurn) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    return ItemEffectResolution(
      owner: owner.applyStatus(
        QuemaduraStatus(remainingTurns: item.value),
        source: owner,
      ),
      opponent: opponent,
    );
  }
}

/// Cura al usuario cada vez que una habilidad suya entra en cooldown.
class ParasiticCapacitorItemEffect extends ItemEffect {
  /// Crea un efecto reutilizable para el Capacitador Parasitario.
  const ParasiticCapacitorItemEffect()
      : super(
          description:
              'Cuando una habilidad entra en cooldown, recuperas vida.',
          hooks: const {
            ItemEffectHook.abilityResolved,
          },
        );

  @override

  /// Genera la descripcion final usando el value real del item equipado.
  String descriptionFor(Item item) {
    return 'Cuando una habilidad entra en cooldown, te curas ${item.value} HP.';
  }

  @override

  /// Detecta entradas en cooldown y cura al instante al portador.
  ItemEffectResolution onAbilityResolved({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required BattlerAbility previousAbility,
    required BattlerAbility resolvedAbility,
    required ItemAbilityResolutionContext context,
  }) {
    if (!_enteredCooldown(previousAbility, resolvedAbility)) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    return ItemEffectResolution(
      owner: owner.heal(item.value),
      opponent: opponent,
    );
  }
}

/// Potencia la primera activacion manual de cada combate.
class EclipseMantleItemEffect extends ItemEffect {
  /// Crea un efecto reutilizable para el Manto de Eclipse.
  const EclipseMantleItemEffect()
      : super(
          description:
              'La primera activacion manual de cada combate obtiene un bonus al value.',
          hooks: const {
            ItemEffectHook.manualAbilityPreparation,
          },
        );

  @override

  /// Genera la descripcion final usando el value real del item equipado.
  String descriptionFor(Item item) {
    return 'La primera activacion manual de cada combate obtiene +${item.value} al value.';
  }

  @override

  /// Aumenta temporalmente el value de la primera habilidad manual del combate.
  ItemAbilityPreparationResolution onManualAbilityPreparing({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required BattlerAbility ability,
    required BattlerAbilityActivationContext screenContext,
  }) {
    if (screenContext != BattlerAbilityActivationContext.battle ||
        !owner.hasCombatFlag(Battler.combatActiveFlag)) {
      return ItemAbilityPreparationResolution(
        owner: owner,
        opponent: opponent,
        ability: ability,
      );
    }

    final usedFlag = _itemCombatFlag(
      item,
      ItemCombatFlagKind.eclipseMantleUsed,
    );
    if (owner.hasCombatFlag(usedFlag)) {
      return ItemAbilityPreparationResolution(
        owner: owner,
        opponent: opponent,
        ability: ability,
      );
    }

    final boostedAbility = ability.addRuntimeValueBonus(item.value);
    final updatedOwner =
        owner.updateAbility(boostedAbility).addCombatFlag(usedFlag);

    return ItemAbilityPreparationResolution(
      owner: updatedOwner,
      opponent: opponent,
      ability: boostedAbility,
    );
  }
}

/// Evita una muerte por combate, deja 1 HP y refresca todas las habilidades.
class OperativeBlackBoxItemEffect extends ItemEffect {
  /// Crea un efecto reutilizable para la Caja Negra del Operativo.
  const OperativeBlackBoxItemEffect()
      : super(
          description:
              'Una vez por combate evita la muerte, deja 1 HP y refresca todas las habilidades.',
          hooks: const {
            ItemEffectHook.turnStart,
            ItemEffectHook.fatalDamage,
          },
        );

  @override

  /// Genera la descripcion final usando la vida con la que deja al portador.
  String descriptionFor(Item item) {
    return 'Una vez por combate evita la muerte, te deja en ${max(1, item.value)} HP y refresca todas las habilidades.';
  }

  @override

  /// Intercepta el dano letal y aplica la proteccion una sola vez por combate.
  Battler onReceiveFatalDamage({
    required Battler owner,
    required Item item,
    required int incomingDamage,
  }) {
    if (!owner.hasCombatFlag(Battler.combatActiveFlag)) return owner;

    final usedFlag = _itemCombatFlag(
      item,
      ItemCombatFlagKind.operativeBlackBoxUsed,
    );
    final protectionFlag = _itemCombatFlag(
      item,
      ItemCombatFlagKind.operativeBlackBoxProtection,
    );
    final recoveredHealth = max(1, item.value);

    if (owner.hasCombatFlag(protectionFlag)) {
      return owner.copyWith(health: recoveredHealth);
    }

    if (owner.hasCombatFlag(usedFlag)) return owner;

    return owner
        .copyWith(health: recoveredHealth)
        .resetAllAbilities()
        .addCombatFlag(usedFlag)
        .addCombatFlag(protectionFlag);
  }

  @override

  /// Limpia la proteccion temporal al inicio del siguiente turno propio.
  ItemEffectResolution onTurnStart({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required bool isOwnerTurn,
  }) {
    if (!isOwnerTurn) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    final protectionFlag = _itemCombatFlag(
      item,
      ItemCombatFlagKind.operativeBlackBoxProtection,
    );
    if (!owner.hasCombatFlag(protectionFlag)) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    return ItemEffectResolution(
      owner: owner.removeCombatFlag(protectionFlag),
      opponent: opponent,
    );
  }
}

/// Enumera los estados "nuevos" que pueden ser aplicados por objetos.
enum ItemStatusEffectKind {
  blindajeTemporal,
  calentando,
  conmocion,
  fragilidad,
  inercia,
  inerciaAtaque,
  inerciaBarrera,
  interferencia,
}

/// Identifica en que momento del combate un objeto genera uno de esos estados.
enum ItemStatusEffectTrigger {
  attackTarget,
  attackOwner,
  attackOwnerReinforce,
  receiveDamageSource,
  receiveDamageOwner,
  turnStartOwnerRefreshMinimum,
  turnStartOwnerIfMissing,
}

/// Aplica estados reutilizando una unica pieza de logica segun trigger y tipo.
class StatusItemEffect extends ItemEffect {
  final ItemStatusEffectKind kind;
  final ItemStatusEffectTrigger trigger;

  /// Crea un efecto parametrico para objetos que solo introducen estados.
  const StatusItemEffect({
    required this.kind,
    required this.trigger,
  }) : super(
          description: 'Aplica un estado contextual.',
          hooks: trigger == ItemStatusEffectTrigger.attackTarget ||
                  trigger == ItemStatusEffectTrigger.attackOwner ||
                  trigger == ItemStatusEffectTrigger.attackOwnerReinforce
              ? const {
                  ItemEffectHook.attackResolved,
                }
              : trigger == ItemStatusEffectTrigger.receiveDamageSource ||
                      trigger == ItemStatusEffectTrigger.receiveDamageOwner
                  ? const {
                      ItemEffectHook.receiveDamageResolved,
                    }
                  : const {
                      ItemEffectHook.turnStart,
                    },
        );

  @override
  String descriptionFor(Item item) {
    final phrase = _statusPhrase(item);

    switch (trigger) {
      case ItemStatusEffectTrigger.attackTarget:
        return 'Al atacar: aplica $phrase al enemigo.';
      case ItemStatusEffectTrigger.attackOwner:
        return 'Al atacar: ganas $phrase.';
      case ItemStatusEffectTrigger.attackOwnerReinforce:
        return 'Al atacar: genera o aumenta $phrase.';
      case ItemStatusEffectTrigger.receiveDamageSource:
        return 'Al recibir dano: aplica $phrase al agresor.';
      case ItemStatusEffectTrigger.receiveDamageOwner:
        return 'Al recibir dano: ganas $phrase.';
      case ItemStatusEffectTrigger.turnStartOwnerRefreshMinimum:
        return 'Al inicio de tu turno, recuperas $phrase.';
      case ItemStatusEffectTrigger.turnStartOwnerIfMissing:
        return 'Al inicio de tu turno, si no lo tienes, ganas $phrase.';
    }
  }

  @override
  ItemEffectResolution onTurnStart({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required bool isOwnerTurn,
  }) {
    if (!isOwnerTurn) {
      return ItemEffectResolution(owner: owner, opponent: opponent);
    }

    switch (trigger) {
      case ItemStatusEffectTrigger.turnStartOwnerRefreshMinimum:
      case ItemStatusEffectTrigger.turnStartOwnerIfMissing:
        return ItemEffectResolution(
          owner: _applyToOwner(
            owner: owner,
            source: owner,
            item: item,
          ),
          opponent: opponent,
        );
      case ItemStatusEffectTrigger.attackTarget:
      case ItemStatusEffectTrigger.attackOwner:
      case ItemStatusEffectTrigger.attackOwnerReinforce:
      case ItemStatusEffectTrigger.receiveDamageSource:
      case ItemStatusEffectTrigger.receiveDamageOwner:
        return ItemEffectResolution(owner: owner, opponent: opponent);
    }
  }

  @override
  ItemEffectResolution onAttackResolved({
    required Battler owner,
    required Battler target,
    required Item item,
    required int damageDealt,
  }) {
    switch (trigger) {
      case ItemStatusEffectTrigger.attackTarget:
        return ItemEffectResolution(
          owner: owner,
          opponent: target.applyStatus(
            _buildStatus(item),
            source: owner,
          ),
        );
      case ItemStatusEffectTrigger.attackOwner:
      case ItemStatusEffectTrigger.attackOwnerReinforce:
        return ItemEffectResolution(
          owner: _applyToOwner(
            owner: owner,
            source: owner,
            item: item,
          ),
          opponent: target,
        );
      case ItemStatusEffectTrigger.receiveDamageSource:
      case ItemStatusEffectTrigger.receiveDamageOwner:
      case ItemStatusEffectTrigger.turnStartOwnerRefreshMinimum:
      case ItemStatusEffectTrigger.turnStartOwnerIfMissing:
        return ItemEffectResolution(owner: owner, opponent: target);
    }
  }

  @override
  ItemEffectResolution onReceiveDamageResolved({
    required Battler owner,
    required Battler source,
    required Item item,
    required int damageTaken,
  }) {
    switch (trigger) {
      case ItemStatusEffectTrigger.receiveDamageSource:
        return ItemEffectResolution(
          owner: owner,
          opponent: source.applyStatus(
            _buildStatus(item),
            source: owner,
          ),
        );
      case ItemStatusEffectTrigger.receiveDamageOwner:
        return ItemEffectResolution(
          owner: _applyToOwner(
            owner: owner,
            source: owner,
            item: item,
          ),
          opponent: source,
        );
      case ItemStatusEffectTrigger.attackTarget:
      case ItemStatusEffectTrigger.attackOwner:
      case ItemStatusEffectTrigger.attackOwnerReinforce:
      case ItemStatusEffectTrigger.turnStartOwnerRefreshMinimum:
      case ItemStatusEffectTrigger.turnStartOwnerIfMissing:
        return ItemEffectResolution(owner: owner, opponent: source);
    }
  }

  Battler _applyToOwner({
    required Battler owner,
    required Battler source,
    required Item item,
  }) {
    final status = _buildStatus(item);

    switch (trigger) {
      case ItemStatusEffectTrigger.turnStartOwnerIfMissing:
        if (owner.hasStatus(status.id)) return owner;

        return owner.applyStatus(
          status,
          source: source,
        );
      case ItemStatusEffectTrigger.turnStartOwnerRefreshMinimum:
        final currentStatus = owner.statusById(status.id);
        if (currentStatus != null &&
            currentStatus.resolved(owner).value >= status.value) {
          return owner;
        }

        final refreshedOwner =
            currentStatus == null ? owner : owner.removeStatus(status.id);
        return refreshedOwner.applyStatus(
          status,
          source: source,
        );
      case ItemStatusEffectTrigger.attackOwnerReinforce:
        if (kind != ItemStatusEffectKind.calentando) {
          return owner.applyStatus(
            status,
            source: source,
          );
        }

        final currentStatus = owner.statusById(CalentandoStatus.statusId);
        if (currentStatus is! CalentandoStatus) {
          return owner.applyStatus(
            status,
            source: source,
          );
        }

        return owner.applyStatus(
          currentStatus.copyWith(
            value: currentStatus.value + status.value,
            remainingTurns: max(
              currentStatus.remainingTurns,
              status.remainingTurns,
            ),
          ),
          applyEquipmentModifiers: false,
        );
      case ItemStatusEffectTrigger.attackOwner:
      case ItemStatusEffectTrigger.receiveDamageOwner:
        return owner.applyStatus(
          status,
          source: source,
        );
      case ItemStatusEffectTrigger.attackTarget:
      case ItemStatusEffectTrigger.receiveDamageSource:
        return owner;
    }
  }

  BattlerStatus _buildStatus(Item item) {
    final resolvedValue = max(1, item.value);

    switch (kind) {
      case ItemStatusEffectKind.blindajeTemporal:
        return BlindajeTemporalStatus(value: resolvedValue);
      case ItemStatusEffectKind.calentando:
        return CalentandoStatus(value: resolvedValue);
      case ItemStatusEffectKind.conmocion:
        return ConmocionStatus(value: resolvedValue);
      case ItemStatusEffectKind.fragilidad:
        return FragilidadStatus(remainingTurns: resolvedValue);
      case ItemStatusEffectKind.inercia:
        return InerciaStatus(value: resolvedValue);
      case ItemStatusEffectKind.inerciaAtaque:
        return InerciaAtaqueStatus(value: resolvedValue);
      case ItemStatusEffectKind.inerciaBarrera:
        return InerciaBarreraStatus(value: resolvedValue);
      case ItemStatusEffectKind.interferencia:
        return InterferenciaStatus(remainingTurns: resolvedValue);
    }
  }

  String _statusPhrase(Item item) {
    final resolvedValue = max(1, item.value);

    switch (kind) {
      case ItemStatusEffectKind.blindajeTemporal:
        return 'Blindaje Temporal ($resolvedValue de absorcion)';
      case ItemStatusEffectKind.calentando:
        return 'Calentando (+$resolvedValue dano)';
      case ItemStatusEffectKind.conmocion:
        return 'Conmocion (-$resolvedValue dano en el siguiente ataque)';
      case ItemStatusEffectKind.fragilidad:
        return 'Fragilidad (+$resolvedValue dano recibido en el siguiente ataque)';
      case ItemStatusEffectKind.inercia:
        return 'Inercia (+$resolvedValue por acumulacion)';
      case ItemStatusEffectKind.inerciaAtaque:
        return 'Reserva de Inercia: ATK (+$resolvedValue)';
      case ItemStatusEffectKind.inerciaBarrera:
        return 'Reserva de Inercia: Barrera (+$resolvedValue)';
      case ItemStatusEffectKind.interferencia:
        return 'Interferencia durante $resolvedValue turnos';
    }
  }
}

/// Comprueba si una habilidad ha pasado de estar lista a estar en cooldown.
bool _enteredCooldown(
  BattlerAbility previousAbility,
  BattlerAbility resolvedAbility,
) {
  return !previousAbility.isOnCooldown && resolvedAbility.isOnCooldown;
}

/// Recupera barrera sin sobrepasar la barrera maxima calculada del portador.
Battler _recoverBarrier({
  required Battler owner,
  required int amount,
}) {
  final safeAmount = max(0, amount);
  if (safeAmount <= 0 || owner.currentBarrier >= owner.maxBarrier) {
    return owner;
  }

  return owner.copyWith(
    currentBarrier: min(
      owner.maxBarrier,
      owner.currentBarrier + safeAmount,
    ),
  );
}

/// Refresca un Blindaje Temporal minimo sin acumularlo infinitamente.
Battler _refreshMinimumBlindajeTemporal({
  required Battler owner,
  required int value,
}) {
  final shieldValue = max(1, value);
  final currentShield = owner.statusById(BlindajeTemporalStatus.statusId);
  if (currentShield != null &&
      currentShield.resolved(owner).value >= shieldValue) {
    return owner;
  }

  final refreshedOwner = currentShield == null
      ? owner
      : owner.removeStatus(BlindajeTemporalStatus.statusId);
  return refreshedOwner.applyStatus(
    BlindajeTemporalStatus(value: shieldValue),
    source: refreshedOwner,
  );
}

/// Genera flags de combate estables para que cada item controle usos por instancia.
/// Genera una flag runtime tipada para aislar usos de efectos por item o por instancia.
CombatRuntimeFlag _itemCombatFlag(
  Item item,
  ItemCombatFlagKind flag,
) {
  return CombatRuntimeFlag.item(
    itemFlag: flag,
    itemId: item.id,
    itemInstanceId: item.instanceId,
  );
}
