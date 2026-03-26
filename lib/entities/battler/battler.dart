import '_imports.dart';

enum BattlerStat {
  health,
  attack,
  defense,
  thorns,
  damageReduction,
  vampirism,
}

class Battler {
  final String name;
  final String iconEmoji;
  final int health;
  final int money;
  final int income;
  final Map<BattlerStat, int> baseStats;
  final List<BattlerAbility> abilities;
  final List<BattlerStatus> statuses;
  final List<Item> inventoryItems;
  final List<Item> equippedItems;

  const Battler({
    required this.name,
    this.iconEmoji = '\u{1F916}',
    required this.health,
    this.money = 0,
    this.income = 0,
    required this.baseStats,
    this.abilities = const [],
    this.statuses = const [],
    this.inventoryItems = const [],
    this.equippedItems = const [],
  }) : assert(health >= 0);

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
    return _calculateStat(
      baseStats: baseStats,
      equippedItems: equippedItems,
      stat: stat,
    );
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
    return receiveDamage(attacker.calculateDamageAgainst(this));
  }

  Battler receiveDamage(int damage) {
    final safeDamage = max(0, damage);
    return copyWith(health: max(0, health - safeDamage));
  }

  Battler heal(int amount) {
    final safeAmount = max(0, amount);
    return copyWith(health: min(maxHealth, health + safeAmount));
  }

  Battler applyStatus(BattlerStatus status) {
    var updatedOwner = this;
    var instancedStatus = status.copyWith();
    final activeStatuses = List<BattlerStatus>.from(updatedOwner.statuses);

    for (final activeStatus in activeStatuses) {
      final resolvedStatus = activeStatus.resolved(updatedOwner);
      final resolution = resolvedStatus.onStatusApplied(
        owner: updatedOwner,
        appliedStatus: instancedStatus,
      );
      updatedOwner = resolution.owner;
      instancedStatus = resolution.appliedStatus.copyWith();
    }

    final updatedStatuses = List<BattlerStatus>.from(updatedOwner.statuses);
    if (instancedStatus.canStack) {
      updatedStatuses.add(instancedStatus);
      return updatedOwner
          .copyWith(
            statuses: List<BattlerStatus>.unmodifiable(updatedStatuses),
          )
          ._removeExpiredStatuses();
    }

    final existingIndex = updatedStatuses.indexWhere(
      (activeStatus) =>
          activeStatus.id == instancedStatus.id && !activeStatus.canStack,
    );

    if (existingIndex >= 0) {
      updatedStatuses[existingIndex] = instancedStatus;
    } else {
      updatedStatuses.add(instancedStatus);
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
      final resolvedAbility = updatedOwner.abilityById(ability.id);
      final effect = resolvedAbility?.effect;
      if (resolvedAbility == null || effect == null) continue;

      final resolution = effect.onTurnStart(
        owner: updatedOwner,
        opponent: updatedOpponent,
        ability: resolvedAbility,
        isOwnerTurn: isOwnerTurn,
      );
      updatedOwner = resolution.owner;
      updatedOpponent = resolution.opponent;
    }

    return BattlerAbilityEffectResolution(
      owner: updatedOwner._removeExpiredStatuses(),
      opponent: updatedOpponent._removeExpiredStatuses(),
    );
  }

  Battler applyStatusTurnEnd({
    required Battler opponent,
    required bool isOwnerTurn,
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
      final resolvedAbility = updatedOwner.abilityById(ability.id);
      final effect = resolvedAbility?.effect;
      if (resolvedAbility == null || effect == null) continue;

      final resolution = effect.onTurnEnd(
        owner: updatedOwner,
        opponent: updatedOpponent,
        ability: resolvedAbility,
        isOwnerTurn: isOwnerTurn,
      );
      updatedOwner = resolution.owner;
      updatedOpponent = resolution.opponent;
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

    for (final item in updatedOwner.equippedItems) {
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
      final resolvedAbility = updatedOwner.abilityById(ability.id);
      final effect = resolvedAbility?.effect;
      if (resolvedAbility == null || effect == null) continue;

      final resolution = effect.onAttackResolved(
        owner: updatedOwner,
        target: updatedTarget,
        ability: resolvedAbility,
        damageDealt: damageDealt,
      );
      updatedOwner = resolution.owner;
      updatedTarget = resolution.opponent;
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

    for (final item in updatedOwner.equippedItems) {
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
      final resolvedAbility = updatedOwner.abilityById(ability.id);
      final effect = resolvedAbility?.effect;
      if (resolvedAbility == null || effect == null) continue;

      final resolution = effect.onReceiveDamageResolved(
        owner: updatedOwner,
        source: updatedSource,
        ability: resolvedAbility,
        damageTaken: damageTaken,
      );
      updatedOwner = resolution.owner;
      updatedSource = resolution.opponent;
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

    for (final item in updatedOwner.equippedItems) {
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

    for (final item in updatedOwner.equippedItems) {
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

    for (final item in updatedOwner.equippedItems) {
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

    final activatedOwner = updateAbility(currentAbility.activate());
    final activatedAbility = activatedOwner.abilityById(abilityId);
    final effect = activatedAbility?.effect;
    if (activatedAbility == null || effect == null) {
      return BattlerAbilityEffectResolution(
        owner: activatedOwner,
        opponent: resolvedOpponent,
      );
    }

    return effect.onManualActivation(
      owner: activatedOwner,
      opponent: resolvedOpponent,
      ability: activatedAbility,
      screenContext: screenContext,
    );
  }

  Battler addItem(Item item) {
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
  }) {
    final resolvedBaseStats = baseStats ?? this.baseStats;
    final resolvedStatuses = List<BattlerStatus>.unmodifiable(
      statuses ?? this.statuses,
    );
    final resolvedInventoryItems = List<Item>.unmodifiable(
      inventoryItems ?? this.inventoryItems,
    );
    final resolvedEquippedItems = List<Item>.unmodifiable(
      equippedItems ?? this.equippedItems,
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
      income: max(0, income ?? this.income),
      baseStats: resolvedBaseStats,
      abilities: List<BattlerAbility>.unmodifiable(abilities ?? this.abilities),
      statuses: resolvedStatuses,
      inventoryItems: resolvedInventoryItems,
      equippedItems: resolvedEquippedItems,
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

    return max(0, baseValue + equipmentBonus);
  }
}
