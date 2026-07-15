part of '../battler_status.dart';

/// Debuff que hace daño al inicio de turno segun los turnos que le queden.
class QuemaduraStatus extends BattlerStatus {
  static const statusId = BattlerStatusId.quemadura;
  static const defaultDuration = 3;

  /// Crea una instancia de Quemadura cuya fuerza sigue su duracion restante.
  const QuemaduraStatus({
    int remainingTurns = defaultDuration,
    int? value,
  }) : super(
          id: statusId,
          name: 'Quemadura',
          type: BattlerStatusType.debuff,
          tags: _debuffQuemaduraStatusTags,
          hooks: const {
            BattlerStatusHook.turnStart,
          },
          description:
              'Al inicio del turno del objetivo, este estado inflige daño igual a su duracion restante.',
          remainingTurns: remainingTurns,
          value: value ?? remainingTurns,
        );

  /// Devuelve el daño efectivo que va a infligir ahora mismo.
  int currentDamage(Battler owner) => resolved(owner).value;

  /// Permite que varias Quemaduras convivan y se resuelvan por separado.
  @override
  bool get canStack => true;

  /// Hace que el value del estado siempre coincida con sus turnos restantes.
  @override
  int resolveValue(Battler owner) => remainingTurns;

  /// Anade a la descripcion el daño actual ya resuelto.
  @override
  String descriptionFor(Battler owner) {
    return '$description Daño actual: ${currentDamage(owner)}';
  }

  /// Clona el estado manteniendo sincronizados value y remainingTurns.
  @override
  BattlerStatus copyWith({
    int? remainingTurns,
    int? value,
  }) {
    final nextRemainingTurns = remainingTurns ?? this.remainingTurns;

    return QuemaduraStatus(
      remainingTurns: nextRemainingTurns,
      value: value ?? nextRemainingTurns,
    );
  }

  /// Amplifica la Quemadura alargando su duracion total.
  @override
  BattlerStatus amplifyValue(int factor) {
    if (factor <= 1) return this;

    return copyWith(
      remainingTurns: remainingTurns * factor,
    );
  }

  /// Al inicio del turno propio inflige daño de debuff igual a su valor actual.
  @override
  Battler onTurnStart({
    required Battler owner,
    required Battler opponent,
    required bool isOwnerTurn,
    RandomSource? randomizer,
  }) {
    if (!isOwnerTurn) return owner;

    final currentStatus = resolved(owner);
    return owner.runtimeReceiveDebuffDamage(
      currentStatus.value,
      source: opponent,
    );
  }
}

/// Debuff indefinido que inflige daño fijo al final del turno y se renueva solo.
class IntoxicacionStatus extends BattlerStatus {
  static const statusId = BattlerStatusId.intoxicacion;
  static const defaultDuration = 1;
  static const defaultValue = 1;

  /// Crea una instancia de Intoxicacion con su daño fijo inicial.
  const IntoxicacionStatus({
    int remainingTurns = defaultDuration,
    int value = defaultValue,
  }) : super(
          id: statusId,
          name: 'Intoxicacion',
          type: BattlerStatusType.debuff,
          tags: _debuffIntoxicacionStatusTags,
          hooks: const {
            BattlerStatusHook.turnEnd,
            BattlerStatusHook.combatEnd,
            BattlerStatusHook.statusApplied,
          },
          description:
              'Al final del turno del objetivo, este estado inflige daño fijo igual a su value directamente a la vida (ignora Barrera) y renueva su duracion.',
          remainingTurns: remainingTurns,
          value: value,
        );

  /// Hace que la Intoxicacion no caduque por decremento normal de turnos.
  @override
  bool get isIndefinite => true;

  /// Devuelve el daño fijo efectivo que inflige este estado.
  int currentDamage(Battler owner) => resolved(owner).value;

  /// Anade a la descripcion el daño actual ya resuelto.
  @override
  String descriptionFor(Battler owner) {
    return '$description Daño actual: ${currentDamage(owner)}';
  }

  @override
  BattlerStatusApplicationResolution onStatusApplied({
    required Battler owner,
    required BattlerStatus appliedStatus,
  }) {
    if (appliedStatus.id != id) {
      return BattlerStatusApplicationResolution(
        owner: owner,
        appliedStatus: appliedStatus,
      );
    }

    final currentStatus = resolved(owner);
    final incomingStatus = appliedStatus.resolved(owner);
    return BattlerStatusApplicationResolution(
      owner: owner.removeStatusInstance(this),
      appliedStatus: copyWith(
        remainingTurns: max(
          currentStatus.remainingTurns,
          incomingStatus.remainingTurns,
        ),
        value: max(0, currentStatus.value) + max(0, incomingStatus.value),
      ),
    );
  }

  /// Clona el estado manteniendo el tipo concreto de Intoxicacion.
  @override
  BattlerStatus copyWith({
    int? remainingTurns,
    int? value,
  }) {
    return IntoxicacionStatus(
      remainingTurns: remainingTurns ?? this.remainingTurns,
      value: value ?? this.value,
    );
  }

  /// Al final del turno propio reaplica su duracion y luego inflige daño fijo.
  @override
  Battler onTurnEnd({
    required Battler owner,
    required Battler opponent,
    required bool isOwnerTurn,
    RandomSource? randomizer,
  }) {
    if (!isOwnerTurn) return owner;

    final currentStatus = resolved(owner);
    final renewedStatus = currentStatus.copyWith(
      remainingTurns: currentStatus.remainingTurns + 1,
    );
    final ownerWithRenewedStatus = owner.replaceStatusInstance(
      currentStatus: this,
      replacement: renewedStatus,
    );
    final incomingResolution =
        ownerWithRenewedStatus.runtimeApplyIncomingDamageEffects(
      source: opponent,
      damage: currentStatus.value,
      kind: DamageKind.debuff,
    );
    if (incomingResolution.damage <= 0) {
      return incomingResolution.owner;
    }

    final damagedOwner = incomingResolution.owner.copyWith(
      health:
          max(0, incomingResolution.owner.health - incomingResolution.damage),
    );
    if (damagedOwner.health > 0) {
      return damagedOwner;
    }

    return damagedOwner.runtimeApplyFatalDamageEffects(
      incomingDamage: incomingResolution.damage,
    );
  }

  /// La Intoxicacion no debe mantenerse cuando el combate ya ha terminado.
  @override
  Battler onCombatEnd({
    required Battler owner,
  }) {
    return owner.removeStatusInstance(this);
  }
}

/// Debuff persistente que potencia otros debuffs entrantes y se consume.
class ContagioStatus extends BattlerStatus {
  static const statusId = BattlerStatusId.contagio;
  static const defaultValue = 1;

  /// Crea una instancia de Contagio con su valor de amplificacion actual.
  const ContagioStatus({
    int value = defaultValue,
  }) : super(
          id: statusId,
          name: 'Contagio',
          type: BattlerStatusType.debuff,
          tags: _debuffContagioStatusTags,
          hooks: const {
            BattlerStatusHook.combatEnd,
            BattlerStatusHook.statusApplied,
          },
          description:
              'Cuando otro debuffo es aplicado al portador, aumenta su valor en value y reduce Contagio en 1.',
          remainingTurns: 1,
          value: value,
        );

  @override
  bool get isIndefinite => true;

  @override
  bool get persistsOutsideCombat => false;

  /// Construye la descripcion visible del efecto usando el valor actual.
  @override
  String descriptionFor(Battler owner) {
    return 'Cuando otro debuffo es aplicado al portador, aumenta su valor en $value y reduce Contagio en 1.';
  }

  /// Limpia o transforma estado temporal al cerrar combate.
  @override
  Battler onCombatEnd({
    required Battler owner,
  }) {
    return owner.removeStatusInstance(this);
  }

  @override
  BattlerStatusApplicationResolution onStatusApplied({
    required Battler owner,
    required BattlerStatus appliedStatus,
  }) {
    if (appliedStatus.id != id) {
      return BattlerStatusApplicationResolution(
        owner: owner,
        appliedStatus: appliedStatus,
      );
    }

    return BattlerStatusApplicationResolution(
      owner: owner.removeStatusInstance(this),
      appliedStatus: copyWith(value: max(0, value) + appliedStatus.value),
    );
  }

  @override
  BattlerStatus copyWith({
    int? remainingTurns,
    int? value,
  }) {
    return ContagioStatus(
      value: value ?? this.value,
    );
  }
}

/// Debuff acumulable que explota al recibir un golpe si llega a su maximo.
class FragilidadStatus extends BattlerStatus {
  static const statusId = BattlerStatusId.fragilidad;
  static const defaultDuration = 3;
  static const defaultValue = 1;
  static const maxValue = 10;
  static const triggerDamage = 10;

  /// Crea una instancia de Fragilidad con acumulacion limitada.
  const FragilidadStatus({
    int remainingTurns = defaultDuration,
    int value = defaultValue,
  }) : super(
          id: statusId,
          name: 'Fragilidad',
          type: BattlerStatusType.debuff,
          tags: _debuffStatusTags,
          hooks: const {
            BattlerStatusHook.receiveDamageResolved,
            BattlerStatusHook.statusApplied,
          },
          description:
              'Se acumula hasta 10. Si recibe un ataque con 10 Fragilidad, se consume e inflige 10 daño directo que ignora Barrera.',
          remainingTurns: remainingTurns,
          value: value,
        );

  /// Limita el valor efectivo al maximo de acumulacion.
  @override
  int resolveValue(Battler owner) => min(maxValue, max(0, value));

  /// Muestra la acumulacion, no la duracion, porque es el dato tactico clave.
  @override
  String badgeLabelFor(Battler owner) => '${resolved(owner).value}';

  /// Anade a la descripcion la acumulacion actual.
  @override
  String descriptionFor(Battler owner) {
    return '$description Acumulacion actual: ${resolved(owner).value}/$maxValue.';
  }

  /// Fusiona nuevas aplicaciones de Fragilidad en una unica acumulacion.
  @override
  BattlerStatusApplicationResolution onStatusApplied({
    required Battler owner,
    required BattlerStatus appliedStatus,
  }) {
    if (appliedStatus.id != id) {
      return BattlerStatusApplicationResolution(
        owner: owner,
        appliedStatus: appliedStatus,
      );
    }

    final currentStatus = resolved(owner);
    final incomingStatus = appliedStatus.resolved(owner);
    final stackedValue = min(
      maxValue,
      max(0, currentStatus.value) + max(0, incomingStatus.value),
    ).toInt();
    final refreshedTurns = max(
      currentStatus.remainingTurns,
      incomingStatus.remainingTurns,
    );

    return BattlerStatusApplicationResolution(
      owner: owner.removeStatus(statusId),
      appliedStatus: copyWith(
        remainingTurns: refreshedTurns,
        value: stackedValue,
      ),
    );
  }

  /// Explota al recibir un golpe si la acumulacion ya esta al maximo.
  @override
  Battler onReceiveDamageResolved({
    required Battler owner,
    required Battler source,
    required int damageTaken,
  }) {
    if (damageTaken <= 0) return owner;
    if (resolved(owner).value < maxValue) return owner;

    final ownerWithoutFragility = source.hasPendingBurstStatusFollowUp
        ? owner
        : owner.removeStatus(statusId);
    final visibleDamage = min(triggerDamage, ownerWithoutFragility.health);
    final damagedOwner = ownerWithoutFragility
        .copyWith(
          health: max(0, ownerWithoutFragility.health - triggerDamage),
        )
        .addCombatFlag(
          CombatRuntimeFlag.battler(
            BattlerCombatFlag.fragilidadTriggeredThisHit,
            secondaryValue: visibleDamage,
          ),
        );
    if (damagedOwner.health > 0) {
      return damagedOwner;
    }

    return damagedOwner.runtimeApplyFatalDamageEffects(
      incomingDamage: triggerDamage,
    );
  }

  /// Clona el estado manteniendo limitada su acumulacion.
  @override
  BattlerStatus copyWith({
    int? remainingTurns,
    int? value,
  }) {
    return FragilidadStatus(
      remainingTurns: remainingTurns ?? this.remainingTurns,
      value: min(maxValue, max(0, value ?? this.value)),
    );
  }
}

/// Debuff que debilita el siguiente ataque del portador y luego desaparece.
class ConmocionStatus extends BattlerStatus {
  static const statusId = BattlerStatusId.conmocion;
  static const defaultValue = 2;

  /// Crea una instancia de Conmocion con la reduccion de daño pendiente.
  const ConmocionStatus({
    int value = defaultValue,
  }) : super(
          id: statusId,
          name: 'Conmocion',
          type: BattlerStatusType.debuff,
          tags: _debuffAtaqueStatusTags,
          hooks: const {
            BattlerStatusHook.outgoingDamageModifier,
            BattlerStatusHook.attackResolved,
          },
          description:
              'Reduce el daño del siguiente ataque del portador y luego desaparece.',
          remainingTurns: 1,
          value: value,
        );

  /// Hace que el estado espere hasta que el portador llegue a atacar.
  @override
  bool get isIndefinite => true;

  /// Resta daño al siguiente ataque sin permitir valores negativos.
  @override
  int modifyOutgoingDamage({
    required Battler owner,
    required Battler target,
    required int damage,
  }) {
    return max(0, damage - value);
  }

  /// Consume la Conmocion justo despues de que el ataque se resuelva.
  @override
  Battler onAttackResolved({
    required Battler owner,
    required Battler target,
    required int damageDealt,
  }) {
    if (owner.hasPendingBurstStatusFollowUp) {
      return owner;
    }

    return owner.removeStatusInstance(this);
  }

  /// Clona el estado manteniendo la penalizacion pendiente.
  @override
  BattlerStatus copyWith({
    int? remainingTurns,
    int? value,
  }) {
    return ConmocionStatus(
      value: value ?? this.value,
    );
  }
}
