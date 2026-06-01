part of '../battler_status.dart';

/// Buff ofensivo que potencia el siguiente ataque y luego se consume.
class CalentandoStatus extends BattlerStatus {
  static const statusId = BattlerStatusId.calentando;
  static const defaultDuration = 1;
  static const defaultValue = 1;

  /// Crea una instancia de Calentando con su bonus inicial.
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
            BattlerStatusHook.attackResolved,
            BattlerStatusHook.combatEnd,
          },
          icon: Icons.local_fire_department_rounded,
          description:
              'El usuario suma su value al daño del siguiente ataque y luego se consume.',
          remainingTurns: remainingTurns,
          value: value,
        );

  @override

  /// Calentando no expira por turnos, solo por ataque o fin de combate.
  bool get isIndefinite => true;

  @override

  /// Calentando solo tiene sentido durante combate.
  bool get persistsOutsideCombat => false;

  /// Devuelve el bonus de daño efectivo que tiene ahora mismo este estado.
  int currentDamageBonus(Battler owner) => resolved(owner).value;

  @override

  /// Muestra el valor que se sumara al siguiente ataque.
  String badgeLabelFor(Battler owner) => '${currentDamageBonus(owner)}';

  @override

  /// Anade a la descripcion el bonus de daño actual ya resuelto.
  String descriptionFor(Battler owner) {
    return '$description Daño del siguiente ataque: +${currentDamageBonus(owner)}';
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

  /// Consume Calentando despues de resolver cualquier ataque del portador.
  Battler onAttackResolved({
    required Battler owner,
    required Battler target,
    required int damageDealt,
  }) {
    return owner.removeStatusInstance(this);
  }

  @override

  /// Calentando es un boost exclusivamente de combate y desaparece al salir.
  Battler onCombatEnd({
    required Battler owner,
  }) {
    return owner.removeStatusInstance(this);
  }
}

/// Buff explosivo que aumenta los golpes durante el combate.
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
            BattlerStatusHook.statusApplied,
          },
          icon: Icons.bolt_rounded,
          description:
              'Aumenta el dano de tus golpes en su value durante este combate.',
          remainingTurns: 1,
          value: value,
        );

  @override

  /// Hace que Potencia dure hasta que termine el combate.
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

  /// Suma su bonus a los golpes del portador.
  int modifyOutgoingDamage({
    required Battler owner,
    required Battler target,
    required int damage,
  }) {
    return damage + resolved(owner).value;
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

/// Buff defensivo que hace fallar los ataques enemigos contra el portador.
class PuntoCiegoStatus extends BattlerStatus {
  static const statusId = BattlerStatusId.puntoCiego;

  /// Crea una instancia de Punto Ciego con duracion ajustada al ciclo de turnos.
  const PuntoCiegoStatus({
    int remainingTurns = 2,
    int value = 1,
  }) : super(
          id: statusId,
          name: 'Punto Ciego',
          type: BattlerStatusType.buff,
          tags: _buffStatusTags,
          icon: Icons.visibility_off_rounded,
          description:
              'Los ataques enemigos fallan contra el portador mientras permanezca activo.',
          remainingTurns: remainingTurns,
          value: value,
        );

  @override
  bool get persistsOutsideCombat => false;

  @override
  String descriptionFor(Battler owner) {
    return '$description Turnos protegidos: $value';
  }

  @override
  BattlerStatus copyWith({
    int? remainingTurns,
    int? value,
  }) {
    return PuntoCiegoStatus(
      remainingTurns: remainingTurns ?? this.remainingTurns,
      value: value ?? this.value,
    );
  }
}

/// Buff ofensivo que guarda un golpe extra para antes del siguiente ataque.
class DesafioStatus extends BattlerStatus {
  static const statusId = BattlerStatusId.desafio;

  /// Crea una reserva de Desafio acumulable hasta que el portador ataque.
  const DesafioStatus({
    int value = 1,
  }) : super(
          id: statusId,
          name: 'Desafio',
          type: BattlerStatusType.buff,
          tags: _buffDesafioStatusTags,
          hooks: const {
            BattlerStatusHook.statusApplied,
            BattlerStatusHook.combatEnd,
          },
          icon: Icons.sports_mma_rounded,
          description:
              'Antes del siguiente ataque, se consume e inflige un golpe directo igual a su value. Si permanece hasta el final del combate, cura el doble de su value.',
          remainingTurns: 1,
          value: value,
        );

  @override
  bool get isIndefinite => true;

  @override
  bool get persistsOutsideCombat => false;

  @override
  String descriptionFor(Battler owner) {
    final amount = resolved(owner).value;
    return '$description Desafio actual: $amount. Cura al final: ${amount * 2}.';
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
  Battler onCombatEnd({
    required Battler owner,
  }) {
    final ownerWithoutStatus = owner.removeStatusInstance(this);
    if (owner.isDefeated || value <= 0) return ownerWithoutStatus;

    return ownerWithoutStatus.heal(value * 2);
  }

  @override
  BattlerStatus copyWith({
    int? remainingTurns,
    int? value,
  }) {
    return DesafioStatus(
      value: value ?? this.value,
    );
  }
}

/// Buff temporal que aumenta los Desafios ganados durante este combate.
class DesafioExcitanteStatus extends BattlerStatus {
  static const statusId = BattlerStatusId.desafioExcitante;

  /// Crea una mejora acumulada para los siguientes Desafios del combate.
  const DesafioExcitanteStatus({
    int value = 1,
  }) : super(
          id: statusId,
          name: 'Desafio Excitante',
          type: BattlerStatusType.buff,
          tags: _buffDesafioStatusTags,
          hooks: const {
            BattlerStatusHook.statusApplied,
            BattlerStatusHook.combatEnd,
          },
          icon: Icons.local_activity_rounded,
          description:
              'Durante este combate, cada nuevo Desafio gana value adicional.',
          remainingTurns: 1,
          value: value,
        );

  @override
  bool get isIndefinite => true;

  @override
  bool get persistsOutsideCombat => false;

  @override
  String descriptionFor(Battler owner) {
    return '$description Bonus actual: +${resolved(owner).value}.';
  }

  @override
  BattlerStatusApplicationResolution onStatusApplied({
    required Battler owner,
    required BattlerStatus appliedStatus,
  }) {
    if (appliedStatus.id == id) {
      return BattlerStatusApplicationResolution(
        owner: owner.removeStatusInstance(this),
        appliedStatus: copyWith(value: value + appliedStatus.value),
      );
    }

    if (appliedStatus.id != DesafioStatus.statusId) {
      return BattlerStatusApplicationResolution(
        owner: owner,
        appliedStatus: appliedStatus,
      );
    }

    return BattlerStatusApplicationResolution(
      owner: owner,
      appliedStatus: appliedStatus.copyWith(
        value: appliedStatus.value + value,
      ),
    );
  }

  @override
  Battler onCombatEnd({
    required Battler owner,
  }) {
    return owner.removeStatusInstance(this);
  }

  @override
  BattlerStatus copyWith({
    int? remainingTurns,
    int? value,
  }) {
    return DesafioExcitanteStatus(
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

class CompensadorRutaStatus extends BattlerStatus {
  static const statusId = BattlerStatusId.compensadorRuta;
  final BattlerStat stat;

  const CompensadorRutaStatus({
    required this.stat,
    int value = 1,
  }) : super(
          id: statusId,
          name: 'Compensador de Ruta',
          type: BattlerStatusType.buff,
          tags: _buffAtaqueStatusTags,
          hooks: const {
            BattlerStatusHook.calculatedStatModifier,
            BattlerStatusHook.combatEnd,
          },
          icon: Icons.route_rounded,
          description:
              'Aumenta temporalmente la stat menos cubierta por tus items.',
          remainingTurns: 1,
          value: value,
        );

  @override
  bool get isIndefinite => true;

  @override
  bool get persistsOutsideCombat => false;

  @override
  String descriptionFor(Battler owner) {
    return '$description Bonus actual: +$value ${stat.shortLabel}.';
  }

  @override
  int modifyCalculatedStat({
    required Battler owner,
    required BattlerStat stat,
    required int value,
  }) {
    if (stat != this.stat) return value;
    return value + this.value;
  }

  @override
  Battler onCombatEnd({
    required Battler owner,
  }) {
    return owner.removeStatusInstance(this);
  }

  @override
  BattlerStatus copyWith({
    int? remainingTurns,
    int? value,
  }) {
    return CompensadorRutaStatus(
      stat: stat,
      value: value ?? this.value,
    );
  }
}

class MercadoFuturosStatus extends BattlerStatus {
  static const statusId = BattlerStatusId.mercadoFuturos;
  final int attack;
  final int barrier;

  const MercadoFuturosStatus({
    this.attack = 1,
    this.barrier = 1,
  }) : super(
          id: statusId,
          name: 'Mercado de Futuros',
          type: BattlerStatusType.buff,
          tags: _buffAtaqueStatusTags,
          hooks: const {
            BattlerStatusHook.calculatedStatModifier,
            BattlerStatusHook.combatEnd,
          },
          icon: Icons.monetization_on_rounded,
          description: 'Contrato de suerte activo para el siguiente combate.',
          remainingTurns: 1,
          value: 1,
        );

  @override
  bool get isIndefinite => true;

  @override
  bool get persistsOutsideCombat => false;

  @override
  String descriptionFor(Battler owner) {
    return '$description Bonus actual: +$attack ATK, +$barrier BAR.';
  }

  @override
  int modifyCalculatedStat({
    required Battler owner,
    required BattlerStat stat,
    required int value,
  }) {
    return switch (stat) {
      BattlerStat.attack => value + attack,
      BattlerStat.barrier => value + barrier,
      _ => value,
    };
  }

  @override
  Battler onCombatEnd({
    required Battler owner,
  }) {
    return owner.removeStatusInstance(this);
  }

  @override
  BattlerStatus copyWith({
    int? remainingTurns,
    int? value,
  }) {
    return MercadoFuturosStatus(
      attack: attack,
      barrier: barrier,
    );
  }
}
