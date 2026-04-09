import '../_imports.dart';
import '../../services/run_randomizer.dart';

/// Distingue si un estado es favorable o perjudicial para su portador.
enum BattlerStatusType {
  buff,
  debuff,
}

/// Distingue si el dano viene de un golpe directo o de un efecto de estado.
enum DamageKind {
  direct,
  debuff,
}

/// Enumera las identidades estables de los estados para evitar lookups por texto.
enum BattlerStatusId {
  calentando,
  quemadura,
  intoxicacion,
  catalisisCruel,
  fragilidad,
  interferencia,
  blindajeTemporal,
  conmocion,
  inercia,
  inerciaAtaque,
  inerciaBarrera,
  deuda,
}

/// Enumera los puntos del ciclo de combate en los que un estado puede intervenir.
enum BattlerStatusHook {
  incomeModifier,
  calculatedStatModifier,
  manualAbilityActivationBlocker,
  turnStart,
  turnEnd,
  combatEnd,
  incomingDamageEffect,
  outgoingDamageModifier,
  incomingDamageModifier,
  attackResolved,
  receiveDamageResolved,
  statusApplied,
}

/// Agrupa el estado del portador y el dano final tras procesar hooks defensivos.
class BattlerIncomingDamageResolution {
  final Battler owner;
  final int damage;

  /// Crea una resolucion inmutable con el dano ya ajustado.
  const BattlerIncomingDamageResolution({
    required this.owner,
    required this.damage,
  });
}

/// Expone etiquetas y colores coherentes para representar tipos de estado en la UI.
extension BattlerStatusTypePresentation on BattlerStatusType {
  /// Devuelve el nombre corto que se muestra junto al estado.
  String get label {
    switch (this) {
      case BattlerStatusType.buff:
        return 'Buff';
      case BattlerStatusType.debuff:
        return 'Debuff';
    }
  }

  /// Devuelve el color principal usado para resaltar este tipo de estado.
  Color get accent {
    switch (this) {
      case BattlerStatusType.buff:
        return const Color(0xFF5AF78E);
      case BattlerStatusType.debuff:
        return const Color(0xFFFF6B6B);
    }
  }

  /// Devuelve el color de texto que mejor contrasta con el accent del tipo.
  Color get foreground {
    switch (this) {
      case BattlerStatusType.buff:
        return const Color(0xFFE6FFF0);
      case BattlerStatusType.debuff:
        return const Color(0xFFFFE3E3);
    }
  }
}

/// Sirve como base comun para todos los estados y sus hooks de combate.
abstract class BattlerStatus {
  final BattlerStatusId id;
  final String name;
  final BattlerStatusType type;
  final List<EntityTag> tags;
  final Set<BattlerStatusHook> hooks;
  final IconData icon;
  final String description;
  final int remainingTurns;
  final int value;

  /// Crea un estado inmutable con su identidad, texto y valores runtime.
  const BattlerStatus({
    required this.id,
    required this.name,
    required this.type,
    this.tags = const [],
    this.hooks = const <BattlerStatusHook>{},
    required this.icon,
    required this.description,
    required this.remainingTurns,
    this.value = 0,
  }) : assert(remainingTurns >= 0);

  /// Indica si este estado ignora el contador de turnos y dura hasta otro evento.
  bool get isIndefinite => false;

  /// Indica si varias copias de este estado pueden convivir a la vez.
  bool get canStack => false;

  /// Indica si efectos de purga convencionales pueden eliminar este estado.
  bool get isPurgeable => true;

  /// Indica si el estado debe conservarse al salir del combate.
  bool get persistsOutsideCombat => true;

  /// Indica si el estado ya no debe seguir en la lista activa.
  bool get isExpired => !isIndefinite && remainingTurns <= 0;

  /// Indica si el estado tiene tags visibles o utiles para filtros.
  bool get hasTags => tags.isNotEmpty;

  /// Comprueba si el estado pertenece a una tag concreta.
  bool hasTag(EntityTag tag) => tags.contains(tag);

  /// Devuelve la duracion legible que muestra la interfaz.
  String get remainingTurnsLabel {
    if (isIndefinite) return 'Indefinido';
    if (remainingTurns == 1) return '1 turno';
    return '$remainingTurns turnos';
  }

  /// Devuelve el minitexto compacto que usan los badges de combate.
  /// Los estados indefinidos muestran su value efectivo porque ese es el
  /// numero relevante para leer su impacto de un vistazo.
  String badgeLabelFor(Battler owner) {
    if (isIndefinite) {
      return '${resolved(owner).value}';
    }

    return '$remainingTurns';
  }

  /// Clona el estado cambiando solo los campos runtime necesarios.
  BattlerStatus copyWith({
    int? remainingTurns,
    int? value,
  });

  /// Multiplica el value del estado cuando otro efecto pide amplificarlo.
  BattlerStatus amplifyValue(int factor) {
    if (factor <= 1) return this;

    return copyWith(value: value * factor);
  }

  /// Calcula el value efectivo del estado para este portador concreto.
  int resolveValue(Battler owner) => value;

  /// Devuelve una copia con el value ya resuelto para el estado actual del portador.
  BattlerStatus resolved(Battler owner) {
    final resolvedValue = resolveValue(owner);

    if (resolvedValue == value) {
      return this;
    }

    return copyWith(value: resolvedValue);
  }

  /// Devuelve la descripcion final mostrada en UI, pudiendo incluir valores runtime.
  String descriptionFor(Battler owner) => description;

  /// Permite que el estado ajuste el income efectivo del portador.
  int modifyIncome({
    required Battler owner,
    required int income,
  }) {
    return income;
  }

  /// Permite que el estado ajuste una stat calculada justo antes de usarla.
  int modifyCalculatedStat({
    required Battler owner,
    required BattlerStat stat,
    required int value,
  }) {
    return value;
  }

  /// Permite bloquear activaciones manuales y explicar el motivo en pantalla.
  String? manualAbilityActivationBlockReason({
    required Battler owner,
    required BattlerAbilityActivationContext screenContext,
  }) {
    return null;
  }

  /// Resuelve efectos que deben ocurrir al inicio de turno.
  Battler onTurnStart({
    required Battler owner,
    required Battler opponent,
    required bool isOwnerTurn,
    RunRandomizer? randomizer,
  }) {
    return owner;
  }

  /// Resuelve efectos que deben ocurrir al final de turno.
  Battler onTurnEnd({
    required Battler owner,
    required Battler opponent,
    required bool isOwnerTurn,
    RunRandomizer? randomizer,
  }) {
    return owner;
  }

  /// Resuelve efectos puntuales al terminar el combate antes de limpiar estado runtime.
  Battler onCombatEnd({
    required Battler owner,
  }) {
    return owner;
  }

  /// Permite absorber o modificar dano entrante segun su tipo.
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

  /// Permite ajustar el dano saliente del portador.
  int modifyOutgoingDamage({
    required Battler owner,
    required Battler target,
    required int damage,
  }) {
    return damage;
  }

  /// Permite ajustar el dano entrante del portador.
  int modifyIncomingDamage({
    required Battler owner,
    required Battler source,
    required int damage,
  }) {
    return damage;
  }

  /// Resuelve efectos posteriores a que el portador complete un ataque.
  Battler onAttackResolved({
    required Battler owner,
    required Battler target,
    required int damageDealt,
  }) {
    return owner;
  }

  /// Resuelve efectos posteriores a que el portador reciba dano.
  Battler onReceiveDamageResolved({
    required Battler owner,
    required Battler source,
    required int damageTaken,
  }) {
    return owner;
  }

  /// Decide como interactua este estado con otro estado que esta entrando.
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

/// Devuelve el portador actualizado y el estado final tras una aplicacion de estados.
class BattlerStatusApplicationResolution {
  final Battler owner;
  final BattlerStatus appliedStatus;

  /// Crea una resolucion inmutable para el pipeline de aplicacion de estados.
  const BattlerStatusApplicationResolution({
    required this.owner,
    required this.appliedStatus,
  });
}

const _buffAtaqueStatusTags = <EntityTag>[
  EntityTag.buff,
  EntityTag.ataque,
];
const _debuffQuemaduraStatusTags = <EntityTag>[
  EntityTag.debuff,
  EntityTag.quemadura,
];
const _debuffIntoxicacionStatusTags = <EntityTag>[
  EntityTag.debuff,
  EntityTag.intoxicacion,
];
const _debuffStatusTags = <EntityTag>[
  EntityTag.debuff,
];
const _debuffBarreraStatusTags = <EntityTag>[
  EntityTag.debuff,
  EntityTag.barrera,
];
const _buffBarreraStatusTags = <EntityTag>[
  EntityTag.buff,
  EntityTag.barrera,
];
const _debuffAtaqueStatusTags = <EntityTag>[
  EntityTag.debuff,
  EntityTag.ataque,
];
const _buffAtaqueBarreraStatusTags = <EntityTag>[
  EntityTag.buff,
  EntityTag.ataque,
  EntityTag.barrera,
];
const _debuffEconomiaStatusTags = <EntityTag>[
  EntityTag.debuff,
  EntityTag.economia,
];

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
              'Al final del turno del objetivo, este estado inflige dano fijo igual a su value y renueva su duracion.',
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

/// Debuff que reduce Barrera segun los turnos que le queden por delante.
class FragilidadStatus extends BattlerStatus {
  static const statusId = BattlerStatusId.fragilidad;
  static const defaultDuration = 3;

  /// Crea una instancia de Fragilidad cuya fuerza sigue la duracion restante.
  const FragilidadStatus({
    int remainingTurns = defaultDuration,
    int? value,
  }) : super(
          id: statusId,
          name: 'Fragilidad',
          type: BattlerStatusType.debuff,
          tags: _debuffBarreraStatusTags,
          hooks: const {
            BattlerStatusHook.calculatedStatModifier,
          },
          icon: Icons.shield_outlined,
          description:
              'Reduce la barrera actual en funcion de su duracion restante.',
          remainingTurns: remainingTurns,
          value: value ?? remainingTurns,
        );

  @override

  /// Hace que la reduccion real de barrera coincida con los turnos restantes.
  int resolveValue(Battler owner) => remainingTurns;

  @override

  /// Anade a la descripcion la reduccion efectiva de barrera.
  String descriptionFor(Battler owner) {
    return '$description Barrera actual: -${resolved(owner).value}';
  }

  @override

  /// Resta barrera al calcular esa stat concreta y nunca baja de cero.
  int modifyCalculatedStat({
    required Battler owner,
    required BattlerStat stat,
    required int value,
  }) {
    if (stat != BattlerStat.barrier) return value;

    return max(0, value - resolved(owner).value);
  }

  @override

  /// Clona el estado manteniendo sincronizados value y remainingTurns.
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
