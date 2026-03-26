import '_imports.dart';

enum BattlerStatusType {
  buff,
  debuff,
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

  Battler onTurnStart({
    required Battler owner,
    required Battler opponent,
    required bool isOwnerTurn,
  }) {
    return owner;
  }

  Battler onTurnEnd({
    required Battler owner,
    required Battler opponent,
    required bool isOwnerTurn,
  }) {
    return owner;
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
  }) {
    if (!isOwnerTurn) return owner;

    final currentStatus = resolved(owner);
    return owner.applyStatus(
      currentStatus.copyWith(value: currentStatus.value + 1),
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
  }) {
    if (!isOwnerTurn) return owner;

    final currentStatus = resolved(owner);
    return owner.receiveDamage(currentStatus.value);
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
  }) {
    if (!isOwnerTurn) return owner;

    final currentStatus = resolved(owner);
    final renewedStatus = currentStatus.copyWith(
      remainingTurns: currentStatus.remainingTurns + 1,
    );

    return owner.applyStatus(renewedStatus).receiveDamage(currentStatus.value);
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
