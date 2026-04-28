part of '../battler_status.dart';

/// Buff ofensivo que aumenta su daño bonus al final de cada turno propio.
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
          description: 'El usuario suma su value al daño total al atacar.',
          remainingTurns: remainingTurns,
          value: value,
        );

  /// Devuelve el bonus de daño efectivo que tiene ahora mismo este estado.
  int currentDamageBonus(Battler owner) => resolved(owner).value;

  @override

  /// Anade a la descripcion el bonus de daño actual ya resuelto.
  String descriptionFor(Battler owner) {
    return '$description Daño actual: +${currentDamageBonus(owner)}';
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

  /// Suma su bonus al daño de cada ataque del portador.
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

/// Buff explosivo que aumenta el siguiente golpe y luego se consume.
class PotenciaStatus extends BattlerStatus {
  static const statusId = BattlerStatusId.potencia;
  static const defaultValue = 1;

  /// Crea una instancia de Potencia con su bonus de daño pendiente.
  const PotenciaStatus({
    int value = defaultValue,
  }) : super(
          id: statusId,
          name: 'Potencia',
          type: BattlerStatusType.buff,
          tags: _buffAtaqueStatusTags,
          hooks: const {
            BattlerStatusHook.outgoingDamageModifier,
            BattlerStatusHook.attackResolved,
            BattlerStatusHook.statusApplied,
          },
          icon: Icons.bolt_rounded,
          description:
              'Aumenta el daño del siguiente golpe en su value y luego se consume.',
          remainingTurns: 1,
          value: value,
        );

  @override

  /// Hace que Potencia espere hasta el siguiente impacto del portador.
  bool get isIndefinite => true;

  @override

  /// Potencia solo tiene sentido durante combate y se limpia al salir.
  bool get persistsOutsideCombat => false;

  @override

  /// Anade a la descripcion el bonus de daño actual ya resuelto.
  String descriptionFor(Battler owner) {
    return '$description Daño extra actual: +${resolved(owner).value}';
  }

  @override

  /// Suma su bonus al siguiente golpe del portador.
  int modifyOutgoingDamage({
    required Battler owner,
    required Battler target,
    required int damage,
  }) {
    return damage + resolved(owner).value;
  }

  @override

  /// Consume la Potencia justo despues de resolver el primer golpe.
  Battler onAttackResolved({
    required Battler owner,
    required Battler target,
    required int damageDealt,
  }) {
    return owner.removeStatusInstance(this);
  }

  @override

  /// Si vuelve a aplicarse, acumula el daño pendiente.
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
      appliedStatus: copyWith(
        value: value + appliedStatus.value,
      ),
    );
  }

  @override

  /// Clona el estado manteniendo su bonus pendiente.
  BattlerStatus copyWith({
    int? remainingTurns,
    int? value,
  }) {
    return PotenciaStatus(
      value: value ?? this.value,
    );
  }
}

/// Buff temporal que hace que los efectos de Ciclo cuenten como dia y noche a la vez.
class CicloEclipseStatus extends BattlerStatus {
  static const statusId = BattlerStatusId.cicloEclipse;

  /// Crea una instancia temporal para Eclipse Manual.
  const CicloEclipseStatus({
    int remainingTurns = 1,
    int value = 1,
  }) : super(
          id: statusId,
          name: 'Eclipse Manual',
          type: BattlerStatusType.buff,
          tags: _buffCicloStatusTags,
          icon: Icons.brightness_medium_rounded,
          description:
              'Tus efectos de Ciclo cuentan como dia y noche a la vez.',
          remainingTurns: remainingTurns,
          value: value,
        );

  @override
  bool get persistsOutsideCombat => false;

  @override
  BattlerStatus copyWith({
    int? remainingTurns,
    int? value,
  }) {
    return CicloEclipseStatus(
      remainingTurns: remainingTurns ?? this.remainingTurns,
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

/// Carga defensiva acumulada que otros efectos pueden convertir en dano.
class ResonanciaStatus extends BattlerStatus {
  static const statusId = BattlerStatusId.resonancia;

  /// Crea una reserva de Resonancia acumulada durante el combate.
  const ResonanciaStatus({
    int value = 1,
  }) : super(
          id: statusId,
          name: 'Resonancia',
          type: BattlerStatusType.buff,
          tags: _buffResonanciaStatusTags,
          hooks: const {
            BattlerStatusHook.statusApplied,
          },
          icon: Icons.graphic_eq_rounded,
          description:
              'Carga defensiva acumulada. Algunos efectos la usan para infligir dano directo.',
          remainingTurns: 1,
          value: value,
        );

  @override
  bool get isIndefinite => true;

  @override
  bool get persistsOutsideCombat => false;

  @override
  String descriptionFor(Battler owner) {
    return '$description Resonancia actual: ${resolved(owner).value}';
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
      appliedStatus: copyWith(value: value + appliedStatus.value),
    );
  }

  @override
  BattlerStatus copyWith({
    int? remainingTurns,
    int? value,
  }) {
    return ResonanciaStatus(
      value: value ?? this.value,
    );
  }
}
