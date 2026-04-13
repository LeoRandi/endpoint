part of '../battler_status.dart';

/// Buff ofensivo que aumenta su dano bonus al final de cada turno propio.
class CalentandoStatus extends BattlerStatus {
  static const statusId = BattlerStatusId.calentando;
  static const defaultDuration = 5;
  static const defaultValue = 1;

  /// Crea una instancia de Calentando con su duracion y bonus iniciales.
  const CalentandoStatus({
    int remainingTurns = defaultDuration,
    int value = defaultValue,
  }) : super(
          id: statusId,
          name: 'Calentando',
          type: BattlerStatusType.buff,
          tags: _buffAtaqueStatusTags,
          hooks: const {
            BattlerStatusHook.outgoingDamageModifier,
            BattlerStatusHook.turnEnd,
            BattlerStatusHook.combatEnd,
          },
          icon: Icons.local_fire_department_rounded,
          description: 'El usuario suma su value al dano total al atacar.',
          remainingTurns: remainingTurns,
          value: value,
        );

  /// Devuelve el bonus de dano efectivo que tiene ahora mismo este estado.
  int currentDamageBonus(Battler owner) => resolved(owner).value;

  @override

  /// Anade a la descripcion el bonus de dano actual ya resuelto.
  String descriptionFor(Battler owner) {
    return '$description Dano actual: +${currentDamageBonus(owner)}';
  }

  @override

  /// Clona el estado manteniendo el tipo concreto de Calentando.
  BattlerStatus copyWith({
    int? remainingTurns,
    int? value,
  }) {
    return CalentandoStatus(
      remainingTurns: remainingTurns ?? this.remainingTurns,
      value: value ?? this.value,
    );
  }

  @override

  /// Suma su bonus al dano de cada ataque del portador.
  int modifyOutgoingDamage({
    required Battler owner,
    required Battler target,
    required int damage,
  }) {
    return damage + currentDamageBonus(owner);
  }

  @override

  /// Al final del turno propio aumenta en uno su value para el siguiente golpe.
  Battler onTurnEnd({
    required Battler owner,
    required Battler opponent,
    required bool isOwnerTurn,
    RunRandomizer? randomizer,
  }) {
    if (!isOwnerTurn) return owner;

    final currentStatus = resolved(owner);
    return owner.applyStatus(
      currentStatus.copyWith(value: currentStatus.value + 1),
      applyEquipmentModifiers: false,
    );
  }

  @override

  /// Calentando es un boost exclusivamente de combate y desaparece al salir.
  Battler onCombatEnd({
    required Battler owner,
  }) {
    return owner.removeStatusInstance(this);
  }
}

/// Buff temporal que absorbe parte del siguiente golpe directo y luego se gasta.
class BlindajeTemporalStatus extends BattlerStatus {
  static const statusId = BattlerStatusId.blindajeTemporal;
  static const defaultValue = 4;

  /// Crea una instancia de Blindaje Temporal con su absorcion restante.
  const BlindajeTemporalStatus({
    int value = defaultValue,
  }) : super(
          id: statusId,
          name: 'Blindaje Temporal',
          type: BattlerStatusType.buff,
          tags: _buffBarreraStatusTags,
          hooks: const {
            BattlerStatusHook.incomingDamageEffect,
            BattlerStatusHook.statusApplied,
          },
          icon: Icons.health_and_safety_rounded,
          description:
              'Absorbe dano del siguiente impacto directo y desaparece al agotarse o al terminar el combate.',
          remainingTurns: 1,
          value: value,
        );

  @override

  /// Hace que el escudo espere hasta recibir un golpe en vez de decrementar turnos.
  bool get isIndefinite => true;

  @override

  /// Hace que el escudo se limpie automaticamente al salir del combate.
  bool get persistsOutsideCombat => false;

  @override

  /// Anade a la descripcion la absorcion que le queda al escudo.
  String descriptionFor(Battler owner) {
    return '$description Absorcion restante: $value';
  }

  @override

  /// Absorbe solo dano directo, reduce su reserva y se elimina al agotarse.
  BattlerIncomingDamageResolution onIncomingDamage({
    required Battler owner,
    required Battler source,
    required int damage,
    required DamageKind kind,
  }) {
    if (kind != DamageKind.direct || damage <= 0) {
      return BattlerIncomingDamageResolution(owner: owner, damage: damage);
    }

    final absorbedDamage = min(value, damage);
    final remainingShield = max(0, value - absorbedDamage);
    final updatedOwner = remainingShield <= 0
        ? owner.removeStatusInstance(this)
        : owner.replaceStatusInstance(
            currentStatus: this,
            replacement: copyWith(value: remainingShield),
          );

    return BattlerIncomingDamageResolution(
      owner: updatedOwner,
      damage: max(0, damage - absorbedDamage),
    );
  }

  @override

  /// Acumula la absorcion si vuelve a aplicarse otro Blindaje Temporal.
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
      appliedStatus: copyWith(value: value + appliedStatus.value),
    );
  }

  @override

  /// Clona el estado manteniendo su absorcion acumulada.
  BattlerStatus copyWith({
    int? remainingTurns,
    int? value,
  }) {
    return BlindajeTemporalStatus(
      value: value ?? this.value,
    );
  }
}

/// Buff generador que crea reservas de ATK o de Barrera si no se usaron habilidades manuales.
class InerciaStatus extends BattlerStatus {
  static const statusId = BattlerStatusId.inercia;
  static const defaultValue = 1;

  /// Crea una instancia de Inercia con el valor que entregara a cada reserva.
  const InerciaStatus({
    int value = defaultValue,
  }) : super(
          id: statusId,
          name: 'Inercia',
          type: BattlerStatusType.buff,
          tags: _buffAtaqueBarreraStatusTags,
          hooks: const {
            BattlerStatusHook.turnEnd,
            BattlerStatusHook.statusApplied,
          },
          icon: Icons.motion_photos_on_rounded,
          description:
              'Si no activas habilidades manuales en tu turno, genera una reserva temporal aleatoria de ATK o de Barrera.',
          remainingTurns: 1,
          value: value,
        );

  @override

  /// Hace que Inercia permanezca mientras no sea reemplazada o eliminada.
  bool get isIndefinite => true;

  @override

  /// Anade a la descripcion el valor que aporta cada acumulacion.
  String descriptionFor(Battler owner) {
    return '$description Valor por acumulacion: +$value';
  }

  @override

  /// Al final del turno propio genera una reserva aleatoria si no hubo activacion manual.
  Battler onTurnEnd({
    required Battler owner,
    required Battler opponent,
    required bool isOwnerTurn,
    RunRandomizer? randomizer,
  }) {
    if (!isOwnerTurn ||
        owner.hasCombatFlag(Battler.manualAbilityActivatedThisTurnFlag)) {
      return owner;
    }

    final effectiveRandomizer = randomizer ?? RunRandomizer();
    final generatedStatus = effectiveRandomizer.chance(0.5)
        ? InerciaAtaqueStatus(value: value)
        : InerciaBarreraStatus(value: value);

    return owner.applyStatus(
      generatedStatus,
      applyEquipmentModifiers: false,
    );
  }

  @override

  /// Acumula su value cuando vuelve a aplicarse otra copia de Inercia.
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
      appliedStatus: copyWith(value: value + appliedStatus.value),
    );
  }

  @override

  /// Clona el estado manteniendo su valor acumulado.
  BattlerStatus copyWith({
    int? remainingTurns,
    int? value,
  }) {
    return InerciaStatus(
      value: value ?? this.value,
    );
  }
}

/// Reserva temporal de ataque generada por Inercia hasta el final del combate.
class InerciaAtaqueStatus extends BattlerStatus {
  static const statusId = BattlerStatusId.inerciaAtaque;

  /// Crea una reserva de ataque con el bonus acumulado actual.
  const InerciaAtaqueStatus({
    int value = 1,
  }) : super(
          id: statusId,
          name: 'Reserva de Inercia: ATK',
          type: BattlerStatusType.buff,
          tags: _buffAtaqueStatusTags,
          hooks: const {
            BattlerStatusHook.calculatedStatModifier,
            BattlerStatusHook.statusApplied,
          },
          icon: Icons.north_rounded,
          description:
              'Bonus temporal de ataque acumulado por Inercia hasta el final del combate.',
          remainingTurns: 1,
          value: value,
        );

  @override

  /// Hace que la reserva siga viva hasta que termine el combate.
  bool get isIndefinite => true;

  @override

  /// Hace que esta reserva se limpie automaticamente al salir del combate.
  bool get persistsOutsideCombat => false;

  @override

  /// Suma su value al calcular el ataque del portador.
  int modifyCalculatedStat({
    required Battler owner,
    required BattlerStat stat,
    required int value,
  }) {
    if (stat != BattlerStat.attack) return value;

    return value + this.value;
  }

  @override

  /// Acumula mas ataque cuando vuelve a aplicarse otra reserva del mismo tipo.
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
      appliedStatus: copyWith(value: value + appliedStatus.value),
    );
  }

  @override

  /// Clona la reserva manteniendo su bonus acumulado.
  BattlerStatus copyWith({
    int? remainingTurns,
    int? value,
  }) {
    return InerciaAtaqueStatus(
      value: value ?? this.value,
    );
  }
}

/// Reserva temporal de barrera generada por Inercia hasta el final del combate.
class InerciaBarreraStatus extends BattlerStatus {
  static const statusId = BattlerStatusId.inerciaBarrera;

  /// Crea una reserva de barrera con el bonus acumulado actual.
  const InerciaBarreraStatus({
    int value = 1,
  }) : super(
          id: statusId,
          name: 'Reserva de Inercia: Barrera',
          type: BattlerStatusType.buff,
          tags: _buffBarreraStatusTags,
          hooks: const {
            BattlerStatusHook.calculatedStatModifier,
            BattlerStatusHook.statusApplied,
          },
          icon: Icons.shield_rounded,
          description:
              'Bonus temporal de barrera acumulado por Inercia hasta el final del combate.',
          remainingTurns: 1,
          value: value,
        );

  @override

  /// Hace que la reserva siga viva hasta que termine el combate.
  bool get isIndefinite => true;

  @override

  /// Hace que esta reserva se limpie automaticamente al salir del combate.
  bool get persistsOutsideCombat => false;

  @override

  /// Suma su value al calcular la barrera del portador.
  int modifyCalculatedStat({
    required Battler owner,
    required BattlerStat stat,
    required int value,
  }) {
    if (stat != BattlerStat.barrier) return value;

    return value + this.value;
  }

  @override

  /// Acumula mas barrera cuando vuelve a aplicarse otra reserva del mismo tipo.
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
      appliedStatus: copyWith(value: value + appliedStatus.value),
    );
  }

  @override

  /// Clona la reserva manteniendo su bonus acumulado.
  BattlerStatus copyWith({
    int? remainingTurns,
    int? value,
  }) {
    return InerciaBarreraStatus(
      value: value ?? this.value,
    );
  }
}
