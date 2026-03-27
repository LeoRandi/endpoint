import '../_imports.dart';
import '../../services/run_randomizer.dart';

/// Enumera las stats base y derivadas que puede consultar un battler.
enum BattlerStat {
  health,
  attack,
  defense,
  thorns,
  damageReduction,
  vampirism,
}

/// Representa el estado completo de un combatiente, incluyendo economia, equipo y hooks runtime.
class Battler {
  static const combatActiveFlag = 'combat_active';
  static const manualAbilityActivatedThisTurnFlag =
      'manual_ability_activated_this_turn';
  static const pendingBasicAttackFollowUpFlag =
      'pending_basic_attack_follow_up';

  final String name;
  final String iconEmoji;
  final int health;
  final int money;
  final int baseIncome;
  final Map<BattlerStat, int> baseStats;
  final List<BattlerAbility> abilities;
  final List<BattlerStatus> statuses;
  final List<Item> inventoryItems;
  final List<Item> equippedItems;
  final Set<String> combatFlags;

  /// Crea un battler inmutable listo para combate, ruta o persistencia.
  const Battler({
    required this.name,
    this.iconEmoji = '\u{1F916}',
    required this.health,
    this.money = 0,
    int income = 0,
    required this.baseStats,
    this.abilities = const [],
    this.statuses = const [],
    this.inventoryItems = const [],
    this.equippedItems = const [],
    this.combatFlags = const <String>{},
  })  : baseIncome = income,
        assert(health >= 0);

  /// Devuelve la vida maxima base sin modificadores de equipo ni estados.
  int get baseMaxHealth => baseStat(BattlerStat.health);

  /// Devuelve la vida maxima ya calculada con equipo y estados.
  int get maxHealth => calculatedStat(BattlerStat.health);

  /// Devuelve el ataque base sin modificadores de equipo ni estados.
  int get baseAttack => baseStat(BattlerStat.attack);

  /// Devuelve el ataque ya calculado con equipo y estados.
  int get attack => calculatedStat(BattlerStat.attack);

  /// Devuelve la defensa base sin modificadores de equipo ni estados.
  int get baseDefense => baseStat(BattlerStat.defense);

  /// Devuelve la defensa ya calculada con equipo y estados.
  int get defense => calculatedStat(BattlerStat.defense);

  /// Devuelve el thorns base sin modificadores de equipo ni estados.
  int get baseThorns => baseStat(BattlerStat.thorns);

  /// Devuelve el thorns ya calculado con equipo y estados.
  int get thorns => calculatedStat(BattlerStat.thorns);

  /// Devuelve la reduccion de dano base sin modificadores de equipo ni estados.
  int get baseDamageReduction => baseStat(BattlerStat.damageReduction);

  /// Devuelve la reduccion de dano ya calculada con equipo y estados.
  int get damageReduction => calculatedStat(BattlerStat.damageReduction);

  /// Devuelve el vampirismo base sin modificadores de equipo ni estados.
  int get baseVampirism => baseStat(BattlerStat.vampirism);

  /// Devuelve el vampirismo ya calculado con equipo y estados.
  int get vampirism => calculatedStat(BattlerStat.vampirism);

  /// Indica cuantas veces se resuelve un ataque basico por cada accion.
  int get basicAttackCount {
    var updatedCount = 1;

    for (final item in equippedItems) {
      final effect = item.effect;
      if (effect == null) continue;

      updatedCount = effect.modifyBasicAttackCount(
        owner: this,
        item: item,
        count: updatedCount,
      );
    }

    return max(1, updatedCount);
  }

  /// Calcula el income efectivo tras aplicar equipo y estados que lo alteran.
  int get income {
    var updatedIncome = _calculateIncome(
      baseIncome: baseIncome,
      equippedItems: equippedItems,
    );

    for (final status in statuses) {
      final resolvedStatus = status.resolved(this);
      updatedIncome = resolvedStatus.modifyIncome(
        owner: this,
        income: updatedIncome,
      );
    }

    return max(0, updatedIncome);
  }

  /// Indica si este battler ya no tiene vida.
  bool get isDefeated => health <= 0;

  /// Comprueba si el battler posee exactamente esa instancia de item.
  bool ownsItem(Item item) {
    return inventoryItems.contains(item) || equippedItems.contains(item);
  }

  /// Comprueba si el battler posee algun item de ese tipo, equipado o en inventario.
  bool ownsItemOfType(ItemId itemId) {
    return inventoryItemOfType(itemId) != null ||
        equippedItemOfType(itemId) != null;
  }

  /// Comprueba si el battler ya tiene una habilidad con ese id.
  bool hasAbility(BattlerAbility ability) {
    return abilityById(ability.id) != null;
  }

  /// Indica si el battler tiene al menos una habilidad.
  bool get hasAbilities => abilities.isNotEmpty;

  /// Indica si el battler tiene al menos un estado activo.
  bool get hasStatuses => statuses.isNotEmpty;

  /// Indica si hay algun item equipado con hooks de efecto.
  bool get hasItemEffects => equippedItems.any((item) => item.effect != null);

  /// Comprueba si una flag de combate concreta sigue activa.
  bool hasCombatFlag(String flag) => combatFlags.contains(flag);

  /// Indica si el ataque basico actual todavia tiene impactos pendientes.
  bool get hasPendingBasicAttackFollowUp {
    return hasCombatFlag(pendingBasicAttackFollowUpFlag);
  }

  /// Devuelve el valor base de una stat sin aplicar ningun modificador.
  int baseStat(BattlerStat stat) {
    return baseStats[stat] ?? 0;
  }

  /// Busca el primer estado activo con el id indicado.
  BattlerStatus? statusById(String statusId) {
    for (final status in statuses) {
      if (status.id == statusId) return status;
    }
    return null;
  }

  /// Devuelve todas las instancias activas que comparten un mismo id de estado.
  List<BattlerStatus> statusesById(String statusId) {
    return statuses
        .where((status) => status.id == statusId)
        .toList(growable: false);
  }

  /// Busca la habilidad activa con el id indicado.
  BattlerAbility? abilityById(BattlerAbilityId abilityId) {
    for (final ability in abilities) {
      if (ability.id == abilityId) return ability;
    }
    return null;
  }

  /// Comprueba si existe al menos una instancia del estado indicado.
  bool hasStatus(String statusId) {
    return statusById(statusId) != null;
  }

  /// Calcula una stat final aplicando equipo y despues modificadores de estados.
  int calculatedStat(BattlerStat stat) {
    var updatedValue = _calculateStat(
      baseStats: baseStats,
      equippedItems: equippedItems,
      stat: stat,
    );

    for (final status in statuses) {
      final resolvedStatus = status.resolved(this);
      updatedValue = resolvedStatus.modifyCalculatedStat(
        owner: this,
        stat: stat,
        value: updatedValue,
      );
    }

    for (final item in equippedItems) {
      final effect = item.effect;
      if (effect == null) continue;

      updatedValue = effect.modifyCalculatedStat(
        owner: this,
        item: item,
        stat: stat,
        value: updatedValue,
      );
    }

    return max(0, updatedValue);
  }

  /// Calcula el dano base de un ataque directo usando ataque menos defensa.
  int calculateDamageAgainst(Battler target) {
    // TODO: Apply thorns, damage reduction, and vampirism when their combat rules are defined.
    return max(
      1,
      calculatedStat(BattlerStat.attack) -
          target.calculatedStat(BattlerStat.defense),
    );
  }

  /// Recibe un ataque basico de otro battler y resuelve dano directo.
  Battler receiveAttack(Battler attacker) {
    return receiveDirectDamage(
      attacker.calculateDamageAgainst(this),
      source: attacker,
    );
  }

  /// Resta vida directa, dispara protecciones letales y nunca deja vida negativa.
  Battler receiveDamage(int damage) {
    final safeDamage = max(0, damage);
    if (safeDamage <= 0) return this;

    final damagedOwner = copyWith(health: max(0, health - safeDamage));
    if (damagedOwner.health > 0) {
      return damagedOwner;
    }

    return damagedOwner.applyEquippedItemFatalDamageEffects(
      incomingDamage: safeDamage,
    );
  }

  /// Procesa un impacto directo con hooks defensivos antes de restar vida.
  Battler receiveDirectDamage(
    int damage, {
    required Battler source,
  }) {
    final resolution = applyIncomingDamageEffects(
      source: source,
      damage: damage,
      kind: DamageKind.direct,
    );
    return resolution.owner.receiveDamage(resolution.damage);
  }

  /// Procesa dano de debuff con hooks defensivos antes de restar vida.
  Battler receiveDebuffDamage(
    int damage, {
    required Battler source,
  }) {
    final resolution = applyIncomingDamageEffects(
      source: source,
      damage: damage,
      kind: DamageKind.debuff,
    );
    return resolution.owner.receiveDamage(resolution.damage);
  }

  /// Cura vida sin superar la vida maxima calculada actual.
  Battler heal(int amount) {
    final safeAmount = max(0, amount);
    return copyWith(health: min(maxHealth, health + safeAmount));
  }

  /// Aplica un estado nuevo pasando por modificadores de equipo, stacking y reemplazos.
  Battler applyStatus(
    BattlerStatus status, {
    Battler? source,
    bool applyEquipmentModifiers = true,
  }) {
    var updatedOwner = this;
    BattlerStatus? instancedStatus = status.copyWith();

    if (applyEquipmentModifiers && source != null) {
      instancedStatus = source.applyEquippedItemOutgoingStatusModifiers(
        target: updatedOwner,
        status: instancedStatus,
      );
      if (instancedStatus != null) {
        instancedStatus = updatedOwner.applyEquippedItemIncomingStatusModifiers(
          source: source,
          status: instancedStatus,
        );
      }
    }

    if (instancedStatus == null || instancedStatus.isExpired) {
      return updatedOwner;
    }

    final activeStatuses = List<BattlerStatus>.from(updatedOwner.statuses);

    for (final activeStatus in activeStatuses) {
      if (instancedStatus == null) break;

      final resolvedStatus = activeStatus.resolved(updatedOwner);
      final resolution = resolvedStatus.onStatusApplied(
        owner: updatedOwner,
        appliedStatus: instancedStatus,
      );
      updatedOwner = resolution.owner;
      instancedStatus = resolution.appliedStatus.copyWith();
    }

    if (instancedStatus == null || instancedStatus.isExpired) {
      return updatedOwner._removeExpiredStatuses();
    }

    final resolvedInstancedStatus = instancedStatus;
    final updatedStatuses = List<BattlerStatus>.from(updatedOwner.statuses);
    if (resolvedInstancedStatus.canStack) {
      updatedStatuses.add(resolvedInstancedStatus);
      return updatedOwner
          .copyWith(
            statuses: List<BattlerStatus>.unmodifiable(updatedStatuses),
          )
          ._removeExpiredStatuses();
    }

    final existingIndex = updatedStatuses.indexWhere(
      (activeStatus) =>
          activeStatus.id == resolvedInstancedStatus.id &&
          !activeStatus.canStack,
    );

    if (existingIndex >= 0) {
      updatedStatuses[existingIndex] = resolvedInstancedStatus;
    } else {
      updatedStatuses.add(resolvedInstancedStatus);
    }

    return updatedOwner
        .copyWith(statuses: List<BattlerStatus>.unmodifiable(updatedStatuses))
        ._removeExpiredStatuses();
  }

  /// Elimina todas las instancias del estado indicado.
  Battler removeStatus(String statusId) {
    if (!hasStatus(statusId)) return this;

    final updatedStatuses = statuses
        .where((status) => status.id != statusId)
        .toList(growable: false);
    return copyWith(
        statuses: List<BattlerStatus>.unmodifiable(updatedStatuses));
  }

  /// Elimina una instancia concreta de estado comparando referencia o valores runtime.
  Battler removeStatusInstance(BattlerStatus status) {
    final updatedStatuses = List<BattlerStatus>.from(statuses);
    final matchingIndex = updatedStatuses.indexWhere(
      (activeStatus) =>
          identical(activeStatus, status) ||
          (activeStatus.runtimeType == status.runtimeType &&
              activeStatus.id == status.id &&
              activeStatus.remainingTurns == status.remainingTurns &&
              activeStatus.value == status.value),
    );
    if (matchingIndex < 0) return this;

    updatedStatuses.removeAt(matchingIndex);
    return copyWith(
      statuses: List<BattlerStatus>.unmodifiable(updatedStatuses),
    );
  }

  /// Sustituye una instancia concreta de estado por otra ya resuelta.
  Battler replaceStatusInstance({
    required BattlerStatus currentStatus,
    required BattlerStatus replacement,
  }) {
    final updatedStatuses = List<BattlerStatus>.from(statuses);
    final matchingIndex = updatedStatuses.indexWhere(
      (activeStatus) =>
          identical(activeStatus, currentStatus) ||
          (activeStatus.runtimeType == currentStatus.runtimeType &&
              activeStatus.id == currentStatus.id &&
              activeStatus.remainingTurns == currentStatus.remainingTurns &&
              activeStatus.value == currentStatus.value),
    );
    if (matchingIndex < 0) return this;

    updatedStatuses[matchingIndex] = replacement;
    return copyWith(
      statuses: List<BattlerStatus>.unmodifiable(updatedStatuses),
    );
  }

  /// Reduce en uno la duracion de todos los estados temporales y limpia los caducados.
  Battler decrementStatusDurations() {
    if (statuses.isEmpty) return this;

    final updatedStatuses = statuses
        .map(
          (status) => status.copyWith(
            remainingTurns: max(0, status.remainingTurns - 1),
          ),
        )
        .where((status) => !status.isExpired)
        .toList(growable: false);
    return copyWith(
        statuses: List<BattlerStatus>.unmodifiable(updatedStatuses));
  }

  /// Hace avanzar el cooldown de las habilidades al inicio del turno propio.
  Battler progressAbilityCooldownsOnTurnStart({
    required bool isOwnerTurn,
  }) {
    if (!isOwnerTurn || abilities.isEmpty) return this;

    return copyWith(
      abilities: abilities
          .map((ability) => ability.tickCooldown())
          .toList(growable: false),
    );
  }

  /// Ejecuta todos los hooks de inicio de turno de los estados activos.
  Battler applyStatusTurnStart({
    required Battler opponent,
    required bool isOwnerTurn,
    RunRandomizer? randomizer,
  }) {
    if (statuses.isEmpty) return this;

    var updatedOwner = this;
    final activeStatuses = List<BattlerStatus>.from(statuses);

    for (final status in activeStatuses) {
      final resolvedStatus = status.resolved(updatedOwner);
      updatedOwner = resolvedStatus.onTurnStart(
        owner: updatedOwner,
        opponent: opponent,
        isOwnerTurn: isOwnerTurn,
        randomizer: randomizer,
      );
    }

    return updatedOwner._removeExpiredStatuses();
  }

  /// Ejecuta todos los hooks de inicio de turno de las habilidades activas.
  BattlerAbilityEffectResolution applyAbilityTurnStartEffects({
    required Battler opponent,
    required bool isOwnerTurn,
  }) {
    if (abilities.isEmpty) {
      return BattlerAbilityEffectResolution(owner: this, opponent: opponent);
    }

    var updatedOwner = this;
    var updatedOpponent = opponent;
    final activeAbilities = List<BattlerAbility>.from(abilities);

    for (final ability in activeAbilities) {
      final previousAbility = updatedOwner.abilityById(ability.id);
      final effect = previousAbility?.effect;
      if (previousAbility == null || effect == null) continue;

      final resolution = effect.onTurnStart(
        owner: updatedOwner,
        opponent: updatedOpponent,
        ability: previousAbility,
        isOwnerTurn: isOwnerTurn,
      );
      updatedOwner = resolution.owner;
      updatedOpponent = resolution.opponent;

      final itemResolution =
          updatedOwner.applyEquippedItemAbilityResolvedEffects(
        opponent: updatedOpponent,
        previousAbility: previousAbility,
        context: ItemAbilityResolutionContext.turnStart,
      );
      updatedOwner = itemResolution.owner;
      updatedOpponent = itemResolution.opponent;
    }

    return BattlerAbilityEffectResolution(
      owner: updatedOwner._removeExpiredStatuses(),
      opponent: updatedOpponent._removeExpiredStatuses(),
    );
  }

  /// Ejecuta todos los hooks de final de turno de los estados activos.
  Battler applyStatusTurnEnd({
    required Battler opponent,
    required bool isOwnerTurn,
    RunRandomizer? randomizer,
  }) {
    if (statuses.isEmpty) return this;

    var updatedOwner = this;
    final activeStatuses = List<BattlerStatus>.from(statuses);

    for (final status in activeStatuses) {
      final resolvedStatus = status.resolved(updatedOwner);
      updatedOwner = resolvedStatus.onTurnEnd(
        owner: updatedOwner,
        opponent: opponent,
        isOwnerTurn: isOwnerTurn,
        randomizer: randomizer,
      );
    }

    return updatedOwner._removeExpiredStatuses();
  }

  /// Ejecuta todos los hooks de final de turno de las habilidades activas.
  BattlerAbilityEffectResolution applyAbilityTurnEndEffects({
    required Battler opponent,
    required bool isOwnerTurn,
  }) {
    if (abilities.isEmpty) {
      return BattlerAbilityEffectResolution(owner: this, opponent: opponent);
    }

    var updatedOwner = this;
    var updatedOpponent = opponent;
    final activeAbilities = List<BattlerAbility>.from(abilities);

    for (final ability in activeAbilities) {
      final previousAbility = updatedOwner.abilityById(ability.id);
      final effect = previousAbility?.effect;
      if (previousAbility == null || effect == null) continue;

      final resolution = effect.onTurnEnd(
        owner: updatedOwner,
        opponent: updatedOpponent,
        ability: previousAbility,
        isOwnerTurn: isOwnerTurn,
      );
      updatedOwner = resolution.owner;
      updatedOpponent = resolution.opponent;

      final itemResolution =
          updatedOwner.applyEquippedItemAbilityResolvedEffects(
        opponent: updatedOpponent,
        previousAbility: previousAbility,
        context: ItemAbilityResolutionContext.turnEnd,
      );
      updatedOwner = itemResolution.owner;
      updatedOpponent = itemResolution.opponent;
    }

    return BattlerAbilityEffectResolution(
      owner: updatedOwner._removeExpiredStatuses(),
      opponent: updatedOpponent._removeExpiredStatuses(),
    );
  }

  /// Aplica a un dano saliente todos los modificadores provenientes de estados.
  int applyOutgoingDamageModifiers({
    required Battler target,
    required int damage,
  }) {
    var updatedDamage = damage;

    for (final status in statuses) {
      final resolvedStatus = status.resolved(this);
      updatedDamage = resolvedStatus.modifyOutgoingDamage(
        owner: this,
        target: target,
        damage: updatedDamage,
      );
    }

    return max(0, updatedDamage);
  }

  /// Aplica a un dano saliente todos los modificadores de items equipados.
  int applyEquippedItemOutgoingDamageModifiers({
    required Battler target,
    required int damage,
  }) {
    var updatedDamage = damage;

    for (final item in equippedItems) {
      final effect = item.effect;
      if (effect == null) continue;

      updatedDamage = effect.modifyOutgoingDamage(
        owner: this,
        target: target,
        item: item,
        damage: updatedDamage,
      );
    }

    return max(0, updatedDamage);
  }

  /// Permite a los items equipados alterar o cancelar un estado que se va a aplicar.
  BattlerStatus? applyEquippedItemOutgoingStatusModifiers({
    required Battler target,
    required BattlerStatus status,
  }) {
    BattlerStatus? updatedStatus = status;

    for (final item in equippedItems) {
      final effect = item.effect;
      if (effect == null || updatedStatus == null) continue;

      updatedStatus = effect.modifyOutgoingStatus(
        owner: this,
        target: target,
        item: item,
        status: updatedStatus,
      );
    }

    return updatedStatus;
  }

  /// Aplica a un dano saliente todos los modificadores provenientes de habilidades.
  int applyAbilityOutgoingDamageModifiers({
    required Battler target,
    required int damage,
  }) {
    var updatedDamage = damage;

    for (final ability in abilities) {
      final effect = ability.effect;
      if (effect == null) continue;

      updatedDamage = effect.modifyOutgoingDamage(
        owner: this,
        target: target,
        ability: ability,
        damage: updatedDamage,
      );
    }

    return max(0, updatedDamage);
  }

  /// Aplica a un dano entrante todos los modificadores provenientes de estados.
  int applyIncomingDamageModifiers({
    required Battler source,
    required int damage,
  }) {
    var updatedDamage = damage;

    for (final status in statuses) {
      final resolvedStatus = status.resolved(this);
      updatedDamage = resolvedStatus.modifyIncomingDamage(
        owner: this,
        source: source,
        damage: updatedDamage,
      );
    }

    return max(0, updatedDamage);
  }

  /// Ejecuta hooks defensivos complejos de estados sobre un dano entrante.
  BattlerIncomingDamageResolution applyIncomingDamageEffects({
    required Battler source,
    required int damage,
    required DamageKind kind,
  }) {
    var updatedOwner = this;
    var updatedDamage = damage;
    final activeStatuses = List<BattlerStatus>.from(statuses);

    for (final status in activeStatuses) {
      final matchingIndex = updatedOwner.statuses.indexWhere(
        (activeStatus) =>
            identical(activeStatus, status) ||
            (activeStatus.runtimeType == status.runtimeType &&
                activeStatus.id == status.id &&
                activeStatus.remainingTurns == status.remainingTurns &&
                activeStatus.value == status.value),
      );
      if (matchingIndex < 0) continue;

      final resolvedStatus = updatedOwner.statuses[matchingIndex].resolved(
        updatedOwner,
      );
      final resolution = resolvedStatus.onIncomingDamage(
        owner: updatedOwner,
        source: source,
        damage: updatedDamage,
        kind: kind,
      );
      updatedOwner = resolution.owner;
      updatedDamage = resolution.damage;
    }

    return BattlerIncomingDamageResolution(
      owner: updatedOwner._removeExpiredStatuses(),
      damage: max(0, updatedDamage),
    );
  }

  /// Aplica a un dano entrante todos los modificadores de items equipados.
  int applyEquippedItemIncomingDamageModifiers({
    required Battler source,
    required int damage,
  }) {
    var updatedDamage = damage;

    for (final item in equippedItems) {
      final effect = item.effect;
      if (effect == null) continue;

      updatedDamage = effect.modifyIncomingDamage(
        owner: this,
        source: source,
        item: item,
        damage: updatedDamage,
      );
    }

    return max(0, updatedDamage);
  }

  /// Permite a los items equipados alterar o cancelar un estado recibido.
  BattlerStatus? applyEquippedItemIncomingStatusModifiers({
    required Battler source,
    required BattlerStatus status,
  }) {
    BattlerStatus? updatedStatus = status;

    for (final item in equippedItems) {
      final effect = item.effect;
      if (effect == null || updatedStatus == null) continue;

      updatedStatus = effect.modifyIncomingStatus(
        owner: this,
        source: source,
        item: item,
        status: updatedStatus,
      );
    }

    return updatedStatus;
  }

  /// Aplica a un dano entrante todos los modificadores provenientes de habilidades.
  int applyAbilityIncomingDamageModifiers({
    required Battler source,
    required int damage,
  }) {
    var updatedDamage = damage;

    for (final ability in abilities) {
      final effect = ability.effect;
      if (effect == null) continue;

      updatedDamage = effect.modifyIncomingDamage(
        owner: this,
        source: source,
        ability: ability,
        damage: updatedDamage,
      );
    }

    return max(0, updatedDamage);
  }

  /// Ejecuta efectos de estados que reaccionan despues de que el portador ataque.
  Battler applyAttackResolvedEffects({
    required Battler target,
    required int damageDealt,
  }) {
    if (statuses.isEmpty) return this;

    var updatedOwner = this;
    final activeStatuses = List<BattlerStatus>.from(statuses);

    for (final status in activeStatuses) {
      final resolvedStatus = status.resolved(updatedOwner);
      updatedOwner = resolvedStatus.onAttackResolved(
        owner: updatedOwner,
        target: target,
        damageDealt: damageDealt,
      );
    }

    return updatedOwner._removeExpiredStatuses();
  }

  /// Ejecuta efectos de items equipados que reaccionan despues de atacar.
  ItemEffectResolution applyEquippedItemAttackResolvedEffects({
    required Battler target,
    required int damageDealt,
  }) {
    var updatedOwner = this;
    var updatedTarget = target;

    for (final item in List<Item>.from(updatedOwner.equippedItems)) {
      final effect = item.effect;
      if (effect == null) continue;

      final resolution = effect.onAttackResolved(
        owner: updatedOwner,
        target: updatedTarget,
        item: item,
        damageDealt: damageDealt,
      );
      updatedOwner = resolution.owner;
      updatedTarget = resolution.opponent;
    }

    return ItemEffectResolution(
      owner: updatedOwner._removeExpiredStatuses(),
      opponent: updatedTarget._removeExpiredStatuses(),
    );
  }

  /// Ejecuta efectos de habilidades que reaccionan despues de atacar.
  BattlerAbilityEffectResolution applyAbilityAttackResolvedEffects({
    required Battler target,
    required int damageDealt,
  }) {
    if (abilities.isEmpty) {
      return BattlerAbilityEffectResolution(owner: this, opponent: target);
    }

    var updatedOwner = this;
    var updatedTarget = target;
    final activeAbilities = List<BattlerAbility>.from(abilities);

    for (final ability in activeAbilities) {
      final previousAbility = updatedOwner.abilityById(ability.id);
      final effect = previousAbility?.effect;
      if (previousAbility == null || effect == null) continue;

      final resolution = effect.onAttackResolved(
        owner: updatedOwner,
        target: updatedTarget,
        ability: previousAbility,
        damageDealt: damageDealt,
      );
      updatedOwner = resolution.owner;
      updatedTarget = resolution.opponent;

      final itemResolution =
          updatedOwner.applyEquippedItemAbilityResolvedEffects(
        opponent: updatedTarget,
        previousAbility: previousAbility,
        context: ItemAbilityResolutionContext.attackResolved,
      );
      updatedOwner = itemResolution.owner;
      updatedTarget = itemResolution.opponent;
    }

    return BattlerAbilityEffectResolution(
      owner: updatedOwner._removeExpiredStatuses(),
      opponent: updatedTarget._removeExpiredStatuses(),
    );
  }

  /// Ejecuta efectos de estados que reaccionan despues de recibir dano.
  Battler applyReceiveDamageResolvedEffects({
    required Battler source,
    required int damageTaken,
  }) {
    if (statuses.isEmpty) return this;

    var updatedOwner = this;
    final activeStatuses = List<BattlerStatus>.from(statuses);

    for (final status in activeStatuses) {
      final resolvedStatus = status.resolved(updatedOwner);
      updatedOwner = resolvedStatus.onReceiveDamageResolved(
        owner: updatedOwner,
        source: source,
        damageTaken: damageTaken,
      );
    }

    return updatedOwner._removeExpiredStatuses();
  }

  /// Ejecuta efectos de items equipados que reaccionan despues de recibir dano.
  ItemEffectResolution applyEquippedItemReceiveDamageResolvedEffects({
    required Battler source,
    required int damageTaken,
  }) {
    var updatedOwner = this;
    var updatedSource = source;

    for (final item in List<Item>.from(updatedOwner.equippedItems)) {
      final effect = item.effect;
      if (effect == null) continue;

      final resolution = effect.onReceiveDamageResolved(
        owner: updatedOwner,
        source: updatedSource,
        item: item,
        damageTaken: damageTaken,
      );
      updatedOwner = resolution.owner;
      updatedSource = resolution.opponent;
    }

    return ItemEffectResolution(
      owner: updatedOwner._removeExpiredStatuses(),
      opponent: updatedSource._removeExpiredStatuses(),
    );
  }

  /// Ejecuta efectos de habilidades que reaccionan despues de recibir dano.
  BattlerAbilityEffectResolution applyAbilityReceiveDamageResolvedEffects({
    required Battler source,
    required int damageTaken,
  }) {
    if (abilities.isEmpty) {
      return BattlerAbilityEffectResolution(owner: this, opponent: source);
    }

    var updatedOwner = this;
    var updatedSource = source;
    final activeAbilities = List<BattlerAbility>.from(abilities);

    for (final ability in activeAbilities) {
      final previousAbility = updatedOwner.abilityById(ability.id);
      final effect = previousAbility?.effect;
      if (previousAbility == null || effect == null) continue;

      final resolution = effect.onReceiveDamageResolved(
        owner: updatedOwner,
        source: updatedSource,
        ability: previousAbility,
        damageTaken: damageTaken,
      );
      updatedOwner = resolution.owner;
      updatedSource = resolution.opponent;

      final itemResolution =
          updatedOwner.applyEquippedItemAbilityResolvedEffects(
        opponent: updatedSource,
        previousAbility: previousAbility,
        context: ItemAbilityResolutionContext.receiveDamageResolved,
      );
      updatedOwner = itemResolution.owner;
      updatedSource = itemResolution.opponent;
    }

    return BattlerAbilityEffectResolution(
      owner: updatedOwner._removeExpiredStatuses(),
      opponent: updatedSource._removeExpiredStatuses(),
    );
  }

  /// Ejecuta efectos de inicio de turno para todos los items equipados.
  ItemEffectResolution applyEquippedItemTurnStartEffects({
    required Battler opponent,
    required bool isOwnerTurn,
  }) {
    var updatedOwner = this;
    var updatedOpponent = opponent;

    for (final item in List<Item>.from(updatedOwner.equippedItems)) {
      final effect = item.effect;
      if (effect == null) continue;

      final resolution = effect.onTurnStart(
        owner: updatedOwner,
        opponent: updatedOpponent,
        item: item,
        isOwnerTurn: isOwnerTurn,
      );
      updatedOwner = resolution.owner;
      updatedOpponent = resolution.opponent;
    }

    return ItemEffectResolution(
      owner: updatedOwner._removeExpiredStatuses(),
      opponent: updatedOpponent._removeExpiredStatuses(),
    );
  }

  /// Ejecuta efectos de final de turno para todos los items equipados.
  ItemEffectResolution applyEquippedItemTurnEndEffects({
    required Battler opponent,
    required bool isOwnerTurn,
  }) {
    var updatedOwner = this;
    var updatedOpponent = opponent;

    for (final item in List<Item>.from(updatedOwner.equippedItems)) {
      final effect = item.effect;
      if (effect == null) continue;

      final resolution = effect.onTurnEnd(
        owner: updatedOwner,
        opponent: updatedOpponent,
        item: item,
        isOwnerTurn: isOwnerTurn,
      );
      updatedOwner = resolution.owner;
      updatedOpponent = resolution.opponent;
    }

    return ItemEffectResolution(
      owner: updatedOwner._removeExpiredStatuses(),
      opponent: updatedOpponent._removeExpiredStatuses(),
    );
  }

  /// Ejecuta efectos pasivos de todos los items equipados.
  ItemEffectResolution applyEquippedItemPassiveEffects({
    required Battler opponent,
  }) {
    var updatedOwner = this;
    var updatedOpponent = opponent;

    for (final item in List<Item>.from(updatedOwner.equippedItems)) {
      final effect = item.effect;
      if (effect == null) continue;

      final resolution = effect.applyPassive(
        owner: updatedOwner,
        opponent: updatedOpponent,
        item: item,
      );
      updatedOwner = resolution.owner;
      updatedOpponent = resolution.opponent;
    }

    return ItemEffectResolution(
      owner: updatedOwner._removeExpiredStatuses(),
      opponent: updatedOpponent._removeExpiredStatuses(),
    );
  }

  /// Permite que los items modifiquen una habilidad justo antes de activarla manualmente.
  ItemAbilityPreparationResolution applyEquippedItemManualAbilityPreparation({
    required Battler opponent,
    required BattlerAbility ability,
    required BattlerAbilityActivationContext screenContext,
  }) {
    var updatedOwner = this;
    var updatedOpponent = opponent;
    var updatedAbility = ability;

    for (final item in List<Item>.from(updatedOwner.equippedItems)) {
      final effect = item.effect;
      if (effect == null) continue;

      final syncedAbility =
          updatedOwner.abilityById(updatedAbility.id) ?? updatedAbility;
      final resolution = effect.onManualAbilityPreparing(
        owner: updatedOwner,
        opponent: updatedOpponent,
        item: item,
        ability: syncedAbility,
        screenContext: screenContext,
      );
      updatedOwner = resolution.owner;
      updatedOpponent = resolution.opponent;
      updatedAbility = resolution.ability;
    }

    return ItemAbilityPreparationResolution(
      owner: updatedOwner._removeExpiredStatuses(),
      opponent: updatedOpponent._removeExpiredStatuses(),
      ability: updatedAbility,
    );
  }

  /// Ejecuta reacciones de items cuando una habilidad ya se ha resuelto.
  ItemEffectResolution applyEquippedItemAbilityResolvedEffects({
    required Battler opponent,
    required BattlerAbility previousAbility,
    required ItemAbilityResolutionContext context,
  }) {
    var updatedOwner = this;
    var updatedOpponent = opponent;

    for (final item in List<Item>.from(updatedOwner.equippedItems)) {
      final effect = item.effect;
      if (effect == null) continue;

      final resolvedAbility =
          updatedOwner.abilityById(previousAbility.id) ?? previousAbility;
      final resolution = effect.onAbilityResolved(
        owner: updatedOwner,
        opponent: updatedOpponent,
        item: item,
        previousAbility: previousAbility,
        resolvedAbility: resolvedAbility,
        context: context,
      );
      updatedOwner = resolution.owner;
      updatedOpponent = resolution.opponent;
    }

    return ItemEffectResolution(
      owner: updatedOwner._removeExpiredStatuses(),
      opponent: updatedOpponent._removeExpiredStatuses(),
    );
  }

  /// Ejecuta todos los efectos pasivos de habilidades activas o presentes.
  BattlerAbilityEffectResolution applyAbilityPassiveEffects({
    required Battler opponent,
  }) {
    if (abilities.isEmpty) {
      return BattlerAbilityEffectResolution(owner: this, opponent: opponent);
    }

    var updatedOwner = this;
    var updatedOpponent = opponent;
    final activeAbilities = List<BattlerAbility>.from(abilities);

    for (final ability in activeAbilities) {
      final resolvedAbility = updatedOwner.abilityById(ability.id);
      final effect = resolvedAbility?.effect;
      if (resolvedAbility == null || effect == null) continue;

      final resolution = effect.applyPassive(
        owner: updatedOwner,
        opponent: updatedOpponent,
        ability: resolvedAbility,
      );
      updatedOwner = resolution.owner;
      updatedOpponent = resolution.opponent;
    }

    return BattlerAbilityEffectResolution(
      owner: updatedOwner._removeExpiredStatuses(),
      opponent: updatedOpponent._removeExpiredStatuses(),
    );
  }

  /// Permite a los items equipados interceptar un golpe letal antes de morir.
  Battler applyEquippedItemFatalDamageEffects({
    required int incomingDamage,
  }) {
    var updatedOwner = this;

    for (final item in List<Item>.from(updatedOwner.equippedItems)) {
      final effect = item.effect;
      if (effect == null) continue;

      updatedOwner = effect.onReceiveFatalDamage(
        owner: updatedOwner,
        item: item,
        incomingDamage: incomingDamage,
      );
      if (updatedOwner.health > 0) {
        break;
      }
    }

    return updatedOwner._removeExpiredStatuses();
  }

  /// Comprueba si el battler tiene dinero suficiente para pagar una cantidad.
  bool canAfford(int amount) => money >= amount;

  /// Suma dinero sin permitir cantidades negativas.
  Battler earnMoney(int amount) {
    return copyWith(money: money + max(0, amount));
  }

  /// Resta dinero sin permitir que el total baje de cero.
  Battler spendMoney(int amount) {
    final safeAmount = max(0, amount);
    return copyWith(money: max(0, money - safeAmount));
  }

  /// Anade una habilidad nueva o mejora la existente si admite upgrade.
  Battler addAbility(BattlerAbility ability) {
    final existingIndex = abilities.indexWhere(
      (activeAbility) => activeAbility.id == ability.id,
    );
    if (existingIndex < 0) {
      return copyWith(
        abilities: List<BattlerAbility>.unmodifiable([
          ...abilities,
          ability,
        ]),
      );
    }

    final updatedAbilities = List<BattlerAbility>.from(abilities);
    updatedAbilities[existingIndex] =
        updatedAbilities[existingIndex].upgraded();

    return copyWith(
      abilities: List<BattlerAbility>.unmodifiable(updatedAbilities),
    );
  }

  /// Sustituye la version activa de una habilidad por la recibida.
  Battler updateAbility(BattlerAbility ability) {
    final updatedAbilities = List<BattlerAbility>.from(abilities);
    final existingIndex = updatedAbilities.indexWhere(
      (activeAbility) => activeAbility.id == ability.id,
    );
    if (existingIndex < 0) return this;

    updatedAbilities[existingIndex] = ability;
    return copyWith(
      abilities: List<BattlerAbility>.unmodifiable(updatedAbilities),
    );
  }

  /// Resetea solo las habilidades manuales que pertenecen al contexto indicado.
  Battler resetAbilitiesForContext(
    BattlerAbilityActivationContext screenContext,
  ) {
    if (abilities.isEmpty) return this;

    return copyWith(
      abilities: abilities
          .map(
            (ability) => ability.manualActivationContext == screenContext
                ? ability.resetState()
                : ability,
          )
          .toList(growable: false),
    );
  }

  /// Resetea por completo el estado runtime de todas las habilidades.
  Battler resetAllAbilities() {
    if (abilities.isEmpty) return this;

    return copyWith(
      abilities: abilities
          .map((ability) => ability.resetState())
          .toList(growable: false),
    );
  }

  /// Activa o desactiva una habilidad manual y resuelve sus hooks asociados.
  BattlerAbilityEffectResolution toggleAbilityActivation({
    required BattlerAbilityId abilityId,
    required BattlerAbilityActivationContext screenContext,
    Battler? opponent,
  }) {
    final currentAbility = abilityById(abilityId);
    final resolvedOpponent = opponent ?? this;
    if (currentAbility == null || !currentAbility.canToggleOn(screenContext)) {
      return BattlerAbilityEffectResolution(
        owner: this,
        opponent: resolvedOpponent,
      );
    }

    if (currentAbility.canDeactivateOn(screenContext)) {
      return BattlerAbilityEffectResolution(
        owner: updateAbility(currentAbility.deactivate()),
        opponent: resolvedOpponent,
      );
    }

    if (!currentAbility.canActivateOn(screenContext) ||
        !currentAbility.isImplemented) {
      return BattlerAbilityEffectResolution(
        owner: this,
        opponent: resolvedOpponent,
      );
    }
    if (!canActivateManualAbilities(screenContext)) {
      return BattlerAbilityEffectResolution(
        owner: this,
        opponent: resolvedOpponent,
      );
    }

    var activatedOwner = updateAbility(currentAbility.activate());
    if (screenContext == BattlerAbilityActivationContext.battle) {
      activatedOwner = activatedOwner.addCombatFlag(
        manualAbilityActivatedThisTurnFlag,
      );
    }
    var updatedOpponent = resolvedOpponent;
    var activatedAbility = activatedOwner.abilityById(abilityId);
    if (activatedAbility == null) {
      return BattlerAbilityEffectResolution(
        owner: activatedOwner,
        opponent: updatedOpponent,
      );
    }

    final preparation =
        activatedOwner.applyEquippedItemManualAbilityPreparation(
      opponent: updatedOpponent,
      ability: activatedAbility,
      screenContext: screenContext,
    );
    activatedOwner = preparation.owner;
    updatedOpponent = preparation.opponent;
    activatedAbility = preparation.ability;

    final effect = activatedAbility.effect;
    if (effect == null) {
      final itemResolution =
          activatedOwner.applyEquippedItemAbilityResolvedEffects(
        opponent: updatedOpponent,
        previousAbility: currentAbility,
        context: ItemAbilityResolutionContext.manualActivation,
      );
      return BattlerAbilityEffectResolution(
        owner: itemResolution.owner,
        opponent: itemResolution.opponent,
      );
    }

    final abilityResolution = effect.onManualActivation(
      owner: activatedOwner,
      opponent: updatedOpponent,
      ability: activatedAbility,
      screenContext: screenContext,
    );
    final itemResolution =
        abilityResolution.owner.applyEquippedItemAbilityResolvedEffects(
      opponent: abilityResolution.opponent,
      previousAbility: currentAbility,
      context: ItemAbilityResolutionContext.manualActivation,
    );

    return BattlerAbilityEffectResolution(
      owner: itemResolution.owner,
      opponent: itemResolution.opponent,
    );
  }

  /// Anade un item nuevo o mejora la copia ya poseida si admite upgrades.
  Battler addItem(Item item) {
    final upgradeTemplate =
        item.canUpgrade ? item : Item.presetForId(item.id);
    final ownedEquippedItem = equippedItemOfType(item.id);
    if (ownedEquippedItem != null && upgradeTemplate.canUpgrade) {
      final updatedEquippedItems = List<Item>.from(equippedItems);
      final existingIndex = updatedEquippedItems.indexOf(ownedEquippedItem);
      updatedEquippedItems[existingIndex] = ownedEquippedItem.upgraded();
      return copyWith(
        equippedItems: List<Item>.unmodifiable(updatedEquippedItems),
      );
    }

    final ownedInventoryItem = inventoryItemOfType(item.id);
    if (ownedInventoryItem != null && upgradeTemplate.canUpgrade) {
      final updatedInventoryItems = List<Item>.from(inventoryItems);
      final existingIndex = updatedInventoryItems.indexOf(ownedInventoryItem);
      updatedInventoryItems[existingIndex] = ownedInventoryItem.upgraded();
      return copyWith(
        inventoryItems: List<Item>.unmodifiable(updatedInventoryItems),
      );
    }

    return copyWith(
      inventoryItems: List<Item>.unmodifiable([
        ...inventoryItems,
        item.toOwnedInstance(),
      ]),
    );
  }

  /// Elimina un item del battler, desequipandolo antes si hace falta.
  Battler removeItem(Item item) {
    if (equippedItems.contains(item)) {
      return unequipItem(item).removeItem(item);
    }
    if (!inventoryItems.contains(item)) return this;

    final updatedInventoryItems = List<Item>.from(inventoryItems)..remove(item);
    return copyWith(
      inventoryItems: List<Item>.unmodifiable(updatedInventoryItems),
    );
  }

  /// Devuelve el item equipado que ocupa un slot concreto, si existe.
  Item? equippedItemForSlot(ItemSlot slot) {
    for (final item in equippedItems) {
      if (item.slot == slot) return item;
    }
    return null;
  }

  /// Busca en inventario el primer item de un tipo concreto.
  Item? inventoryItemOfType(ItemId itemId) {
    for (final item in inventoryItems) {
      if (item.id == itemId) return item;
    }
    return null;
  }

  /// Busca entre los items equipados el primero de un tipo concreto.
  Item? equippedItemOfType(ItemId itemId) {
    for (final item in equippedItems) {
      if (item.id == itemId) return item;
    }
    return null;
  }

  /// Convierte todos los items poseidos en instancias propias para poder diferenciarlos.
  Battler materializeOwnedItems() {
    final hasOnlyInstancedItems =
        inventoryItems.every((item) => item.isInstanced) &&
            equippedItems.every((item) => item.isInstanced);
    if (hasOnlyInstancedItems) return this;

    return copyWith(
      inventoryItems: inventoryItems
          .map((item) => item.toOwnedInstance())
          .toList(growable: false),
      equippedItems: equippedItems
          .map((item) => item.toOwnedInstance())
          .toList(growable: false),
    );
  }

  /// Equipa un item del inventario y libera el slot anterior si estaba ocupado.
  Battler equipItem(Item item) {
    if (!item.isEquippable) return this;
    if (!inventoryItems.contains(item)) return this;
    if (equippedItems.contains(item)) return this;

    final updatedInventoryItems = List<Item>.from(inventoryItems)..remove(item);
    final updatedEquippedItems = List<Item>.from(equippedItems);
    final occupiedSlotItem = equippedItemForSlot(item.slot!);

    if (occupiedSlotItem != null) {
      updatedEquippedItems.remove(occupiedSlotItem);
      updatedInventoryItems.add(occupiedSlotItem);
    }

    updatedEquippedItems.add(item);

    return copyWith(
      inventoryItems: List<Item>.unmodifiable(updatedInventoryItems),
      equippedItems: List<Item>.unmodifiable(updatedEquippedItems),
    );
  }

  /// Devuelve un item equipado al inventario sin alterar el resto del equipo.
  Battler unequipItem(Item item) {
    if (!equippedItems.contains(item)) return this;

    final updatedEquippedItems = List<Item>.from(equippedItems)..remove(item);
    final updatedInventoryItems = List<Item>.from(inventoryItems)..add(item);

    return copyWith(
      inventoryItems: List<Item>.unmodifiable(updatedInventoryItems),
      equippedItems: List<Item>.unmodifiable(updatedEquippedItems),
    );
  }

  /// Anade una flag de combate sin duplicarla.
  Battler addCombatFlag(String flag) {
    if (combatFlags.contains(flag)) return this;

    return copyWith(
      combatFlags: Set<String>.unmodifiable({
        ...combatFlags,
        flag,
      }),
    );
  }

  /// Elimina una flag de combate concreta si estaba activa.
  Battler removeCombatFlag(String flag) {
    if (!combatFlags.contains(flag)) return this;

    final updatedFlags = Set<String>.from(combatFlags)..remove(flag);
    return copyWith(
      combatFlags: Set<String>.unmodifiable(updatedFlags),
    );
  }

  /// Limpia todas las flags temporales de combate.
  Battler clearCombatFlags() {
    if (combatFlags.isEmpty) return this;

    return copyWith(combatFlags: const <String>{});
  }

  /// Elimina todos los estados que no deben sobrevivir fuera del combate.
  Battler clearCombatStatuses() {
    if (statuses.every((status) => status.persistsOutsideCombat)) {
      return this;
    }

    return copyWith(
      statuses: List<BattlerStatus>.unmodifiable(
        statuses
            .where((status) => status.persistsOutsideCombat)
            .toList(growable: false),
      ),
    );
  }

  /// Devuelve el primer motivo por el que una activacion manual esta bloqueada.
  String? manualAbilityActivationBlockReason(
    BattlerAbilityActivationContext screenContext,
  ) {
    for (final status in statuses) {
      final resolvedStatus = status.resolved(this);
      final blockReason = resolvedStatus.manualAbilityActivationBlockReason(
        owner: this,
        screenContext: screenContext,
      );
      if (blockReason != null) {
        return blockReason;
      }
    }

    return null;
  }

  /// Indica si puede activarse una habilidad manual en este contexto.
  bool canActivateManualAbilities(
    BattlerAbilityActivationContext screenContext,
  ) {
    return manualAbilityActivationBlockReason(screenContext) == null;
  }

  /// Clona el battler cambiando cualquier parte de su estado y limitando la vida al maximo actual.
  Battler copyWith({
    String? name,
    String? iconEmoji,
    int? health,
    int? money,
    int? income,
    Map<BattlerStat, int>? baseStats,
    List<BattlerAbility>? abilities,
    List<BattlerStatus>? statuses,
    List<Item>? inventoryItems,
    List<Item>? equippedItems,
    Set<String>? combatFlags,
  }) {
    final resolvedBaseStats = baseStats ?? this.baseStats;
    final resolvedAbilities = List<BattlerAbility>.unmodifiable(
      abilities ?? this.abilities,
    );
    final resolvedStatuses = List<BattlerStatus>.unmodifiable(
      statuses ?? this.statuses,
    );
    final resolvedInventoryItems = List<Item>.unmodifiable(
      inventoryItems ?? this.inventoryItems,
    );
    final resolvedEquippedItems = List<Item>.unmodifiable(
      equippedItems ?? this.equippedItems,
    );
    final resolvedCombatFlags = Set<String>.unmodifiable(
      combatFlags ?? this.combatFlags,
    );
    final resolvedMaxHealth = _calculateStat(
      baseStats: resolvedBaseStats,
      equippedItems: resolvedEquippedItems,
      stat: BattlerStat.health,
    );
    final resolvedHealth = min(health ?? this.health, resolvedMaxHealth);

    return Battler(
      name: name ?? this.name,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      health: max(0, resolvedHealth),
      money: max(0, money ?? this.money),
      income: max(0, income ?? baseIncome),
      baseStats: resolvedBaseStats,
      abilities: resolvedAbilities,
      statuses: resolvedStatuses,
      inventoryItems: resolvedInventoryItems,
      equippedItems: resolvedEquippedItems,
      combatFlags: resolvedCombatFlags,
    );
  }

  /// Elimina automaticamente las instancias de estado que ya han caducado.
  Battler _removeExpiredStatuses() {
    if (statuses.every((status) => !status.isExpired)) return this;

    final activeStatuses =
        statuses.where((status) => !status.isExpired).toList(growable: false);
    return copyWith(statuses: List<BattlerStatus>.unmodifiable(activeStatuses));
  }

  /// Calcula una stat base aplicando bonus planos y el modificador porcentual de vida maxima.
  static int _calculateStat({
    required Map<BattlerStat, int> baseStats,
    required List<Item> equippedItems,
    required BattlerStat stat,
  }) {
    final baseValue = baseStats[stat] ?? 0;
    final equipmentBonus = equippedItems.fold<int>(
      0,
      (total, item) => total + item.modifier(stat),
    );
    final flatResolvedValue = max(0, baseValue + equipmentBonus);
    if (stat != BattlerStat.health) {
      return flatResolvedValue;
    }

    final healthPercentModifier = equippedItems.fold<int>(
      0,
      (total, item) => total + item.maxHealthPercentModifier,
    );
    if (healthPercentModifier == 0) {
      return flatResolvedValue;
    }

    return max(
      0,
      (flatResolvedValue * (100 + healthPercentModifier) / 100).round(),
    );
  }

  /// Calcula el income base mas los bonus planos aportados por el equipo.
  static int _calculateIncome({
    required int baseIncome,
    required List<Item> equippedItems,
  }) {
    final equipmentBonus = equippedItems.fold<int>(
      0,
      (total, item) => total + item.incomeModifier,
    );

    return max(0, baseIncome + equipmentBonus);
  }
}
