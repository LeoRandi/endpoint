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
  final int totalDuration;
  final int remainingTurns;

  const BattlerStatus({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.description,
    required this.totalDuration,
    required this.remainingTurns,
  })  : assert(totalDuration > 0),
        assert(remainingTurns >= 0),
        assert(remainingTurns <= totalDuration);

  bool get isExpired => remainingTurns <= 0;

  int get activeTurnCount => min(
        totalDuration,
        max(1, totalDuration - remainingTurns + 1),
      );

  String get remainingTurnsLabel {
    if (remainingTurns == 1) return '1 turno';
    return '$remainingTurns turnos';
  }

  String descriptionFor(Battler owner) => description;

  BattlerStatus copyWith({
    int? remainingTurns,
  });

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
}

class CalentandoStatus extends BattlerStatus {
  static const defaultDuration = 5;

  const CalentandoStatus({
    int remainingTurns = defaultDuration,
  }) : super(
          id: 'calentando',
          name: 'Calentando',
          type: BattlerStatusType.buff,
          icon: Icons.local_fire_department_rounded,
          description:
              'El usuario hace 1 mas de dano por cada turno que este activo este efecto.',
          totalDuration: defaultDuration,
          remainingTurns: remainingTurns,
        );

  int currentDamageBonus(Battler owner) => activeTurnCount;

  @override
  String descriptionFor(Battler owner) {
    return '$description Dano actual: +${currentDamageBonus(owner)}';
  }

  @override
  BattlerStatus copyWith({
    int? remainingTurns,
  }) {
    return CalentandoStatus(
      remainingTurns: remainingTurns ?? this.remainingTurns,
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
}
