import '_imports.dart';
import '../../services/run_randomizer.dart';

enum BattlerStat {
  health,
  attack,
  defense,
  thorns,
  damageReduction,
  vampirism,
}

class Battler {
  static const combatActiveFlag = 'combat_active';
  static const manualAbilityActivatedThisTurnFlag =
      'manual_ability_activated_this_turn';

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

  Battler.legacy({
    required String name,
    String iconEmoji = '\u{1F916}',
    required int attack,
    required int defense,
    required int health,
    int? maxHealth,
    int money = 0,
    int income = 0,
    List<Object> abilities = const [],
    List<BattlerStatus> statuses = const [],
    List<Item> inventoryItems = const [],
    List<Item> equippedItems = const [],
    Set<String> combatFlags = const <String>{},
  }) : this(
          name: name,
          iconEmoji: iconEmoji,
          health: health,
          money: money,
          income: income,
          baseStats: {
            BattlerStat.health: maxHealth ?? health,
            BattlerStat.attack: attack,
            BattlerStat.defense: defense,
            BattlerStat.thorns: 0,
            BattlerStat.damageReduction: 0,
            BattlerStat.vampirism: 0,
          },
          abilities: List<BattlerAbility>.unmodifiable(
            abilities.map(BattlerAbility.fromLegacy),
          ),
          statuses: List<BattlerStatus>.unmodifiable(statuses),
          inventoryItems: inventoryItems,
          equippedItems: equippedItems,
          combatFlags: combatFlags,
        );

  int get baseMaxHealth => baseStat(BattlerStat.health);
  int get maxHealth => calculatedStat(BattlerStat.health);

  int get baseAttack => baseStat(BattlerStat.attack);
  int get attack => calculatedStat(BattlerStat.attack);

  int get baseDefense => baseStat(BattlerStat.defense);
  int get defense => calculatedStat(BattlerStat.defense);

  int get baseThorns => baseStat(BattlerStat.thorns);
  int get thorns => calculatedStat(BattlerStat.thorns);

  int get baseDamageReduction => baseStat(BattlerStat.damageReduction);
  int get damageReduction => calculatedStat(BattlerStat.damageReduction);

  int get baseVampirism => baseStat(BattlerStat.vampirism);
  int get vampirism => calculatedStat(BattlerStat.vampirism);

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

  bool get isDefeated => health <= 0;

  bool ownsItem(Item item) {
    return inventoryItems.contains(item) || equippedItems.contains(item);
  }

  bool ownsItemOfType(ItemId itemId) {
    return inventoryItemOfType(itemId) != null ||
        equippedItemOfType(itemId) != null;
  }

  bool hasAbility(BattlerAbility ability) {
    return abilityById(ability.id) != null;
  }

  bool get hasAbilities => abilities.isNotEmpty;
  bool get hasStatuses => statuses.isNotEmpty;
  bool get hasItemEffects => equippedItems.any((item) => item.effect != null);

  bool hasCombatFlag(String flag) => combatFlags.contains(flag);

  int baseStat(BattlerStat stat) {
    return baseStats[stat] ?? 0;
  }

  BattlerStatus? statusById(String statusId) {
    for (final status in statuses) {
      if (status.id == statusId) return status;
    }
    return null;
  }

  List<BattlerStatus> statusesById(String statusId) {
    return statuses
        .where((status) => status.id == statusId)
        .toList(growable: false);
  }

  BattlerAbility? abilityById(BattlerAbilityId abilityId) {
    for (final ability in abilities) {
      if (ability.id == abilityId) return ability;
    }
    return null;
  }

  bool hasStatus(String statusId) {
    return statusById(statusId) != null;
  }

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

    return max(0, updatedValue);
  }

  int calculateDamageAgainst(Battler target) {
    // TODO: Apply thorns, damage reduction, and vampirism when their combat rules are defined.
    return max(
      1,
      calculatedStat(BattlerStat.attack) -
          target.calculatedStat(BattlerStat.defense),
    );
  }

  Battler receiveAttack(Battler attacker) {
    return receiveDirectDamage(
      attacker.calculateDamageAgainst(this),
      source: attacker,
    );
  }

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

  Battler heal(int amount) {
    final safeAmount = max(0, amount);
    return copyWith(health: min(maxHealth, health + safeAmount));
  }

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

  Battler removeStatus(String statusId) {
    if (!hasStatus(statusId)) return this;

    final updatedStatuses = statuses
        .where((status) => status.id != statusId)
        .toList(growable: false);
    return copyWith(
        statuses: List<BattlerStatus>.unmodifiable(updatedStatuses));
  }

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

  bool canAfford(int amount) => money >= amount;

  Battler earnMoney(int amount) {
    return copyWith(money: money + max(0, amount));
  }

  Battler spendMoney(int amount) {
    final safeAmount = max(0, amount);
    return copyWith(money: max(0, money - safeAmount));
  }

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

  Battler resetAllAbilities() {
    if (abilities.isEmpty) return this;

    return copyWith(
      abilities: abilities
          .map((ability) => ability.resetState())
          .toList(growable: false),
    );
  }

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

  Battler addItem(Item item) {
    final ownedEquippedItem = equippedItemOfType(item.id);
    if (ownedEquippedItem != null && ownedEquippedItem.upgradeValue > 0) {
      final updatedEquippedItems = List<Item>.from(equippedItems);
      final existingIndex = updatedEquippedItems.indexOf(ownedEquippedItem);
      updatedEquippedItems[existingIndex] = ownedEquippedItem.upgraded();
      return copyWith(
        equippedItems: List<Item>.unmodifiable(updatedEquippedItems),
      );
    }

    final ownedInventoryItem = inventoryItemOfType(item.id);
    if (ownedInventoryItem != null && ownedInventoryItem.upgradeValue > 0) {
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

  Item? equippedItemForSlot(ItemSlot slot) {
    for (final item in equippedItems) {
      if (item.slot == slot) return item;
    }
    return null;
  }

  Item? inventoryItemOfType(ItemId itemId) {
    for (final item in inventoryItems) {
      if (item.id == itemId) return item;
    }
    return null;
  }

  Item? equippedItemOfType(ItemId itemId) {
    for (final item in equippedItems) {
      if (item.id == itemId) return item;
    }
    return null;
  }

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

  Battler unequipItem(Item item) {
    if (!equippedItems.contains(item)) return this;

    final updatedEquippedItems = List<Item>.from(equippedItems)..remove(item);
    final updatedInventoryItems = List<Item>.from(inventoryItems)..add(item);

    return copyWith(
      inventoryItems: List<Item>.unmodifiable(updatedInventoryItems),
      equippedItems: List<Item>.unmodifiable(updatedEquippedItems),
    );
  }

  Battler addCombatFlag(String flag) {
    if (combatFlags.contains(flag)) return this;

    return copyWith(
      combatFlags: Set<String>.unmodifiable({
        ...combatFlags,
        flag,
      }),
    );
  }

  Battler removeCombatFlag(String flag) {
    if (!combatFlags.contains(flag)) return this;

    final updatedFlags = Set<String>.from(combatFlags)..remove(flag);
    return copyWith(
      combatFlags: Set<String>.unmodifiable(updatedFlags),
    );
  }

  Battler clearCombatFlags() {
    if (combatFlags.isEmpty) return this;

    return copyWith(combatFlags: const <String>{});
  }

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

  bool canActivateManualAbilities(
    BattlerAbilityActivationContext screenContext,
  ) {
    return manualAbilityActivationBlockReason(screenContext) == null;
  }

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

  Battler _removeExpiredStatuses() {
    if (statuses.every((status) => !status.isExpired)) return this;

    final activeStatuses =
        statuses.where((status) => !status.isExpired).toList(growable: false);
    return copyWith(statuses: List<BattlerStatus>.unmodifiable(activeStatuses));
  }

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
