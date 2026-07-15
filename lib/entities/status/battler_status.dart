import '_imports.dart';

part 'battler_statuses/battler_status_buffs.dart';
part 'battler_statuses/battler_status_debuffs.dart';

/// Distingue si un estado es favorable o perjudicial para su portador.
enum BattlerStatusType {
  buff,
  debuff,
}

/// Distingue si el daño viene de un golpe directo o de un efecto de estado.
enum DamageKind {
  direct,
  debuff,
  burn,
  desafioCounter,
}

/// Enumera las identidades estables de los estados para evitar lookups por texto.
enum BattlerStatusId {
  calentando,
  potencia,
  quemadura,
  intoxicacion,
  contagio,
  fragilidad,
  conmocion,
  resonancia,
  puntoCiego,
  desafio,
  compensadorRuta,
  mercadoFuturos,
}

/// Enumera los puntos del ciclo de combate en los que un estado puede intervenir.
enum BattlerStatusHook {
  incomeModifier,
  calculatedStatModifier,
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

/// Agrupa el estado del portador y el daño final tras procesar hooks defensivos.
class BattlerIncomingDamageResolution {
  final Battler owner;
  final int damage;

  /// Crea una resolucion inmutable con el daño ya ajustado.
  const BattlerIncomingDamageResolution({
    required this.owner,
    required this.damage,
  });
}

/// Sirve como base comun para todos los estados y sus hooks de combate.
abstract class BattlerStatus {
  final BattlerStatusId id;
  final String name;
  final BattlerStatusType type;
  final List<EntityTag> tags;
  final Set<BattlerStatusHook> hooks;
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

  /// Resuelve efectos que deben ocurrir al inicio de turno.
  Battler onTurnStart({
    required Battler owner,
    required Battler opponent,
    required bool isOwnerTurn,
    RandomSource? randomizer,
  }) {
    return owner;
  }

  /// Resuelve efectos que deben ocurrir al final de turno.
  Battler onTurnEnd({
    required Battler owner,
    required Battler opponent,
    required bool isOwnerTurn,
    RandomSource? randomizer,
  }) {
    return owner;
  }

  /// Resuelve efectos puntuales al terminar el combate antes de limpiar estado runtime.
  Battler onCombatEnd({
    required Battler owner,
  }) {
    return owner;
  }

  /// Permite absorber o modificar daño entrante segun su tipo.
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

  /// Permite ajustar el daño saliente del portador.
  int modifyOutgoingDamage({
    required Battler owner,
    required Battler target,
    required int damage,
  }) {
    return damage;
  }

  /// Permite ajustar el daño entrante del portador.
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

  /// Resuelve efectos posteriores a que el portador reciba daño.
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
const _buffStatusTags = <EntityTag>[
  EntityTag.buff,
];
const _debuffQuemaduraStatusTags = <EntityTag>[
  EntityTag.debuff,
  EntityTag.quemadura,
];
const _debuffIntoxicacionStatusTags = <EntityTag>[
  EntityTag.debuff,
  EntityTag.intoxicacion,
];
const _debuffContagioStatusTags = <EntityTag>[
  EntityTag.debuff,
  EntityTag.contagio,
];
const _debuffStatusTags = <EntityTag>[
  EntityTag.debuff,
];
const _buffResonanciaStatusTags = <EntityTag>[
  EntityTag.buff,
  EntityTag.resonancia,
];
const _buffDesafioStatusTags = <EntityTag>[
  EntityTag.buff,
  EntityTag.desafio,
];
const _debuffAtaqueStatusTags = <EntityTag>[
  EntityTag.debuff,
  EntityTag.ataque,
];
