import 'battler/_exports.dart';
import 'status/_exports.dart';

/// Resume si los efectos de Ciclo deben contar como dia, noche o ambos.
class CycleContext {
  final bool isDay;
  final bool isNight;

  /// Crea un contexto de Ciclo para resolver efectos dependientes de hora.
  ///
  /// `isDay` y `isNight` pueden estar activos a la vez cuando un estado fuerza
  /// que los bonus de ambos lados del ciclo se apliquen.
  const CycleContext({
    this.isDay = false,
    this.isNight = false,
  });

  /// Indica si algun lado del ciclo esta disponible para efectos activos.
  bool get isActive => isDay || isNight;

  /// Indica si el owner cuenta simultaneamente como dia y noche.
  bool get isDual => isDay && isNight;
}

const CycleContext _inactiveCycleContext = CycleContext();
const CycleContext _dualCycleContext = CycleContext(
  isDay: true,
  isNight: true,
);

/// Resuelve el contexto efectivo de Ciclo para items en combate.
///
/// La prioridad es intencional: sin combate no hay ciclo; Ciclo Eclipse gana a
/// todo; y por ultimo se respetan las flags genericas del battler.
CycleContext cycleContextFor(Battler owner) {
  final isCombatActive = owner.combatFlags.contains(Battler.combatActiveFlag);
  if (!isCombatActive) {
    return _inactiveCycleContext;
  }

  final hasCycleEclipse = owner.statuses.any(
    (status) => status.id == CicloEclipseStatus.statusId,
  );
  if (hasCycleEclipse) {
    return _dualCycleContext;
  }

  final hasDayContext = owner.combatFlags.contains(Battler.cycleDayContextFlag);
  final hasNightContext =
      owner.combatFlags.contains(Battler.cycleNightContextFlag);
  if (hasDayContext || hasNightContext) {
    return CycleContext(
      isDay: hasDayContext,
      isNight: hasNightContext,
    );
  }

  return _inactiveCycleContext;
}
