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

  /// Calentando no expira por turnos, solo por ataque o fin de combate.
  @override
  bool get isIndefinite => true;

  /// Calentando solo tiene sentido durante combate.
  @override
  bool get persistsOutsideCombat => false;

  /// Devuelve el bonus de daño efectivo que tiene ahora mismo este estado.
  int currentDamageBonus(Battler owner) => resolved(owner).value;

  /// Muestra el valor que se sumara al siguiente ataque.
  @override
  String badgeLabelFor(Battler owner) => '${currentDamageBonus(owner)}';

  /// Anade a la descripcion el bonus de daño actual ya resuelto.
  @override
  String descriptionFor(Battler owner) {
    return '$description Daño del siguiente ataque: +${currentDamageBonus(owner)}';
  }

  /// Clona el estado manteniendo el tipo concreto de Calentando.
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

  /// Suma su bonus al daño de cada ataque del portador.
  @override
  int modifyOutgoingDamage({
    required Battler owner,
    required Battler target,
    required int damage,
  }) {
    return damage + currentDamageBonus(owner);
  }

  /// Consume Calentando despues de resolver cualquier ataque del portador.
  @override
  Battler onAttackResolved({
    required Battler owner,
    required Battler target,
    required int damageDealt,
  }) {
    return owner.removeStatusInstance(this);
  }

  /// Calentando es un boost exclusivamente de combate y desaparece al salir.
  @override
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

  /// Hace que Potencia dure hasta que termine el combate.
  @override
  bool get isIndefinite => true;

  /// Potencia solo tiene sentido durante combate y se limpia al salir.
  @override
  bool get persistsOutsideCombat => false;

  /// Anade a la descripcion el bonus de daño actual ya resuelto.
  @override
  String descriptionFor(Battler owner) {
    return '$description Daño extra actual: +${resolved(owner).value}';
  }

  /// Suma su bonus a los golpes del portador.
  @override
  int modifyOutgoingDamage({
    required Battler owner,
    required Battler target,
    required int damage,
  }) {
    return damage + resolved(owner).value;
  }

  /// Si vuelve a aplicarse, acumula el daño pendiente.
  @override
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
      appliedStatus: copyWith(
        value: value + appliedStatus.value,
      ),
    );
  }

  /// Clona el estado manteniendo su bonus pendiente.
  @override
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

  /// Hace que Eclipse Manual se limpie al terminar el combate.
  @override
  bool get persistsOutsideCombat => false;

  /// Clona el estado manteniendo duracion y valor de Eclipse Manual.
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

  /// Hace que Punto Ciego se limpie al terminar el combate.
  @override
  bool get persistsOutsideCombat => false;

  /// Explica cuanta proteccion visible conserva Punto Ciego.
  @override
  String descriptionFor(Battler owner) {
    return '$description Turnos protegidos: $value';
  }

  /// Clona el estado manteniendo duracion y valor defensivo.
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

  /// Hace que Desafio espere indefinidamente hasta ataque o fin de combate.
  @override
  bool get isIndefinite => true;

  /// Limpia Desafio al terminar el combate tras resolver su cura final.
  @override
  bool get persistsOutsideCombat => false;

  /// Explica el golpe reservado y la cura potencial si el combate termina.
  @override
  String descriptionFor(Battler owner) {
    final amount = resolved(owner).value;
    return '$description Desafio actual: $amount. Cura al final: ${amount * 2}.';
  }

  /// Acumula nuevas aplicaciones de Desafio en una unica reserva.
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

  /// Consume Desafio al cerrar combate y cura si el portador sigue vivo.
  @override
  Battler onCombatEnd({
    required Battler owner,
  }) {
    final ownerWithoutStatus = owner.removeStatusInstance(this);
    if (owner.isDefeated || value <= 0) return ownerWithoutStatus;

    return ownerWithoutStatus.heal(value * 2);
  }

  /// Clona Desafio manteniendo el golpe reservado.
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

  /// Hace que el bonus dure todo el combate hasta que se limpie explicitamente.
  @override
  bool get isIndefinite => true;

  /// Limpia Desafio Excitante al terminar el combate.
  @override
  bool get persistsOutsideCombat => false;

  /// Explica cuanto aumenta cada nuevo Desafio recibido.
  @override
  String descriptionFor(Battler owner) {
    return '$description Bonus actual: +${resolved(owner).value}.';
  }

  /// Acumula consigo mismo o mejora los Desafios entrantes.
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

  /// Elimina el bonus temporal al cerrar combate.
  @override
  Battler onCombatEnd({
    required Battler owner,
  }) {
    return owner.removeStatusInstance(this);
  }

  /// Clona el bonus manteniendo su acumulacion actual.
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

  /// Hace que Resonancia permanezca hasta ser consumida o limpiar el combate.
  @override
  bool get isIndefinite => true;

  /// Limpia Resonancia al terminar el combate.
  @override
  bool get persistsOutsideCombat => false;

  /// Explica la carga de Resonancia disponible para otros efectos.
  @override
  String descriptionFor(Battler owner) {
    return '$description Resonancia actual: ${resolved(owner).value}';
  }

  /// Acumula nuevas aplicaciones de Resonancia en una unica carga.
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

  /// Clona Resonancia manteniendo su carga acumulada.
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

  /// Crea una instancia de CompensadorRuta con sus valores actuales.
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

  /// Construye la descripcion visible del efecto usando el valor actual.
  @override
  String descriptionFor(Battler owner) {
    return '$description Bonus actual: +$value ${stat.shortLabel}.';
  }

  /// Ajusta una stat calculada mientras el efecto esta activo.
  @override
  int modifyCalculatedStat({
    required Battler owner,
    required BattlerStat stat,
    required int value,
  }) {
    if (stat != this.stat) return value;
    return value + this.value;
  }

  /// Limpia o transforma estado temporal al cerrar combate.
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

  /// Crea una instancia de MercadoFuturos con sus valores actuales.
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

  /// Construye la descripcion visible del efecto usando el valor actual.
  @override
  String descriptionFor(Battler owner) {
    return '$description Bonus actual: +$attack ATK, +$barrier BAR.';
  }

  /// Ajusta una stat calculada mientras el efecto esta activo.
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

  /// Limpia o transforma estado temporal al cerrar combate.
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
