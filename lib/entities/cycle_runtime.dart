import 'battler/_exports.dart';
import 'item/_exports.dart';
import 'status/_exports.dart';

/// Resume si los efectos de Ciclo deben contar como dia, noche o ambos.
class CycleContext {
  final bool isDay;
  final bool isNight;

  const CycleContext({
    this.isDay = false,
    this.isNight = false,
  });

  bool get isActive => isDay || isNight;
  bool get isDual => isDay && isNight;
}

const CycleContext _inactiveCycleContext = CycleContext();
const CycleContext _dayCycleContext = CycleContext(isDay: true);
const CycleContext _nightCycleContext = CycleContext(isNight: true);
const CycleContext _dualCycleContext = CycleContext(
  isDay: true,
  isNight: true,
);

/// Resuelve el contexto efectivo de Ciclo para items y habilidades en combate.
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

  final forcesDay =
      _hasActiveAbility(owner, BattlerAbilityId.amanecerSintetico);
  final forcesNight = _hasActiveAbility(owner, BattlerAbilityId.lunaArtificial);
  if (forcesDay || forcesNight) {
    return CycleContext(
      isDay: forcesDay,
      isNight: forcesNight,
    );
  }

  Item? eclipseMantle;
  for (final item in owner.equippedItems) {
    if (item.id == ItemId.eclipseMantle) {
      eclipseMantle = item;
      break;
    }
  }
  if (eclipseMantle != null) {
    final nightFlag = CombatRuntimeFlag.item(
      itemFlag: ItemCombatFlagKind.eclipseMantleNightMode,
      itemId: eclipseMantle.id,
      itemInstanceId: eclipseMantle.instanceId,
    );
    if (owner.combatFlags.contains(nightFlag)) {
      return _nightCycleContext;
    }
    return _dayCycleContext;
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

bool _hasActiveAbility(Battler owner, BattlerAbilityId abilityId) {
  for (final ability in owner.abilities) {
    if (ability.id == abilityId && ability.isActive) {
      return true;
    }
  }
  return false;
}
