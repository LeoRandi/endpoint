import '_imports.dart';
import '../../services/run_randomizer.dart';

enum BattlerStatusType {
  buff,
  debuff,
}

enum DamageKind {
  direct,
  debuff,
}

class BattlerIncomingDamageResolution {
  final Battler owner;
  final int damage;

  const BattlerIncomingDamageResolution({
    required this.owner,
    required this.damage,
  });
}

extension BattlerStatusTypePresentation on BattlerStatusType {
  String get label {
    switch (this) {
      case BattlerStatusType.buff:
        return 'Buff';
      case BattlerStatusType.debuff:
        return 'Debuff';
    }
  }

  Color get accent {
    switch (this) {
      case BattlerStatusType.buff:
        return const Color(0xFF5AF78E);
      case BattlerStatusType.debuff:
        return const Color(0xFFFF6B6B);
    }
  }

  Color get foreground {
    switch (this) {
      case BattlerStatusType.buff:
        return const Color(0xFFE6FFF0);
      case BattlerStatusType.debuff:
        return const Color(0xFFFFE3E3);
    }
  }
}

abstract class BattlerStatus {
  final String id;
  final String name;
  final BattlerStatusType type;
  final IconData icon;
  final String description;
  final int remainingTurns;
  final int value;

  const BattlerStatus({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.description,
    required this.remainingTurns,
    this.value = 0,
  }) : assert(remainingTurns >= 0);

  bool get isIndefinite => false;
  bool get canStack => false;
  bool get isPurgeable => true;
  bool get persistsOutsideCombat => true;

  bool get isExpired => !isIndefinite && remainingTurns <= 0;

  String get remainingTurnsLabel {
    if (isIndefinite) return 'Indefinido';
    if (remainingTurns == 1) return '1 turno';
    return '$remainingTurns turnos';
  }

  BattlerStatus copyWith({
    int? remainingTurns,
    int? value,
  });

  BattlerStatus amplifyValue(int factor) {
    if (factor <= 1) return this;

    return copyWith(value: value * factor);
  }

  int resolveValue(Battler owner) => value;

  BattlerStatus resolved(Battler owner) {
    final resolvedValue = resolveValue(owner);

    if (resolvedValue == value) {
      return this;
    }

    return copyWith(value: resolvedValue);
  }

  String descriptionFor(Battler owner) => description;

  int modifyIncome({
    required Battler owner,
    required int income,
  }) {
    return income;
  }

  int modifyCalculatedStat({
    required Battler owner,
    required BattlerStat stat,
    required int value,
  }) {
    return value;
  }

  String? manualAbilityActivationBlockReason({
    required Battler owner,
    required BattlerAbilityActivationContext screenContext,
  }) {
    return null;
  }

  Battler onTurnStart({
    required Battler owner,
    required Battler opponent,
    required bool isOwnerTurn,
    RunRandomizer? randomizer,
  }) {
    return owner;
  }

  Battler onTurnEnd({
    required Battler owner,
    required Battler opponent,
    required bool isOwnerTurn,
    RunRandomizer? randomizer,
  }) {
    return owner;
  }

  BattlerIncomingDamageResolution onIncomingDamage({
    required Battler owner,
    required Battler source,
    required int damage,
    required DamageKind kind,
  }) {
    return BattlerIncomingDamageResolution(
      owner: owner,
      damage: damage,
    );
  }

  int modifyOutgoingDamage({
    required Battler owner,
    required Battler target,
    required int damage,
  }) {
    return damage;
  }

  int modifyIncomingDamage({
    required Battler owner,
    required Battler source,
    required int damage,
  }) {
    return damage;
  }

  Battler onAttackResolved({
    required Battler owner,
    required Battler target,
    required int damageDealt,
  }) {
    return owner;
  }

  Battler onReceiveDamageResolved({
    required Battler owner,
    required Battler source,
    required int damageTaken,
  }) {
    return owner;
  }

  BattlerStatusApplicationResolution onStatusApplied({
    required Battler owner,
    required BattlerStatus appliedStatus,
  }) {
    return BattlerStatusApplicationResolution(
      owner: owner,
      appliedStatus: appliedStatus,
    );
  }
}

class BattlerStatusApplicationResolution {
  final Battler owner;
  final BattlerStatus appliedStatus;

  const BattlerStatusApplicationResolution({
    required this.owner,
    required this.appliedStatus,
  });
}

class CalentandoStatus extends BattlerStatus {
  static const defaultDuration = 5;
  static const defaultValue = 1;

  const CalentandoStatus({
    int remainingTurns = defaultDuration,
    int value = defaultValue,
  }) : super(
          id: 'calentando',
          name: 'Calentando',
          type: BattlerStatusType.buff,
          icon: Icons.local_fire_department_rounded,
          description: 'El usuario suma su value al dano total al atacar.',
          remainingTurns: remainingTurns,
          value: value,
        );

  int currentDamageBonus(Battler owner) => resolved(owner).value;

  @override
  String descriptionFor(Battler owner) {
    return '$description Dano actual: +${currentDamageBonus(owner)}';
  }

  @override
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
  int modifyOutgoingDamage({
    required Battler owner,
    required Battler target,
    required int damage,
  }) {
    return damage + currentDamageBonus(owner);
  }

  @override
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
}

class QuemaduraStatus extends BattlerStatus {
  static const defaultDuration = 3;

  const QuemaduraStatus({
    int remainingTurns = defaultDuration,
    int? value,
  }) : super(
          id: 'quemadura',
          name: 'Quemadura',
          type: BattlerStatusType.debuff,
          icon: Icons.whatshot_rounded,
          description:
              'Al final del turno del objetivo, este estado inflige dano igual a su duracion restante.',
          remainingTurns: remainingTurns,
          value: value ?? remainingTurns,
        );

  int currentDamage(Battler owner) => resolved(owner).value;

  @override
  bool get canStack => true;

  @override
  int resolveValue(Battler owner) => remainingTurns;

  @override
  String descriptionFor(Battler owner) {
    return '$description Dano actual: ${currentDamage(owner)}';
  }

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

  @override
  BattlerStatus amplifyValue(int factor) {
    if (factor <= 1) return this;

    return copyWith(
      remainingTurns: remainingTurns * factor,
    );
  }

  @override
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

class IntoxicacionStatus extends BattlerStatus {
  static const defaultDuration = 1;
  static const defaultValue = 1;

  const IntoxicacionStatus({
    int remainingTurns = defaultDuration,
    int value = defaultValue,
  }) : super(
          id: 'intoxicacion',
          name: 'Intoxicacion',
          type: BattlerStatusType.debuff,
          icon: Icons.science_rounded,
          description:
              'Al final del turno del objetivo, este estado inflige dano fijo igual a su value y renueva su duracion.',
          remainingTurns: remainingTurns,
          value: value,
        );

  @override
  bool get isIndefinite => true;

  int currentDamage(Battler owner) => resolved(owner).value;

  @override
  String descriptionFor(Battler owner) {
    return '$description Dano actual: ${currentDamage(owner)}';
  }

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

  @override
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

    return owner
        .applyStatus(
          renewedStatus,
          applyEquipmentModifiers: false,
        )
        .receiveDebuffDamage(
          currentStatus.value,
          source: opponent,
        );
  }
}

class CatalisisCruelStatus extends BattlerStatus {
  const CatalisisCruelStatus({
    int value = 2,
  }) : super(
          id: 'catalisis_cruel',
          name: 'Catalisis Cruel',
          type: BattlerStatusType.debuff,
          icon: Icons.biotech_rounded,
          description:
              'La proxima desventaja recibida multiplica su valor y consume este estado. Volver a aplicarlo acumula multiplicador.',
          remainingTurns: 1,
          value: value,
        );

  @override
  bool get isIndefinite => true;

  @override
  String descriptionFor(Battler owner) {
    return '$description Multiplicador actual: x$value';
  }

  @override
  BattlerStatus copyWith({
    int? remainingTurns,
    int? value,
  }) {
    return CatalisisCruelStatus(
      value: value ?? this.value,
    );
  }

  @override
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

class FragilidadStatus extends BattlerStatus {
  static const statusId = 'fragilidad';
  static const defaultDuration = 3;

  const FragilidadStatus({
    int remainingTurns = defaultDuration,
    int? value,
  }) : super(
          id: statusId,
          name: 'Fragilidad',
          type: BattlerStatusType.debuff,
          icon: Icons.shield_outlined,
          description:
              'Reduce la defensa actual en funcion de su duracion restante.',
          remainingTurns: remainingTurns,
          value: value ?? remainingTurns,
        );

  @override
  int resolveValue(Battler owner) => remainingTurns;

  @override
  String descriptionFor(Battler owner) {
    return '$description Defensa actual: -${resolved(owner).value}';
  }

  @override
  int modifyCalculatedStat({
    required Battler owner,
    required BattlerStat stat,
    required int value,
  }) {
    if (stat != BattlerStat.defense) return value;

    return max(0, value - resolved(owner).value);
  }

  @override
  BattlerStatus copyWith({
    int? remainingTurns,
    int? value,
  }) {
    final nextRemainingTurns = remainingTurns ?? this.remainingTurns;
    return FragilidadStatus(
      remainingTurns: nextRemainingTurns,
      value: value ?? nextRemainingTurns,
    );
  }
}

class InterferenciaStatus extends BattlerStatus {
  static const statusId = 'interferencia';
  static const defaultDuration = 1;

  const InterferenciaStatus({
    int remainingTurns = defaultDuration,
    int? value,
  }) : super(
          id: statusId,
          name: 'Interferencia',
          type: BattlerStatusType.debuff,
          icon: Icons.portable_wifi_off_rounded,
          description:
              'Impide activar habilidades manuales mientras permanezca activo.',
          remainingTurns: remainingTurns,
          value: value ?? remainingTurns,
        );

  @override
  int resolveValue(Battler owner) => remainingTurns;

  @override
  String? manualAbilityActivationBlockReason({
    required Battler owner,
    required BattlerAbilityActivationContext screenContext,
  }) {
    return 'Interferencia activa: no puedes usar habilidades manuales';
  }

  @override
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

class BlindajeTemporalStatus extends BattlerStatus {
  static const statusId = 'blindaje_temporal';
  static const defaultValue = 4;

  const BlindajeTemporalStatus({
    int value = defaultValue,
  }) : super(
          id: statusId,
          name: 'Blindaje Temporal',
          type: BattlerStatusType.buff,
          icon: Icons.health_and_safety_rounded,
          description:
              'Absorbe dano del siguiente impacto directo y desaparece al agotarse o al terminar el combate.',
          remainingTurns: 1,
          value: value,
        );

  @override
  bool get isIndefinite => true;

  @override
  bool get persistsOutsideCombat => false;

  @override
  String descriptionFor(Battler owner) {
    return '$description Absorcion restante: $value';
  }

  @override
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
    return BlindajeTemporalStatus(
      value: value ?? this.value,
    );
  }
}

class ConmocionStatus extends BattlerStatus {
  static const statusId = 'conmocion';
  static const defaultValue = 2;

  const ConmocionStatus({
    int value = defaultValue,
  }) : super(
          id: statusId,
          name: 'Conmocion',
          type: BattlerStatusType.debuff,
          icon: Icons.flash_off_rounded,
          description:
              'Reduce el dano del siguiente ataque del portador y luego desaparece.',
          remainingTurns: 1,
          value: value,
        );

  @override
  bool get isIndefinite => true;

  @override
  int modifyOutgoingDamage({
    required Battler owner,
    required Battler target,
    required int damage,
  }) {
    return max(0, damage - value);
  }

  @override
  Battler onAttackResolved({
    required Battler owner,
    required Battler target,
    required int damageDealt,
  }) {
    return owner.removeStatusInstance(this);
  }

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

class EscudoDeEnergiaStatus extends BattlerStatus {
  static const statusId = 'escudo_energia';
  static const defaultValue = 1;

  const EscudoDeEnergiaStatus({
    int value = defaultValue,
  }) : super(
          id: statusId,
          name: 'Escudo de Energia',
          type: BattlerStatusType.buff,
          icon: Icons.bolt_rounded,
          description:
              'Reduce el dano directo recibido, pero amplifica el dano de debuffs.',
          remainingTurns: 1,
          value: value,
        );

  @override
  bool get isIndefinite => true;

  @override
  BattlerIncomingDamageResolution onIncomingDamage({
    required Battler owner,
    required Battler source,
    required int damage,
    required DamageKind kind,
  }) {
    final updatedDamage =
        kind == DamageKind.direct ? max(0, damage - value) : damage + value;

    return BattlerIncomingDamageResolution(
      owner: owner,
      damage: updatedDamage,
    );
  }

  @override
  BattlerStatus copyWith({
    int? remainingTurns,
    int? value,
  }) {
    return EscudoDeEnergiaStatus(
      value: value ?? this.value,
    );
  }
}

class EscudoDeFaseStatus extends BattlerStatus {
  static const statusId = 'escudo_fase';
  static const defaultValue = 1;

  const EscudoDeFaseStatus({
    int value = defaultValue,
  }) : super(
          id: statusId,
          name: 'Escudo de Fase',
          type: BattlerStatusType.buff,
          icon: Icons.blur_on_rounded,
          description:
              'Reduce el dano de debuffs recibidos, pero amplifica los impactos directos.',
          remainingTurns: 1,
          value: value,
        );

  @override
  bool get isIndefinite => true;

  @override
  BattlerIncomingDamageResolution onIncomingDamage({
    required Battler owner,
    required Battler source,
    required int damage,
    required DamageKind kind,
  }) {
    final updatedDamage =
        kind == DamageKind.debuff ? max(0, damage - value) : damage + value;

    return BattlerIncomingDamageResolution(
      owner: owner,
      damage: updatedDamage,
    );
  }

  @override
  BattlerStatus copyWith({
    int? remainingTurns,
    int? value,
  }) {
    return EscudoDeFaseStatus(
      value: value ?? this.value,
    );
  }
}

class InerciaStatus extends BattlerStatus {
  static const statusId = 'inercia';
  static const defaultValue = 1;

  const InerciaStatus({
    int value = defaultValue,
  }) : super(
          id: statusId,
          name: 'Inercia',
          type: BattlerStatusType.buff,
          icon: Icons.motion_photos_on_rounded,
          description:
              'Si no activas habilidades manuales en tu turno, genera una reserva temporal aleatoria de ATK o DEF.',
          remainingTurns: 1,
          value: value,
        );

  @override
  bool get isIndefinite => true;

  @override
  String descriptionFor(Battler owner) {
    return '$description Valor por acumulacion: +$value';
  }

  @override
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
        : InerciaDefensaStatus(value: value);

    return owner.applyStatus(
      generatedStatus,
      applyEquipmentModifiers: false,
    );
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
    return InerciaStatus(
      value: value ?? this.value,
    );
  }
}

class InerciaAtaqueStatus extends BattlerStatus {
  static const statusId = 'inercia_ataque';

  const InerciaAtaqueStatus({
    int value = 1,
  }) : super(
          id: statusId,
          name: 'Reserva de Inercia: ATK',
          type: BattlerStatusType.buff,
          icon: Icons.north_rounded,
          description:
              'Bonus temporal de ataque acumulado por Inercia hasta el final del combate.',
          remainingTurns: 1,
          value: value,
        );

  @override
  bool get isIndefinite => true;

  @override
  bool get persistsOutsideCombat => false;

  @override
  int modifyCalculatedStat({
    required Battler owner,
    required BattlerStat stat,
    required int value,
  }) {
    if (stat != BattlerStat.attack) return value;

    return value + this.value;
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
    return InerciaAtaqueStatus(
      value: value ?? this.value,
    );
  }
}

class InerciaDefensaStatus extends BattlerStatus {
  static const statusId = 'inercia_defensa';

  const InerciaDefensaStatus({
    int value = 1,
  }) : super(
          id: statusId,
          name: 'Reserva de Inercia: DEF',
          type: BattlerStatusType.buff,
          icon: Icons.shield_rounded,
          description:
              'Bonus temporal de defensa acumulado por Inercia hasta el final del combate.',
          remainingTurns: 1,
          value: value,
        );

  @override
  bool get isIndefinite => true;

  @override
  bool get persistsOutsideCombat => false;

  @override
  int modifyCalculatedStat({
    required Battler owner,
    required BattlerStat stat,
    required int value,
  }) {
    if (stat != BattlerStat.defense) return value;

    return value + this.value;
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
    return InerciaDefensaStatus(
      value: value ?? this.value,
    );
  }
}

class DeudaStatus extends BattlerStatus {
  static const statusId = 'deuda';
  static const defaultValue = 8;

  const DeudaStatus({
    int value = defaultValue,
  }) : super(
          id: statusId,
          name: 'Deuda',
          type: BattlerStatusType.debuff,
          icon: Icons.receipt_long_rounded,
          description:
              'Limita el income efectivo a 1 hasta saldarse. No puede purgarse de forma convencional.',
          remainingTurns: 1,
          value: value,
        );

  @override
  bool get isIndefinite => true;

  @override
  bool get isPurgeable => false;

  @override
  int modifyIncome({
    required Battler owner,
    required int income,
  }) {
    return min(income, 1);
  }

  @override
  String descriptionFor(Battler owner) {
    final potentialIncome = owner.baseIncome +
        owner.equippedItems.fold<int>(
          0,
          (total, item) => total + item.incomeModifier,
        );
    final blockedIncome = max(0, potentialIncome - owner.income);
    return '$description Saldo pendiente: $value. Income retenido actualmente: +$blockedIncome.';
  }

  DeudaStatus registerPayment(int payment) {
    return copyWith(value: max(0, value - max(0, payment))) as DeudaStatus;
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
      owner: owner,
      appliedStatus: this,
    );
  }

  @override
  BattlerStatus copyWith({
    int? remainingTurns,
    int? value,
  }) {
    return DeudaStatus(
      value: value ?? this.value,
    );
  }
}
