import '../_imports.dart';

part 'item_effects/item_effect_attack_and_sustain.dart';
part 'item_effects/item_effect_reactive_defense.dart';
part 'item_effects/item_effect_specialized.dart';

/// Agrupa el estado final del portador y del rival tras resolver un efecto de item.
class ItemEffectResolution {
  final Battler owner;
  final Battler opponent;

  /// Crea una resolucion inmutable con ambos combatientes ya actualizados.
  const ItemEffectResolution({
    required this.owner,
    required this.opponent,
  });
}

/// Enumera los momentos en los que un item puede reaccionar a una habilidad.
enum ItemAbilityResolutionContext {
  manualActivation,
  attackResolved,
  receiveDamageResolved,
  turnStart,
  turnEnd,
}

/// Enumera los puntos del ciclo de combate en los que un item equipado puede intervenir.
enum ItemEffectHook {
  turnStart,
  turnEnd,
  combatEnd,
  outgoingDamageModifier,
  incomingDamageModifier,
  calculatedStatModifier,
  basicAttackCountModifier,
  attackResolved,
  receiveDamageResolved,
  passive,
  manualAbilityPreparation,
  abilityResolved,
  outgoingStatusModifier,
  incomingStatusModifier,
  fatalDamage,
}

/// Devuelve el estado resultante cuando un item modifica una activacion manual.
class ItemAbilityPreparationResolution {
  final Battler owner;
  final Battler opponent;
  final BattlerAbility ability;

  /// Crea una resolucion con el usuario, el rival y la habilidad ya ajustados.
  const ItemAbilityPreparationResolution({
    required this.owner,
    required this.opponent,
    required this.ability,
  });
}

/// Sirve como base comun para todos los hooks reactivos de los objetos equipados.
abstract class ItemEffect {
  final String description;
  final Set<ItemEffectHook> hooks;

  /// Crea un efecto reutilizable con la descripcion base del item.
  const ItemEffect({
    required this.description,
    this.hooks = const <ItemEffectHook>{},
  });

  /// Devuelve la descripcion mostrada por la UI, pudiendo usar el value del item.
  String descriptionFor(Item item) => description;

  /// Resuelve el efecto del item al inicio de turno.
  ItemEffectResolution onTurnStart({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required bool isOwnerTurn,
  }) {
    return ItemEffectResolution(owner: owner, opponent: opponent);
  }

  /// Resuelve el efecto del item al final de turno.
  ItemEffectResolution onTurnEnd({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required bool isOwnerTurn,
  }) {
    return ItemEffectResolution(owner: owner, opponent: opponent);
  }

  /// Resuelve efectos puntuales al terminar el combate antes de limpiar flags y cooldowns.
  Battler onCombatEnd({
    required Battler owner,
    required Item item,
  }) {
    return owner;
  }

  /// Ajusta el dano saliente del portador antes de que se aplique.
  int modifyOutgoingDamage({
    required Battler owner,
    required Battler target,
    required Item item,
    required int damage,
  }) {
    return damage;
  }

  /// Ajusta el dano entrante del portador antes de que se aplique.
  int modifyIncomingDamage({
    required Battler owner,
    required Battler source,
    required Item item,
    required int damage,
  }) {
    return damage;
  }

  /// Ajusta una stat ya calculada del portador para efectos persistentes de equipo.
  int modifyCalculatedStat({
    required Battler owner,
    required Item item,
    required BattlerStat stat,
    required int value,
  }) {
    return value;
  }

  /// Ajusta cuantas veces se resuelve una accion de ataque basico.
  int modifyBasicAttackCount({
    required Battler owner,
    required Item item,
    required int count,
  }) {
    return count;
  }

  /// Resuelve efectos posteriores a que el portador termine un ataque.
  ItemEffectResolution onAttackResolved({
    required Battler owner,
    required Battler target,
    required Item item,
    required int damageDealt,
  }) {
    return ItemEffectResolution(owner: owner, opponent: target);
  }

  /// Resuelve efectos posteriores a que el portador reciba dano.
  ItemEffectResolution onReceiveDamageResolved({
    required Battler owner,
    required Battler source,
    required Item item,
    required int damageTaken,
  }) {
    return ItemEffectResolution(owner: owner, opponent: source);
  }

  /// Aplica efectos pasivos que deben reevaluarse sin un disparador puntual.
  ItemEffectResolution applyPassive({
    required Battler owner,
    required Battler opponent,
    required Item item,
  }) {
    return ItemEffectResolution(owner: owner, opponent: opponent);
  }

  /// Permite modificar una habilidad justo antes de su activacion manual real.
  ItemAbilityPreparationResolution onManualAbilityPreparing({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required BattlerAbility ability,
    required BattlerAbilityActivationContext screenContext,
  }) {
    return ItemAbilityPreparationResolution(
      owner: owner,
      opponent: opponent,
      ability: ability,
    );
  }

  /// Reacciona a una habilidad ya resuelta para aplicar efectos posteriores.
  ItemEffectResolution onAbilityResolved({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required BattlerAbility previousAbility,
    required BattlerAbility resolvedAbility,
    required ItemAbilityResolutionContext context,
  }) {
    return ItemEffectResolution(owner: owner, opponent: opponent);
  }

  /// Permite alterar o cancelar un estado antes de aplicarlo al objetivo.
  BattlerStatus? modifyOutgoingStatus({
    required Battler owner,
    required Battler target,
    required Item item,
    required BattlerStatus status,
  }) {
    return status;
  }

  /// Permite alterar o cancelar un estado recibido antes de que se aplique.
  BattlerStatus? modifyIncomingStatus({
    required Battler owner,
    required Battler source,
    required Item item,
    required BattlerStatus status,
  }) {
    return status;
  }

  /// Permite interceptar un golpe letal justo antes de que el portador muera.
  Battler onReceiveFatalDamage({
    required Battler owner,
    required Item item,
    required int incomingDamage,
  }) {
    return owner;
  }
}

/// Comprueba si una habilidad ha pasado de estar lista a estar en cooldown.
bool _enteredCooldown(
  BattlerAbility previousAbility,
  BattlerAbility resolvedAbility,
) {
  return !previousAbility.isOnCooldown && resolvedAbility.isOnCooldown;
}

/// Recupera barrera sin sobrepasar la barrera maxima calculada del portador.
Battler _recoverBarrier({
  required Battler owner,
  required int amount,
}) {
  final safeAmount = max(0, amount);
  if (safeAmount <= 0 || owner.currentBarrier >= owner.maxBarrier) {
    return owner;
  }

  return owner.copyWith(
    currentBarrier: min(
      owner.maxBarrier,
      owner.currentBarrier + safeAmount,
    ),
  );
}

/// Refresca un Blindaje Temporal minimo sin acumularlo infinitamente.
Battler _refreshMinimumBlindajeTemporal({
  required Battler owner,
  required int value,
}) {
  final shieldValue = max(1, value);
  final currentShield = owner.statusById(BlindajeTemporalStatus.statusId);
  if (currentShield != null &&
      currentShield.resolved(owner).value >= shieldValue) {
    return owner;
  }

  final refreshedOwner = currentShield == null
      ? owner
      : owner.removeStatus(BlindajeTemporalStatus.statusId);
  return refreshedOwner.applyStatus(
    BlindajeTemporalStatus(value: shieldValue),
    source: refreshedOwner,
  );
}

/// Genera flags de combate estables para que cada item controle usos por instancia.
/// Genera una flag runtime tipada para aislar usos de efectos por item o por instancia.
CombatRuntimeFlag _itemCombatFlag(
  Item item,
  ItemCombatFlagKind flag,
) {
  return CombatRuntimeFlag.item(
    itemFlag: flag,
    itemId: item.id,
    itemInstanceId: item.instanceId,
  );
}
