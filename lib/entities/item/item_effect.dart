import '../_imports.dart';
import '../../services/battler_runtime_service.dart';
import '../../services/operative_pattern_combat_rules.dart';
import '../../services/run_randomizer.dart';

part 'item_effects/item_effect_attack_and_sustain.dart';
part 'item_effects/item_effect_cycle.dart';
part 'item_effects/item_effect_desafio_line.dart';
part 'item_effects/item_effect_reactive_defense.dart';
part 'item_effects/item_effect_specialized.dart';

/// Agrupa el estado final del portador y del rival tras resolver un efecto de item.
class ItemEffectResolution {
  final Battler owner;
  final Battler opponent;
  final int attackBonusDelta;
  final int barrierBonusDelta;

  /// Crea una resolucion inmutable con ambos combatientes ya actualizados.
  const ItemEffectResolution({
    required this.owner,
    required this.opponent,
    this.attackBonusDelta = 0,
    this.barrierBonusDelta = 0,
  });
}

/// Enumera los momentos en los que un item puede reaccionar a una habilidad.
enum ItemAbilityResolutionContext {
  manualActivation,
  attackResolved,
  receiveDamageResolved,
  turnStart,
  turnEnd,
  patternMatchResolved,
}

/// Enumera los puntos del ciclo de combate en los que un item equipado puede intervenir.
enum ItemEffectHook {
  combatStart,
  turnStart,
  turnEnd,
  combatEnd,
  prePatternAttack,
  patternUsed,
  defendResolved,
  outgoingDamageModifier,
  incomingDamageEffect,
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
  contagioValueLost,
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

/// Devuelve el estado resultante cuando un item intercepta un estado entrante.
class ItemIncomingStatusResolution {
  final Battler owner;
  final Battler source;
  final BattlerStatus? status;

  /// Crea una resolucion para modificar/cancelar/redirigir un estado entrante.
  const ItemIncomingStatusResolution({
    required this.owner,
    required this.source,
    required this.status,
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

  /// Resuelve el efecto del item al inicio del combate.
  ItemEffectResolution onCombatStart({
    required Battler owner,
    required Battler opponent,
    required Item item,
    RunRandomizer? randomizer,
  }) {
    return ItemEffectResolution(owner: owner, opponent: opponent);
  }

  /// Resuelve el efecto del item al inicio de turno.
  ItemEffectResolution onTurnStart({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required bool isOwnerTurn,
    RunRandomizer? randomizer,
  }) {
    return ItemEffectResolution(owner: owner, opponent: opponent);
  }

  /// Resuelve el efecto del item al final de turno.
  ItemEffectResolution onTurnEnd({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required bool isOwnerTurn,
    RunRandomizer? randomizer,
  }) {
    return ItemEffectResolution(owner: owner, opponent: opponent);
  }

  /// Resuelve efectos inmediatamente despues de ejecutar una accion de defender.
  ItemEffectResolution onDefendResolved({
    required Battler owner,
    required Battler opponent,
    required Item item,
  }) {
    return ItemEffectResolution(owner: owner, opponent: opponent);
  }

  /// Resuelve un item cuando su punto equipado se usa en el Patron final.
  ItemEffectResolution onPatternUsed({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required BattlePatternMatchContext pattern,
  }) {
    final attackResolution = onAttackResolved(
      owner: owner,
      target: opponent,
      item: item,
      damageDealt: pattern.attackBonus,
    );
    return onDefendResolved(
      owner: attackResolution.owner,
      opponent: attackResolution.opponent,
      item: item,
    );
  }

  /// Resuelve efectos puntuales al terminar el combate antes de limpiar flags y cooldowns.
  Battler onCombatEnd({
    required Battler owner,
    required Item item,
  }) {
    return owner;
  }

  /// Ajusta el daño saliente del portador antes de que se aplique.
  int modifyOutgoingDamage({
    required Battler owner,
    required Battler target,
    required Item item,
    required int damage,
  }) {
    return damage;
  }

  /// Ajusta el daño entrante del portador antes de que se aplique.
  int modifyIncomingDamage({
    required Battler owner,
    required Battler source,
    required Item item,
    required int damage,
  }) {
    return damage;
  }

  /// Permite alterar el portador y el dano entrante justo antes de recibirlo.
  BattlerIncomingDamageResolution onIncomingDamage({
    required Battler owner,
    required Battler source,
    required Item item,
    required int damage,
    required DamageKind kind,
  }) {
    return BattlerIncomingDamageResolution(
      owner: owner,
      damage: modifyIncomingDamage(
        owner: owner,
        source: source,
        item: item,
        damage: damage,
      ),
    );
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

  /// Resuelve efectos que deben ocurrir antes del ataque de un Patron.
  ItemEffectResolution onPrePatternAttack({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required BattlePatternMatchContext pattern,
  }) {
    return ItemEffectResolution(owner: owner, opponent: opponent);
  }

  /// Resuelve efectos posteriores a que el portador reciba daño.
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

  /// Permite que un item reaccione a un estado recibido y tambien altere la fuente.
  ItemIncomingStatusResolution onIncomingStatus({
    required Battler owner,
    required Battler source,
    required Item item,
    required BattlerStatus status,
  }) {
    return ItemIncomingStatusResolution(
      owner: owner,
      source: source,
      status: modifyIncomingStatus(
        owner: owner,
        source: source,
        item: item,
        status: status,
      ),
    );
  }

  /// Reacciona cuando Contagio pierde valor al activarse o desaparecer.
  ItemEffectResolution onContagioValueLost({
    required Battler owner,
    required Battler opponent,
    required Item item,
    required int lostValue,
    required bool isOwnerContagioCarrier,
    required bool wasRemoved,
    required BattlerStatus triggerStatus,
  }) {
    return ItemEffectResolution(owner: owner, opponent: opponent);
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

/// Recupera barrera sin aplicar tope maximo.
Battler _recoverBarrier({
  required Battler owner,
  required int amount,
}) {
  final safeAmount = max(0, amount);
  if (safeAmount <= 0 || owner.isDefeated) {
    return owner;
  }

  return owner.gainCombatBarrier(safeAmount);
}

/// Suma barrera directa sin aplicar tope de barrera maxima.
Battler _recoverBarrierWithoutCap({
  required Battler owner,
  required int amount,
}) {
  return _recoverBarrier(
    owner: owner,
    amount: amount,
  );
}

/// Comprueba si el battler tiene al menos un debuff activo.
bool _hasAnyDebuff(Battler battler) {
  return battler.statuses.any(
    (status) => status.type == BattlerStatusType.debuff,
  );
}

int _missingHealth(Battler battler) {
  return max(0, battler.maxHealth - battler.health);
}

Battler _loseHealthDirectly({
  required Battler owner,
  required int amount,
}) {
  final safeAmount = max(0, amount);
  if (safeAmount <= 0 || owner.health <= 0) {
    return owner;
  }

  final damagedOwner = owner.copyWith(
    health: max(0, owner.health - safeAmount),
  );
  if (damagedOwner.health > 0) {
    return damagedOwner;
  }

  return damagedOwner.applyEquippedItemFatalDamageEffects(
    incomingDamage: safeAmount,
  );
}

Battler _replaceOwnedItem({
  required Battler owner,
  required Item currentItem,
  required Item replacement,
}) {
  final equippedIndex = owner.equippedItems.indexOf(currentItem);
  if (equippedIndex >= 0) {
    final updatedEquippedItems = List<Item>.from(owner.equippedItems);
    updatedEquippedItems[equippedIndex] = replacement;
    return owner.copyWith(
      equippedItems: List<Item>.unmodifiable(updatedEquippedItems),
    );
  }

  final inventoryIndex = owner.inventoryItems.indexOf(currentItem);
  if (inventoryIndex >= 0) {
    final updatedInventoryItems = List<Item>.from(owner.inventoryItems);
    updatedInventoryItems[inventoryIndex] = replacement;
    return owner.copyWith(
      inventoryItems: List<Item>.unmodifiable(updatedInventoryItems),
    );
  }

  return owner;
}

List<BattlerStatus> _purgeableDebuffs(Battler battler) {
  return battler.statuses
      .where(
        (status) =>
            status.type == BattlerStatusType.debuff && status.isPurgeable,
      )
      .toList(growable: false);
}

Battler _reduceDebuffTurns({
  required Battler owner,
  required BattlerStatus debuff,
  required int amount,
}) {
  final reducedTurns = max(0, debuff.remainingTurns - max(0, amount)).toInt();
  if (reducedTurns <= 0) {
    return owner.removeStatusInstance(debuff);
  }

  return owner.replaceStatusInstance(
    currentStatus: debuff,
    replacement: debuff.copyWith(remainingTurns: reducedTurns),
  );
}

Battler _reduceAllPurgeableDebuffs({
  required Battler owner,
  required int amount,
}) {
  var updatedOwner = owner;
  final debuffs = _purgeableDebuffs(owner);
  for (final debuff in debuffs) {
    updatedOwner = _reduceDebuffTurns(
      owner: updatedOwner,
      debuff: debuff,
      amount: amount,
    );
  }

  return updatedOwner.pruneExpiredStatuses();
}

Battler _reduceRandomPurgeableDebuffs({
  required Battler owner,
  required int repetitions,
  RunRandomizer? randomizer,
}) {
  var updatedOwner = owner;

  for (var index = 0; index < max(0, repetitions); index++) {
    final debuffs = _purgeableDebuffs(updatedOwner);
    if (debuffs.isEmpty) break;

    final selectedIndex =
        randomizer == null ? 0 : randomizer.nextInt(debuffs.length);
    updatedOwner = _reduceDebuffTurns(
      owner: updatedOwner,
      debuff: debuffs[selectedIndex],
      amount: 1,
    );
  }

  return updatedOwner.pruneExpiredStatuses();
}

/// Comprueba si un item cuenta como mercancia ajena para las sinergias del Mercante.
bool _isForeignItemForMercante(Item item) {
  if (item.hasArchetypeAffinity(ItemArchetypeAffinity.general) ||
      item.hasArchetypeAffinity(ItemArchetypeAffinity.mercante)) {
    return false;
  }

  return item.archetypeAffinities.any((affinity) => affinity.isSpecific);
}

/// Cuenta cuantos items ajenos guarda el portador en el inventario.
int _countForeignInventoryItemsForMercante(Battler owner) {
  return owner.inventoryItems.where(_isForeignItemForMercante).length;
}

/// Cuenta cuantos items ajenos posee el portador entre inventario y equipo.
int _countForeignOwnedItemsForMercante(Battler owner) {
  return [
    ...owner.inventoryItems,
    ...owner.equippedItems,
  ].where(_isForeignItemForMercante).length;
}

/// Sube la barrera del portador hasta un minimo.
Battler _refreshMinimumBarrier({
  required Battler owner,
  required int value,
}) {
  final minimumBarrier = max(1, value);
  if (owner.currentBarrier >= minimumBarrier) {
    return owner;
  }

  return owner.copyWith(
    currentBarrier: minimumBarrier,
  );
}

ItemEffectResolution _applyStatusToOpponentFromOwner({
  required Battler owner,
  required Battler opponent,
  required BattlerStatus status,
  bool applyEquipmentModifiers = true,
}) {
  final resolution = opponent.applyStatusFromSourceResolved(
    status,
    source: owner,
    applyEquipmentModifiers: applyEquipmentModifiers,
  );
  return ItemEffectResolution(
    owner: resolution.source,
    opponent: resolution.owner,
  );
}

/// Genera flags de combate estables para que cada item controle usos por instancia.
/// Genera una flag runtime tipada para aislar usos de efectos por item o por instancia.
CombatRuntimeFlag _itemCombatFlag(
  Item item,
  ItemCombatFlagKind flag, [
  int? value,
]) {
  return CombatRuntimeFlag.item(
    itemFlag: flag,
    itemId: item.id,
    itemInstanceId: item.instanceId,
    value: value,
  );
}
