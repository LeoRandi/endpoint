part of '../battler_status.dart';

/// Debuff que hace dano al final de turno segun los turnos que le queden.
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
            BattlerStatusHook.turnEnd,
          },
          icon: Icons.whatshot_rounded,
          description:
              'Al final del turno del objetivo, este estado inflige dano igual a su duracion restante.',
          remainingTurns: remainingTurns,
          value: value ?? remainingTurns,
        );

  /// Devuelve el dano efectivo que va a infligir ahora mismo.
  int currentDamage(Battler owner) => resolved(owner).value;

  @override

  /// Permite que varias Quemaduras convivan y se resuelvan por separado.
  bool get canStack => true;

  @override

  /// Hace que el value del estado siempre coincida con sus turnos restantes.
  int resolveValue(Battler owner) => remainingTurns;

  @override

  /// Anade a la descripcion el dano actual ya resuelto.
  String descriptionFor(Battler owner) {
    return '$description Dano actual: ${currentDamage(owner)}';
  }

  @override

  /// Clona el estado manteniendo sincronizados value y remainingTurns.
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

  @override

  /// Amplifica la Quemadura alargando su duracion total.
  BattlerStatus amplifyValue(int factor) {
    if (factor <= 1) return this;

    return copyWith(
      remainingTurns: remainingTurns * factor,
    );
  }

  @override

  /// Al final del turno propio inflige dano de debuff igual a su valor actual.
  Battler onTurnEnd({
    required Battler owner,
    required Battler opponent,
    required bool isOwnerTurn,
    RunRandomizer? randomizer,
  }) {
    if (!isOwnerTurn) return owner;

    final currentStatus = resolved(owner);
    return owner.receiveDebuffDamage(
      currentStatus.value,
      source: opponent,
    );
  }
}

/// Debuff indefinido que inflige dano fijo al final del turno y se renueva solo.
class IntoxicacionStatus extends BattlerStatus {
  static const statusId = BattlerStatusId.intoxicacion;
  static const defaultDuration = 1;
  static const defaultValue = 1;

  /// Crea una instancia de Intoxicacion con su dano fijo inicial.
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
          },
          icon: Icons.science_rounded,
          description:
              'Al final del turno del objetivo, este estado inflige dano fijo igual a su value directamente a la vida (ignora Barrera) y renueva su duracion.',
          remainingTurns: remainingTurns,
          value: value,
        );

  @override

  /// Hace que la Intoxicacion no caduque por decremento normal de turnos.
  bool get isIndefinite => true;

  /// Devuelve el dano fijo efectivo que inflige este estado.
  int currentDamage(Battler owner) => resolved(owner).value;

  @override

  /// Anade a la descripcion el dano actual ya resuelto.
  String descriptionFor(Battler owner) {
    return '$description Dano actual: ${currentDamage(owner)}';
  }

  @override

  /// Clona el estado manteniendo el tipo concreto de Intoxicacion.
  BattlerStatus copyWith({
    int? remainingTurns,
    int? value,
  }) {
    return IntoxicacionStatus(
      remainingTurns: remainingTurns ?? this.remainingTurns,
      value: value ?? this.value,
    );
  }

  @override

  /// Al final del turno propio reaplica su duracion y luego inflige dano fijo.
  Battler onTurnEnd({
    required Battler owner,
    required Battler opponent,
    required bool isOwnerTurn,
    RunRandomizer? randomizer,
  }) {
    if (!isOwnerTurn) return owner;

    final currentStatus = resolved(owner);
    final renewedStatus = currentStatus.copyWith(
      remainingTurns: currentStatus.remainingTurns + 1,
    );
    final ownerWithRenewedStatus = owner.applyStatus(
      renewedStatus,
      applyEquipmentModifiers: false,
    );
    final incomingResolution =
        ownerWithRenewedStatus.applyIncomingDamageEffects(
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

    return damagedOwner.applyEquippedItemFatalDamageEffects(
      incomingDamage: incomingResolution.damage,
    );
  }

  @override

  /// La Intoxicacion no debe mantenerse cuando el combate ya ha terminado.
  Battler onCombatEnd({
    required Battler owner,
  }) {
    return owner.removeStatusInstance(this);
  }
}

/// Debuff puente que multiplica el siguiente debuff recibido y luego se consume.
class CatalisisCruelStatus extends BattlerStatus {
  static const statusId = BattlerStatusId.catalisisCruel;

  /// Crea una instancia de Catalisis Cruel con su multiplicador actual.
  const CatalisisCruelStatus({
    int value = 2,
  }) : super(
          id: statusId,
          name: 'Catalisis Cruel',
          type: BattlerStatusType.debuff,
          tags: _debuffStatusTags,
          hooks: const {
            BattlerStatusHook.statusApplied,
          },
          icon: Icons.biotech_rounded,
          description:
              'La proxima desventaja recibida multiplica su valor y consume este estado. Volver a aplicarlo acumula multiplicador.',
          remainingTurns: 1,
          value: value,
        );

  @override

  /// Hace que el estado espere indefinidamente hasta interceptar otro debuff.
  bool get isIndefinite => true;

  @override

  /// Anade a la descripcion el multiplicador activo actual.
  String descriptionFor(Battler owner) {
    return '$description Multiplicador actual: x$value';
  }

  @override

  /// Clona el estado manteniendo su multiplicador acumulado.
  BattlerStatus copyWith({
    int? remainingTurns,
    int? value,
  }) {
    return CatalisisCruelStatus(
      value: value ?? this.value,
    );
  }

  @override

  /// Acumula multiplicadores consigo mismo o amplifica el siguiente debuff que llegue.
  BattlerStatusApplicationResolution onStatusApplied({
    required Battler owner,
    required BattlerStatus appliedStatus,
  }) {
    if (appliedStatus.id == id) {
      final stackedMultiplier =
          (max(1, value) * max(1, appliedStatus.value)).toInt();

      return BattlerStatusApplicationResolution(
        owner: owner.removeStatusInstance(this),
        appliedStatus: appliedStatus.copyWith(value: stackedMultiplier),
      );
    }

    if (appliedStatus.type != BattlerStatusType.debuff) {
      return BattlerStatusApplicationResolution(
        owner: owner,
        appliedStatus: appliedStatus,
      );
    }

    return BattlerStatusApplicationResolution(
      owner: owner.removeStatusInstance(this),
      appliedStatus: appliedStatus.amplifyValue(value),
    );
  }
}

/// Debuff que aumenta el dano del siguiente ataque recibido y luego se consume.
class FragilidadStatus extends BattlerStatus {
  static const statusId = BattlerStatusId.fragilidad;
  static const defaultDuration = 3;

  /// Crea una instancia de Fragilidad con dano extra fijo hasta consumirse.
  const FragilidadStatus({
    int remainingTurns = defaultDuration,
    int? value,
  }) : super(
          id: statusId,
          name: 'Fragilidad',
          type: BattlerStatusType.debuff,
          tags: _debuffStatusTags,
          hooks: const {
            BattlerStatusHook.incomingDamageModifier,
            BattlerStatusHook.receiveDamageResolved,
          },
          icon: Icons.flash_on_outlined,
          description:
              'Aumenta el dano del siguiente ataque recibido y luego se consume.',
          remainingTurns: remainingTurns,
          value: value ?? remainingTurns,
        );

  @override

  /// Anade a la descripcion el dano extra que recibira el portador.
  String descriptionFor(Battler owner) {
    return '$description Dano extra actual: +${resolved(owner).value}';
  }

  @override

  /// Aumenta el siguiente dano de ataque que reciba el portador.
  int modifyIncomingDamage({
    required Battler owner,
    required Battler source,
    required int damage,
  }) {
    return damage + resolved(owner).value;
  }

  @override

  /// Consume la Fragilidad justo despues de resolver ese golpe.
  Battler onReceiveDamageResolved({
    required Battler owner,
    required Battler source,
    required int damageTaken,
  }) {
    if (damageTaken <= 0) return owner;

    return owner.removeStatusInstance(this);
  }

  @override

  /// Clona el estado manteniendo sincronizados value y remainingTurns.
  BattlerStatus copyWith({
    int? remainingTurns,
    int? value,
  }) {
    return FragilidadStatus(
      remainingTurns: remainingTurns ?? this.remainingTurns,
      value: value ?? this.value,
    );
  }
}

/// Debuff que bloquea el uso manual de habilidades mientras siga activo.
class InterferenciaStatus extends BattlerStatus {
  static const statusId = BattlerStatusId.interferencia;
  static const defaultDuration = 1;

  /// Crea una instancia de Interferencia cuya fuerza sigue la duracion restante.
  const InterferenciaStatus({
    int remainingTurns = defaultDuration,
    int? value,
  }) : super(
          id: statusId,
          name: 'Interferencia',
          type: BattlerStatusType.debuff,
          tags: _debuffStatusTags,
          hooks: const {
            BattlerStatusHook.manualAbilityActivationBlocker,
          },
          icon: Icons.portable_wifi_off_rounded,
          description:
              'Impide activar habilidades manuales mientras permanezca activo.',
          remainingTurns: remainingTurns,
          value: value ?? remainingTurns,
        );

  @override

  /// Hace que el value real del bloqueo coincida con su duracion restante.
  int resolveValue(Battler owner) => remainingTurns;

  @override

  /// Devuelve el motivo visible por el que la activacion manual queda bloqueada.
  String? manualAbilityActivationBlockReason({
    required Battler owner,
    required BattlerAbilityActivationContext screenContext,
  }) {
    return 'Interferencia activa: no puedes usar habilidades manuales';
  }

  @override

  /// Clona el estado manteniendo sincronizados value y remainingTurns.
  BattlerStatus copyWith({
    int? remainingTurns,
    int? value,
  }) {
    final nextRemainingTurns = remainingTurns ?? this.remainingTurns;
    return InterferenciaStatus(
      remainingTurns: nextRemainingTurns,
      value: value ?? nextRemainingTurns,
    );
  }
}

/// Debuff que debilita el siguiente ataque del portador y luego desaparece.
class ConmocionStatus extends BattlerStatus {
  static const statusId = BattlerStatusId.conmocion;
  static const defaultValue = 2;

  /// Crea una instancia de Conmocion con la reduccion de dano pendiente.
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
          icon: Icons.flash_off_rounded,
          description:
              'Reduce el dano del siguiente ataque del portador y luego desaparece.',
          remainingTurns: 1,
          value: value,
        );

  @override

  /// Hace que el estado espere hasta que el portador llegue a atacar.
  bool get isIndefinite => true;

  @override

  /// Resta dano al siguiente ataque sin permitir valores negativos.
  int modifyOutgoingDamage({
    required Battler owner,
    required Battler target,
    required int damage,
  }) {
    return max(0, damage - value);
  }

  @override

  /// Consume la Conmocion justo despues de que el ataque se resuelva.
  Battler onAttackResolved({
    required Battler owner,
    required Battler target,
    required int damageDealt,
  }) {
    if (owner.hasPendingBasicAttackFollowUp) {
      return owner;
    }

    return owner.removeStatusInstance(this);
  }

  @override

  /// Clona el estado manteniendo la penalizacion pendiente.
  BattlerStatus copyWith({
    int? remainingTurns,
    int? value,
  }) {
    return ConmocionStatus(
      value: value ?? this.value,
    );
  }
}

/// Debuff persistente que limita el income efectivo hasta que una deuda pendiente se pague.
class DeudaStatus extends BattlerStatus {
  static const statusId = BattlerStatusId.deuda;
  static const defaultValue = 8;

  /// Crea una instancia de Deuda con el saldo pendiente actual.
  const DeudaStatus({
    int value = defaultValue,
  }) : super(
          id: statusId,
          name: 'Deuda',
          type: BattlerStatusType.debuff,
          tags: _debuffEconomiaStatusTags,
          hooks: const {
            BattlerStatusHook.incomeModifier,
            BattlerStatusHook.statusApplied,
          },
          icon: Icons.receipt_long_rounded,
          description:
              'Limita el income efectivo a 1 hasta saldarse. No puede purgarse de forma convencional.',
          remainingTurns: 1,
          value: value,
        );

  @override

  /// Hace que la deuda siga viva hasta que un evento especifico la resuelva.
  bool get isIndefinite => true;

  @override

  /// Impide que efectos de purga convencionales eliminen la deuda.
  bool get isPurgeable => false;

  @override

  /// Limita el income efectivo del portador a un maximo de 1.
  int modifyIncome({
    required Battler owner,
    required int income,
  }) {
    return min(income, 1);
  }

  @override

  /// Anade a la descripcion el saldo pendiente y el income retenido actualmente.
  String descriptionFor(Battler owner) {
    final potentialIncome = owner.baseIncome +
        owner.equippedItems.fold<int>(
          0,
          (total, item) => total + item.incomeModifier,
        );
    final blockedIncome = max(0, potentialIncome - owner.income);
    return '$description Saldo pendiente: $value. Income retenido actualmente: +$blockedIncome.';
  }

  /// Resta un pago al saldo pendiente sin permitir valores negativos.
  DeudaStatus registerPayment(int payment) {
    return copyWith(value: max(0, value - max(0, payment))) as DeudaStatus;
  }

  @override

  /// Hace que volver a aplicar Deuda no cree copias ni reinicie el saldo.
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
      owner: owner,
      appliedStatus: this,
    );
  }

  @override

  /// Clona la deuda manteniendo el saldo pendiente.
  BattlerStatus copyWith({
    int? remainingTurns,
    int? value,
  }) {
    return DeudaStatus(
      value: value ?? this.value,
    );
  }
}
