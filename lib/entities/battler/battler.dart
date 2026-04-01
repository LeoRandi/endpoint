import '../_imports.dart';
import '../../services/battler_effect_pipeline.dart';
import '../../services/run_randomizer.dart';

/// Enumera las stats base y derivadas que puede consultar un battler.
enum BattlerStat {
  health,
  attack,
  barrier,
  thorns,
  damageReduction,
  vampirism,
}

/// Expone etiquetas legibles y colores coherentes para cada stat visible.
extension BattlerStatPresentation on BattlerStat {
  String get label {
    switch (this) {
      case BattlerStat.health:
        return 'Vida';
      case BattlerStat.attack:
        return 'Ataque';
      case BattlerStat.barrier:
        return 'Barrera';
      case BattlerStat.thorns:
        return 'Espinas';
      case BattlerStat.damageReduction:
        return 'Red. dano';
      case BattlerStat.vampirism:
        return 'Vampirismo';
    }
  }

  String get shortLabel {
    switch (this) {
      case BattlerStat.health:
        return 'HP';
      case BattlerStat.attack:
        return 'ATK';
      case BattlerStat.barrier:
        return 'BAR';
      case BattlerStat.thorns:
        return 'ESP';
      case BattlerStat.damageReduction:
        return 'RED';
      case BattlerStat.vampirism:
        return 'VAMP';
    }
  }

  Color get accent {
    switch (this) {
      case BattlerStat.health:
        return const Color(0xFFFF8BA7);
      case BattlerStat.attack:
        return const Color(0xFFF3D35C);
      case BattlerStat.barrier:
        return const Color(0xFF59B7FF);
      case BattlerStat.thorns:
        return const Color(0xFF9EA7B3);
      case BattlerStat.damageReduction:
        return const Color(0xFF8BE9FD);
      case BattlerStat.vampirism:
        return const Color(0xFFFF6B6B);
    }
  }
}

/// Enumera las recompensas permanentes que el jugador puede escoger al subir de nivel.
enum BattlerLevelReward {
  income,
  attack,
  health,
}

/// Enumera las flags globales del runtime de combate del battler.
enum BattlerCombatFlag {
  combatActive,
  manualAbilityActivatedThisTurn,
  pendingBasicAttackFollowUp,
}

/// Enumera las flags runtime que usan los items para limitar activaciones por combate.
enum ItemCombatFlagKind {
  crackedBatteryUsed,
  eclipseMantleUsed,
  operativeBlackBoxUsed,
  operativeBlackBoxProtection,
}

/// Identifica una flag runtime concreta sin depender de claves String concatenadas.
class CombatRuntimeFlag {
  final BattlerCombatFlag? battlerFlag;
  final ItemCombatFlagKind? itemFlag;
  final ItemId? itemId;
  final String? itemInstanceId;

  /// Crea una flag global asociada solo al battler.
  const CombatRuntimeFlag.battler(BattlerCombatFlag flag)
      : battlerFlag = flag,
        itemFlag = null,
        itemId = null,
        itemInstanceId = null;

  /// Crea una flag asociada a un item concreto o a una de sus instancias.
  const CombatRuntimeFlag.item({
    required ItemCombatFlagKind flag,
    required ItemId itemId,
    String? itemInstanceId,
  })  : battlerFlag = null,
        itemFlag = flag,
        itemId = itemId,
        itemInstanceId = itemInstanceId;

  /// Compara dos flags por su identidad tipada y por el item al que pertenezcan.
  @override
  bool operator ==(Object other) {
    return other is CombatRuntimeFlag &&
        other.battlerFlag == battlerFlag &&
        other.itemFlag == itemFlag &&
        other.itemId == itemId &&
        other.itemInstanceId == itemInstanceId;
  }

  /// Calcula el hash estable que permite almacenar la flag en `Set` y `Map`.
  @override
  int get hashCode => Object.hash(
        battlerFlag,
        itemFlag,
        itemId,
        itemInstanceId,
      );
}

/// Registra un valor dentro de todos los buckets tipados que declara para sus hooks.
void _appendHookBindings<K extends Object, V>(
  Map<K, List<V>> index,
  Iterable<K> hooks,
  V value,
) {
  for (final hook in hooks) {
    (index[hook] ??= <V>[]).add(value);
  }
}

/// Convierte un indice mutable de hooks en una estructura inmutable reutilizable por frame.
Map<K, List<V>> _freezeHookIndex<K extends Object, V>(
  Map<K, List<V>> index,
) {
  return Map<K, List<V>>.unmodifiable(
    index.map(
      (hook, values) => MapEntry(
        hook,
        List<V>.unmodifiable(values),
      ),
    ),
  );
}

/// Agrupa los valores derivados e indices que se leen muchas veces por frame o por turno.
class _BattlerDerivedState {
  final Map<BattlerStat, int> calculatedStats;
  final int income;
  final int basicAttackCount;
  final int equippedItemCost;
  final Map<BattlerStatusId, List<BattlerStatus>> statusesById;
  final Map<BattlerStatusHook, List<BattlerStatus>> statusesByHook;
  final Map<BattlerAbilityId, BattlerAbility> abilitiesById;
  final Map<BattlerAbilityHook, List<BattlerAbilityId>> abilityIdsByHook;
  final Map<ItemId, Item> inventoryItemsByType;
  final Map<ItemId, Item> equippedItemsByType;
  final Map<ItemSlot, Item> equippedItemsBySlot;
  final Map<ItemEffectHook, List<Item>> equippedItemsByHook;
  final bool hasItemEffects;

  const _BattlerDerivedState._({
    required this.calculatedStats,
    required this.income,
    required this.basicAttackCount,
    required this.equippedItemCost,
    required this.statusesById,
    required this.statusesByHook,
    required this.abilitiesById,
    required this.abilityIdsByHook,
    required this.inventoryItemsByType,
    required this.equippedItemsByType,
    required this.equippedItemsBySlot,
    required this.equippedItemsByHook,
    required this.hasItemEffects,
  });

  factory _BattlerDerivedState.build(Battler owner) {
    final statusesById = <BattlerStatusId, List<BattlerStatus>>{};
    final statusesByHook = <BattlerStatusHook, List<BattlerStatus>>{};
    for (final status in owner.statuses) {
      (statusesById[status.id] ??= <BattlerStatus>[]).add(status);
      _appendHookBindings(statusesByHook, status.hooks, status);
    }

    final abilitiesById = <BattlerAbilityId, BattlerAbility>{
      for (final ability in owner.abilities) ability.id: ability,
    };
    final abilityIdsByHook = <BattlerAbilityHook, List<BattlerAbilityId>>{};
    for (final ability in owner.abilities) {
      _appendHookBindings(abilityIdsByHook, ability.hookBindings, ability.id);
    }
    final inventoryItemsByType = <ItemId, Item>{};
    for (final item in owner.inventoryItems) {
      inventoryItemsByType.putIfAbsent(item.id, () => item);
    }

    final equippedItemsByType = <ItemId, Item>{};
    final equippedItemsBySlot = <ItemSlot, Item>{};
    final equippedItemsByHook = <ItemEffectHook, List<Item>>{};
    var hasItemEffects = false;
    var basicAttackCount = 1;
    var equippedItemCost = 0;

    for (final item in owner.equippedItems) {
      equippedItemsByType.putIfAbsent(item.id, () => item);
      equippedItemCost += item.equipmentCost;
      if (item.slot != null) {
        equippedItemsBySlot.putIfAbsent(item.slot!, () => item);
      }

      final effect = item.effect;
      if (effect == null) continue;

      hasItemEffects = true;
      _appendHookBindings(equippedItemsByHook, effect.hooks, item);
      if (effect.hooks.contains(ItemEffectHook.basicAttackCountModifier)) {
        basicAttackCount = effect.modifyBasicAttackCount(
          owner: owner,
          item: item,
          count: basicAttackCount,
        );
      }
    }

    final incomeStatuses = statusesByHook[BattlerStatusHook.incomeModifier] ??
        const <BattlerStatus>[];
    final statStatuses =
        statusesByHook[BattlerStatusHook.calculatedStatModifier] ??
            const <BattlerStatus>[];
    final statItems =
        equippedItemsByHook[ItemEffectHook.calculatedStatModifier] ??
            const <Item>[];
    final resolvedIncomeStatuses = incomeStatuses
        .map((status) => status.resolved(owner))
        .toList(growable: false);
    final resolvedStatStatuses = statStatuses
        .map((status) => status.resolved(owner))
        .toList(growable: false);
    final calculatedStats = <BattlerStat, int>{
      for (final stat in BattlerStat.values)
        stat: Battler._calculateStat(
          baseStats: owner.baseStats,
          equippedItems: owner.equippedItems,
          stat: stat,
        ),
    };

    var income = Battler._calculateIncome(
      baseIncome: owner.baseIncome,
      equippedItems: owner.equippedItems,
    );
    for (final status in resolvedIncomeStatuses) {
      income = status.modifyIncome(
        owner: owner,
        income: income,
      );
    }

    for (final stat in BattlerStat.values) {
      var updatedValue = calculatedStats[stat] ?? 0;

      for (final status in resolvedStatStatuses) {
        updatedValue = status.modifyCalculatedStat(
          owner: owner,
          stat: stat,
          value: updatedValue,
        );
      }

      for (final item in statItems) {
        final effect = item.effect;
        if (effect == null) continue;

        updatedValue = effect.modifyCalculatedStat(
          owner: owner,
          item: item,
          stat: stat,
          value: updatedValue,
        );
      }

      calculatedStats[stat] = max(0, updatedValue);
    }

    return _BattlerDerivedState._(
      calculatedStats: Map<BattlerStat, int>.unmodifiable(calculatedStats),
      income: max(0, income),
      basicAttackCount: max(1, basicAttackCount),
      equippedItemCost: max(0, equippedItemCost),
      statusesById: Map<BattlerStatusId, List<BattlerStatus>>.unmodifiable(
        statusesById.map(
          (statusId, statuses) => MapEntry(
            statusId,
            List<BattlerStatus>.unmodifiable(statuses),
          ),
        ),
      ),
      statusesByHook: _freezeHookIndex(statusesByHook),
      abilitiesById: Map<BattlerAbilityId, BattlerAbility>.unmodifiable(
        abilitiesById,
      ),
      abilityIdsByHook: _freezeHookIndex(abilityIdsByHook),
      inventoryItemsByType:
          Map<ItemId, Item>.unmodifiable(inventoryItemsByType),
      equippedItemsByType: Map<ItemId, Item>.unmodifiable(equippedItemsByType),
      equippedItemsBySlot:
          Map<ItemSlot, Item>.unmodifiable(equippedItemsBySlot),
      equippedItemsByHook: _freezeHookIndex(equippedItemsByHook),
      hasItemEffects: hasItemEffects,
    );
  }
}

/// Representa el estado completo de un combatiente, incluyendo economia, equipo y hooks runtime.
class Battler {
  static const defaultEquipmentCapacity = 3;

  /// Marca el nivel operativo inicial que tiene cualquier battler controlado por la run.
  static const initialLevel = 1;

  /// Limita la progresion total para evitar escalado indefinido mientras no exista postgame.
  static const maximumLevel = 10;

  /// Define el coste en XP de la primera subida de nivel antes de aplicar crecimiento.
  static const initialLevelUpExperienceCost = 2;
  static const combatActiveFlag = CombatRuntimeFlag.battler(
    BattlerCombatFlag.combatActive,
  );
  static const manualAbilityActivatedThisTurnFlag = CombatRuntimeFlag.battler(
    BattlerCombatFlag.manualAbilityActivatedThisTurn,
  );
  static const pendingBasicAttackFollowUpFlag = CombatRuntimeFlag.battler(
    BattlerCombatFlag.pendingBasicAttackFollowUp,
  );
  static const BattlerEffectPipeline _effectPipeline = BattlerEffectPipeline();
  static final Expando<_BattlerDerivedState> _derivedStateCache =
      Expando<_BattlerDerivedState>('battlerDerivedState');

  final String name;
  final String iconEmoji;
  final int health;
  final int currentBarrier;
  final int money;
  final int baseIncome;
  final int equipmentCapacity;
  final int level;
  final int experience;
  final Map<BattlerStat, int> baseStats;
  final List<BattlerAbility> abilities;
  final List<BattlerStatus> statuses;
  final List<Item> inventoryItems;
  final List<Item> equippedItems;
  final Set<CombatRuntimeFlag> combatFlags;

  // Los presets de juego dependen de constructores const, asi que la cache de
  // derivados vive fuera de la instancia y se rellena a demanda por identidad.
  _BattlerDerivedState get _derivedState {
    final cachedState = _derivedStateCache[this];
    if (cachedState != null) {
      return cachedState;
    }

    final derivedState = _BattlerDerivedState.build(this);
    _derivedStateCache[this] = derivedState;
    return derivedState;
  }

  /// Crea un battler inmutable listo para combate, ruta o persistencia.
  const Battler({
    required this.name,
    this.iconEmoji = '\u{1F916}',
    required this.health,
    this.currentBarrier = 0,
    this.money = 0,
    int income = 0,
    this.equipmentCapacity = defaultEquipmentCapacity,
    this.level = initialLevel,
    this.experience = 0,
    required this.baseStats,
    this.abilities = const [],
    this.statuses = const [],
    this.inventoryItems = const [],
    this.equippedItems = const [],
    this.combatFlags = const <CombatRuntimeFlag>{},
  })  : baseIncome = income,
        assert(health >= 0),
        assert(currentBarrier >= 0),
        assert(level >= initialLevel),
        assert(experience >= 0);

  /// Devuelve la vida maxima base sin modificadores de equipo ni estados.
  int get baseMaxHealth => baseStat(BattlerStat.health);

  /// Devuelve la vida maxima ya calculada con equipo y estados.
  int get maxHealth => calculatedStat(BattlerStat.health);

  /// Devuelve el ataque base sin modificadores de equipo ni estados.
  int get baseAttack => baseStat(BattlerStat.attack);

  /// Devuelve el ataque ya calculado con equipo y estados.
  int get attack => calculatedStat(BattlerStat.attack);

  /// Devuelve la Barrera base sin modificadores de equipo ni estados.
  int get baseBarrier => baseStat(BattlerStat.barrier);

  /// Devuelve la Barrera maxima ya calculada con equipo y estados.
  int get maxBarrier => calculatedStat(BattlerStat.barrier);

  /// Reexpone la Barrera maxima como stat visible del battler.
  int get barrier => maxBarrier;

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
  int get basicAttackCount => _derivedState.basicAttackCount;

  /// Devuelve el coste total consumido por los objetos actualmente equipados.
  int get equippedItemCost => _derivedState.equippedItemCost;

  /// Devuelve cuantos puntos de capacidad de equipo siguen libres.
  int get remainingEquipmentCapacity =>
      max(0, equipmentCapacity - equippedItemCost);

  /// Indica si el battler ya alcanzo el techo de progresion actual.
  bool get isAtMaxLevel => level >= maximumLevel;

  /// Devuelve el coste de XP que exige el siguiente nivel del battler.
  int get experienceToNextLevel {
    if (isAtMaxLevel) return 0;

    return _experienceCostForLevel(level);
  }

  /// Devuelve la XP visible de este nivel, limitada al coste del siguiente salto.
  int get displayedExperience {
    if (isAtMaxLevel) return 0;

    return min(experience, experienceToNextLevel);
  }

  /// Indica si el battler ya tiene suficiente XP acumulada para abrir la subida de nivel.
  bool get canLevelUp => !isAtMaxLevel && experience >= experienceToNextLevel;

  /// Calcula el income efectivo tras aplicar equipo y estados que lo alteran.
  int get income => _derivedState.income;

  /// Indica si este battler ya no tiene vida.
  bool get isDefeated => health <= 0;

  /// Indica si al menos queda un punto de Barrera temporal durante el combate.
  bool get hasBarrier => currentBarrier > 0;

  /// Suma XP persistente fuera del combate y deja el exceso acumulado para futuros niveles.
  Battler gainExperience(int amount) {
    final safeAmount = max(0, amount);
    if (safeAmount <= 0 || isAtMaxLevel) return this;

    return copyWith(experience: experience + safeAmount);
  }

  /// Comprueba si el battler posee exactamente esa instancia de item.
  bool ownsItem(Item item) {
    return inventoryItems.contains(item) || equippedItems.contains(item);
  }

  /// Comprueba si el battler posee algun item de ese tipo, equipado o en inventario.
  bool ownsItemOfType(ItemId itemId) {
    return _derivedState.inventoryItemsByType.containsKey(itemId) ||
        _derivedState.equippedItemsByType.containsKey(itemId);
  }

  /// Comprueba si el battler ya tiene una habilidad con ese id.
  bool hasAbility(BattlerAbility ability) {
    return abilityById(ability.id) != null;
  }

  /// Indica si el battler tiene al menos una habilidad.
  bool get hasAbilities => _derivedState.abilitiesById.isNotEmpty;

  /// Indica si el battler tiene al menos un estado activo.
  bool get hasStatuses => _derivedState.statusesById.isNotEmpty;

  /// Indica si hay algun item equipado con hooks de efecto.
  bool get hasItemEffects => _derivedState.hasItemEffects;

  /// Comprueba si una flag de combate concreta sigue activa.
  bool hasCombatFlag(CombatRuntimeFlag flag) => combatFlags.contains(flag);

  /// Indica si el ataque basico actual todavia tiene impactos pendientes.
  bool get hasPendingBasicAttackFollowUp {
    return hasCombatFlag(pendingBasicAttackFollowUpFlag);
  }

  /// Devuelve el valor base de una stat sin aplicar ningun modificador.
  int baseStat(BattlerStat stat) {
    return baseStats[stat] ?? 0;
  }

  /// Busca el primer estado activo con el id indicado.
  BattlerStatus? statusById(BattlerStatusId statusId) {
    final matchingStatuses = _derivedState.statusesById[statusId];
    if (matchingStatuses == null || matchingStatuses.isEmpty) return null;

    return matchingStatuses.first;
  }

  /// Devuelve todas las instancias activas que comparten un mismo id de estado.
  List<BattlerStatus> statusesById(BattlerStatusId statusId) {
    return _derivedState.statusesById[statusId] ?? const <BattlerStatus>[];
  }

  /// Devuelve solo los estados que declararon el hook pedido en su metadata tipada.
  List<BattlerStatus> statusesForHook(BattlerStatusHook hook) {
    return _derivedState.statusesByHook[hook] ?? const <BattlerStatus>[];
  }

  /// Busca la habilidad activa con el id indicado.
  BattlerAbility? abilityById(BattlerAbilityId abilityId) {
    return _derivedState.abilitiesById[abilityId];
  }

  /// Devuelve los ids de habilidad que registraron un hook concreto para el pipeline.
  List<BattlerAbilityId> abilityIdsForHook(BattlerAbilityHook hook) {
    return _derivedState.abilityIdsByHook[hook] ?? const <BattlerAbilityId>[];
  }

  /// Comprueba si existe al menos una instancia del estado indicado.
  bool hasStatus(BattlerStatusId statusId) {
    return statusById(statusId) != null;
  }

  /// Explica por que un objeto no puede equiparse en el estado actual del battler.
  String? equipItemBlockReason(Item item) {
    if (!item.isEquippable) return 'Este objeto no se puede equipar';
    if (equippedItems.contains(item)) return 'El objeto ya esta equipado';
    if (!inventoryItems.contains(item)) {
      return 'El objeto ya no esta en tu inventario';
    }

    final nextCost = equippedItemCost + item.equipmentCost;
    if (nextCost > equipmentCapacity) {
      return 'Capacidad insuficiente: $nextCost/$equipmentCapacity';
    }

    return null;
  }

  /// Indica si el objeto cabe dentro de la capacidad de equipo disponible.
  bool canEquipItem(Item item) => equipItemBlockReason(item) == null;

  /// Devuelve solo los items equipados que declararon el hook pedido en su efecto.
  List<Item> equippedItemsForHook(ItemEffectHook hook) {
    return _derivedState.equippedItemsByHook[hook] ?? const <Item>[];
  }

  /// Calcula una stat final aplicando equipo y despues modificadores de estados.
  int calculatedStat(BattlerStat stat) =>
      _derivedState.calculatedStats[stat] ?? 0;

  /// Calcula el dano base de un ataque directo usando solo el ataque total del portador.
  int calculateDamageAgainst(Battler target) {
    // TODO: Apply thorns, damage reduction, and vampirism when their combat rules are defined.
    return max(1, calculatedStat(BattlerStat.attack));
  }

  /// Recibe un ataque basico de otro battler y resuelve dano directo.
  Battler receiveAttack(Battler attacker) {
    return receiveDirectDamage(
      attacker.calculateDamageAgainst(this),
      source: attacker,
    );
  }

  /// Consume primero Barrera activa y despues vida, disparando protecciones letales si procede.
  Battler receiveDamage(int damage) {
    final safeDamage = max(0, damage);
    if (safeDamage <= 0) return this;

    final absorbedByBarrier = min(currentBarrier, safeDamage);
    final ownerAfterBarrier = absorbedByBarrier <= 0
        ? this
        : copyWith(currentBarrier: currentBarrier - absorbedByBarrier);
    final remainingDamage = max(0, safeDamage - absorbedByBarrier);
    if (remainingDamage <= 0) {
      return ownerAfterBarrier;
    }

    final damagedOwner = ownerAfterBarrier.copyWith(
      health: max(0, ownerAfterBarrier.health - remainingDamage),
    );
    if (damagedOwner.health > 0) {
      return damagedOwner;
    }

    return damagedOwner.applyEquippedItemFatalDamageEffects(
      incomingDamage: remainingDamage,
    );
  }

  /// Procesa un impacto directo con hooks defensivos antes de restar vida.
  Battler receiveDirectDamage(
    int damage, {
    required Battler source,
  }) {
    return _effectPipeline.receiveDirectDamage(
      owner: this,
      damage: damage,
      source: source,
    );
  }

  /// Limpia solo las instancias de estado ya caducadas y deja el resto intacto.
  Battler pruneExpiredStatuses() {
    return _removeExpiredStatuses();
  }

  /// Procesa dano de debuff con hooks defensivos antes de restar vida.
  Battler receiveDebuffDamage(
    int damage, {
    required Battler source,
  }) {
    return _effectPipeline.receiveDebuffDamage(
      owner: this,
      damage: damage,
      source: source,
    );
  }

  /// Cura vida sin superar la vida maxima calculada actual.
  Battler heal(int amount) {
    final safeAmount = max(0, amount);
    return copyWith(health: min(maxHealth, health + safeAmount));
  }

  /// Activa el estado runtime de combate y rellena la Barrera temporal inicial.
  Battler prepareForCombat() {
    final preparedOwner = materializeOwnedItems().clearCombatFlags();
    return preparedOwner.copyWith(
      combatFlags: const <CombatRuntimeFlag>{
        combatActiveFlag,
      },
      currentBarrier: preparedOwner.maxBarrier,
    );
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

    final activeStatuses = List<BattlerStatus>.from(
      updatedOwner.statusesForHook(BattlerStatusHook.statusApplied),
    );

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
  Battler removeStatus(BattlerStatusId statusId) {
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
    return _effectPipeline.applyStatusTurnStart(
      owner: this,
      opponent: opponent,
      isOwnerTurn: isOwnerTurn,
      randomizer: randomizer,
    );
  }

  /// Ejecuta todos los hooks de inicio de turno de las habilidades activas.
  BattlerAbilityEffectResolution applyAbilityTurnStartEffects({
    required Battler opponent,
    required bool isOwnerTurn,
  }) {
    return _effectPipeline.applyAbilityTurnStartEffects(
      owner: this,
      opponent: opponent,
      isOwnerTurn: isOwnerTurn,
    );
  }

  /// Ejecuta todos los hooks de final de turno de los estados activos.
  Battler applyStatusTurnEnd({
    required Battler opponent,
    required bool isOwnerTurn,
    RunRandomizer? randomizer,
  }) {
    return _effectPipeline.applyStatusTurnEnd(
      owner: this,
      opponent: opponent,
      isOwnerTurn: isOwnerTurn,
      randomizer: randomizer,
    );
  }

  /// Ejecuta todos los hooks de final de turno de las habilidades activas.
  BattlerAbilityEffectResolution applyAbilityTurnEndEffects({
    required Battler opponent,
    required bool isOwnerTurn,
  }) {
    return _effectPipeline.applyAbilityTurnEndEffects(
      owner: this,
      opponent: opponent,
      isOwnerTurn: isOwnerTurn,
    );
  }

  /// Aplica a un dano saliente todos los modificadores provenientes de estados.
  int applyOutgoingDamageModifiers({
    required Battler target,
    required int damage,
  }) {
    return _effectPipeline.applyOutgoingDamageModifiers(
      owner: this,
      target: target,
      damage: damage,
    );
  }

  /// Aplica a un dano saliente todos los modificadores de items equipados.
  int applyEquippedItemOutgoingDamageModifiers({
    required Battler target,
    required int damage,
  }) {
    return _effectPipeline.applyEquippedItemOutgoingDamageModifiers(
      owner: this,
      target: target,
      damage: damage,
    );
  }

  /// Permite a los items equipados alterar o cancelar un estado que se va a aplicar.
  BattlerStatus? applyEquippedItemOutgoingStatusModifiers({
    required Battler target,
    required BattlerStatus status,
  }) {
    return _effectPipeline.applyEquippedItemOutgoingStatusModifiers(
      owner: this,
      target: target,
      status: status,
    );
  }

  /// Aplica a un dano saliente todos los modificadores provenientes de habilidades.
  int applyAbilityOutgoingDamageModifiers({
    required Battler target,
    required int damage,
  }) {
    return _effectPipeline.applyAbilityOutgoingDamageModifiers(
      owner: this,
      target: target,
      damage: damage,
    );
  }

  /// Aplica a un dano entrante todos los modificadores provenientes de estados.
  int applyIncomingDamageModifiers({
    required Battler source,
    required int damage,
  }) {
    return _effectPipeline.applyIncomingDamageModifiers(
      owner: this,
      source: source,
      damage: damage,
    );
  }

  /// Ejecuta hooks defensivos complejos de estados sobre un dano entrante.
  BattlerIncomingDamageResolution applyIncomingDamageEffects({
    required Battler source,
    required int damage,
    required DamageKind kind,
  }) {
    return _effectPipeline.applyIncomingDamageEffects(
      owner: this,
      source: source,
      damage: damage,
      kind: kind,
    );
  }

  /// Aplica a un dano entrante todos los modificadores de items equipados.
  int applyEquippedItemIncomingDamageModifiers({
    required Battler source,
    required int damage,
  }) {
    return _effectPipeline.applyEquippedItemIncomingDamageModifiers(
      owner: this,
      source: source,
      damage: damage,
    );
  }

  /// Permite a los items equipados alterar o cancelar un estado recibido.
  BattlerStatus? applyEquippedItemIncomingStatusModifiers({
    required Battler source,
    required BattlerStatus status,
  }) {
    return _effectPipeline.applyEquippedItemIncomingStatusModifiers(
      owner: this,
      source: source,
      status: status,
    );
  }

  /// Aplica a un dano entrante todos los modificadores provenientes de habilidades.
  int applyAbilityIncomingDamageModifiers({
    required Battler source,
    required int damage,
  }) {
    return _effectPipeline.applyAbilityIncomingDamageModifiers(
      owner: this,
      source: source,
      damage: damage,
    );
  }

  /// Ejecuta efectos de estados que reaccionan despues de que el portador ataque.
  Battler applyAttackResolvedEffects({
    required Battler target,
    required int damageDealt,
  }) {
    return _effectPipeline.applyAttackResolvedEffects(
      owner: this,
      target: target,
      damageDealt: damageDealt,
    );
  }

  /// Ejecuta efectos de items equipados que reaccionan despues de atacar.
  ItemEffectResolution applyEquippedItemAttackResolvedEffects({
    required Battler target,
    required int damageDealt,
  }) {
    return _effectPipeline.applyEquippedItemAttackResolvedEffects(
      owner: this,
      target: target,
      damageDealt: damageDealt,
    );
  }

  /// Ejecuta efectos de habilidades que reaccionan despues de atacar.
  BattlerAbilityEffectResolution applyAbilityAttackResolvedEffects({
    required Battler target,
    required int damageDealt,
  }) {
    return _effectPipeline.applyAbilityAttackResolvedEffects(
      owner: this,
      target: target,
      damageDealt: damageDealt,
    );
  }

  /// Ejecuta efectos de estados que reaccionan despues de recibir dano.
  Battler applyReceiveDamageResolvedEffects({
    required Battler source,
    required int damageTaken,
  }) {
    return _effectPipeline.applyReceiveDamageResolvedEffects(
      owner: this,
      source: source,
      damageTaken: damageTaken,
    );
  }

  /// Ejecuta efectos de items equipados que reaccionan despues de recibir dano.
  ItemEffectResolution applyEquippedItemReceiveDamageResolvedEffects({
    required Battler source,
    required int damageTaken,
  }) {
    return _effectPipeline.applyEquippedItemReceiveDamageResolvedEffects(
      owner: this,
      source: source,
      damageTaken: damageTaken,
    );
  }

  /// Ejecuta efectos de habilidades que reaccionan despues de recibir dano.
  BattlerAbilityEffectResolution applyAbilityReceiveDamageResolvedEffects({
    required Battler source,
    required int damageTaken,
  }) {
    return _effectPipeline.applyAbilityReceiveDamageResolvedEffects(
      owner: this,
      source: source,
      damageTaken: damageTaken,
    );
  }

  /// Ejecuta efectos de inicio de turno para todos los items equipados.
  ItemEffectResolution applyEquippedItemTurnStartEffects({
    required Battler opponent,
    required bool isOwnerTurn,
  }) {
    return _effectPipeline.applyEquippedItemTurnStartEffects(
      owner: this,
      opponent: opponent,
      isOwnerTurn: isOwnerTurn,
    );
  }

  /// Ejecuta efectos de final de turno para todos los items equipados.
  ItemEffectResolution applyEquippedItemTurnEndEffects({
    required Battler opponent,
    required bool isOwnerTurn,
  }) {
    return _effectPipeline.applyEquippedItemTurnEndEffects(
      owner: this,
      opponent: opponent,
      isOwnerTurn: isOwnerTurn,
    );
  }

  /// Ejecuta efectos pasivos de todos los items equipados.
  ItemEffectResolution applyEquippedItemPassiveEffects({
    required Battler opponent,
  }) {
    return _effectPipeline.applyEquippedItemPassiveEffects(
      owner: this,
      opponent: opponent,
    );
  }

  /// Permite que los items modifiquen una habilidad justo antes de activarla manualmente.
  ItemAbilityPreparationResolution applyEquippedItemManualAbilityPreparation({
    required Battler opponent,
    required BattlerAbility ability,
    required BattlerAbilityActivationContext screenContext,
  }) {
    return _effectPipeline.applyEquippedItemManualAbilityPreparation(
      owner: this,
      opponent: opponent,
      ability: ability,
      screenContext: screenContext,
    );
  }

  /// Ejecuta reacciones de items cuando una habilidad ya se ha resuelto.
  ItemEffectResolution applyEquippedItemAbilityResolvedEffects({
    required Battler opponent,
    required BattlerAbility previousAbility,
    required ItemAbilityResolutionContext context,
  }) {
    return _effectPipeline.applyEquippedItemAbilityResolvedEffects(
      owner: this,
      opponent: opponent,
      previousAbility: previousAbility,
      context: context,
    );
  }

  /// Ejecuta todos los efectos pasivos de habilidades activas o presentes.
  BattlerAbilityEffectResolution applyAbilityPassiveEffects({
    required Battler opponent,
  }) {
    return _effectPipeline.applyAbilityPassiveEffects(
      owner: this,
      opponent: opponent,
    );
  }

  /// Ejecuta todos los hooks de fin de combate antes de limpiar estado runtime.
  Battler applyCombatEndEffects() {
    return _effectPipeline.applyCombatEndEffects(owner: this);
  }

  /// Permite a los items equipados interceptar un golpe letal antes de morir.
  Battler applyEquippedItemFatalDamageEffects({
    required int incomingDamage,
  }) {
    return _effectPipeline.applyEquippedItemFatalDamageEffects(
      owner: this,
      incomingDamage: incomingDamage,
    );
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
    return _effectPipeline.toggleAbilityActivation(
      owner: this,
      abilityId: abilityId,
      screenContext: screenContext,
      opponent: opponent,
    );
  }

  /// Anade un item nuevo o mejora la copia ya poseida si admite upgrades.
  Battler addItem(Item item) {
    final upgradeTemplate = item.canUpgrade ? item : Item.presetForId(item.id);
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
    return _derivedState.equippedItemsBySlot[slot];
  }

  /// Busca en inventario el primer item de un tipo concreto.
  Item? inventoryItemOfType(ItemId itemId) {
    return _derivedState.inventoryItemsByType[itemId];
  }

  /// Busca entre los items equipados el primero de un tipo concreto.
  Item? equippedItemOfType(ItemId itemId) {
    return _derivedState.equippedItemsByType[itemId];
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

  /// Equipa un item del inventario si su coste cabe dentro de la capacidad disponible.
  Battler equipItem(Item item) {
    if (!canEquipItem(item)) return this;

    final updatedInventoryItems = List<Item>.from(inventoryItems)..remove(item);
    final updatedEquippedItems = List<Item>.from(equippedItems);
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
  Battler addCombatFlag(CombatRuntimeFlag flag) {
    if (combatFlags.contains(flag)) return this;

    return copyWith(
      combatFlags: Set<CombatRuntimeFlag>.unmodifiable({
        ...combatFlags,
        flag,
      }),
    );
  }

  /// Elimina una flag de combate concreta si estaba activa.
  Battler removeCombatFlag(CombatRuntimeFlag flag) {
    if (!combatFlags.contains(flag)) return this;

    final updatedFlags = Set<CombatRuntimeFlag>.from(combatFlags)..remove(flag);
    return copyWith(
      combatFlags: Set<CombatRuntimeFlag>.unmodifiable(updatedFlags),
    );
  }

  /// Limpia todas las flags temporales de combate.
  Battler clearCombatFlags() {
    if (combatFlags.isEmpty) return this;

    return copyWith(combatFlags: const <CombatRuntimeFlag>{});
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

  /// Cierra el estado de combate una sola vez y deja el battler listo para volver a ruta.
  Battler finalizeCombatState() {
    final ownerAfterHooks =
        hasCombatFlag(combatActiveFlag) ? applyCombatEndEffects() : this;

    return ownerAfterHooks
        .clearCombatStatuses()
        .resetAbilitiesForContext(
          BattlerAbilityActivationContext.battle,
        )
        .copyWith(currentBarrier: 0)
        .clearCombatFlags();
  }

  /// Devuelve el primer motivo por el que una activacion manual esta bloqueada.
  String? manualAbilityActivationBlockReason(
    BattlerAbilityActivationContext screenContext,
  ) {
    for (final status
        in statusesForHook(BattlerStatusHook.manualAbilityActivationBlocker)) {
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

  /// Consume una subida de nivel pendiente, aplica la mejora base y la recompensa elegida.
  Battler applyLevelReward(BattlerLevelReward reward) {
    if (!canLevelUp) return this;

    final requiredExperience = experienceToNextLevel;
    final nextLevel = min(maximumLevel, level + 1);
    final updatedBaseStats = Map<BattlerStat, int>.from(baseStats);
    var attackGain = 1;
    var healthGain = 10;
    var incomeGain = 0;

    switch (reward) {
      case BattlerLevelReward.income:
        incomeGain = 1;
        break;
      case BattlerLevelReward.attack:
        attackGain += 1;
        break;
      case BattlerLevelReward.health:
        healthGain += 10;
        break;
    }

    updatedBaseStats[BattlerStat.attack] =
        max(0, (updatedBaseStats[BattlerStat.attack] ?? 0) + attackGain);
    updatedBaseStats[BattlerStat.health] =
        max(0, (updatedBaseStats[BattlerStat.health] ?? 0) + healthGain);

    final remainingExperience =
        nextLevel >= maximumLevel ? 0 : max(0, experience - requiredExperience);

    return copyWith(
      health: health + healthGain,
      income: baseIncome + incomeGain,
      equipmentCapacity: equipmentCapacity + 1,
      level: nextLevel,
      experience: remainingExperience,
      baseStats: Map<BattlerStat, int>.unmodifiable(updatedBaseStats),
    );
  }

  /// Clona el battler cambiando cualquier parte de su estado y limitando la vida al maximo actual.
  Battler copyWith({
    String? name,
    String? iconEmoji,
    int? health,
    int? currentBarrier,
    int? money,
    int? income,
    int? equipmentCapacity,
    int? level,
    int? experience,
    Map<BattlerStat, int>? baseStats,
    List<BattlerAbility>? abilities,
    List<BattlerStatus>? statuses,
    List<Item>? inventoryItems,
    List<Item>? equippedItems,
    Set<CombatRuntimeFlag>? combatFlags,
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
    final resolvedCombatFlags = Set<CombatRuntimeFlag>.unmodifiable(
      combatFlags ?? this.combatFlags,
    );
    return _buildResolved(
      name: name ?? this.name,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      health: max(0, health ?? this.health),
      explicitCurrentBarrier: currentBarrier,
      previousCurrentBarrier: this.currentBarrier,
      previousMaxBarrier: maxBarrier,
      wasCombatActive: hasCombatFlag(combatActiveFlag),
      money: max(0, money ?? this.money),
      income: max(0, income ?? baseIncome),
      equipmentCapacity: max(0, equipmentCapacity ?? this.equipmentCapacity),
      level: max(initialLevel, level ?? this.level),
      experience: max(0, experience ?? this.experience),
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

  /// Calcula el coste de XP del siguiente nivel aplicando crecimiento del 50% y redondeo hacia arriba.
  static int _experienceCostForLevel(int level) {
    var cost = initialLevelUpExperienceCost;
    for (var currentLevel = initialLevel;
        currentLevel < level;
        currentLevel++) {
      cost = (cost * 1.5).ceil();
    }

    return max(initialLevelUpExperienceCost, cost);
  }

  static Battler _buildResolved({
    required String name,
    required String iconEmoji,
    required int health,
    required int? explicitCurrentBarrier,
    required int previousCurrentBarrier,
    required int previousMaxBarrier,
    required bool wasCombatActive,
    required int money,
    required int income,
    required int equipmentCapacity,
    required int level,
    required int experience,
    required Map<BattlerStat, int> baseStats,
    required List<BattlerAbility> abilities,
    required List<BattlerStatus> statuses,
    required List<Item> inventoryItems,
    required List<Item> equippedItems,
    required Set<CombatRuntimeFlag> combatFlags,
  }) {
    final seedBarrier = max(
      0,
      explicitCurrentBarrier ?? previousCurrentBarrier,
    );
    final candidate = Battler(
      name: name,
      iconEmoji: iconEmoji,
      health: health,
      currentBarrier: seedBarrier,
      money: money,
      income: income,
      equipmentCapacity: equipmentCapacity,
      level: min(maximumLevel, max(initialLevel, level)),
      experience: min(maximumLevel, max(initialLevel, level)) >= maximumLevel
          ? 0
          : max(0, experience),
      baseStats: baseStats,
      abilities: abilities,
      statuses: statuses,
      inventoryItems: inventoryItems,
      equippedItems: equippedItems,
      combatFlags: combatFlags,
    );
    final clampedHealth = min(candidate.health, candidate.maxHealth);
    final willBeCombatActive = combatFlags.contains(combatActiveFlag);
    final resolvedCurrentBarrier = !willBeCombatActive
        ? 0
        : explicitCurrentBarrier != null
            ? explicitCurrentBarrier
            : wasCombatActive
                ? previousCurrentBarrier +
                    (candidate.maxBarrier - previousMaxBarrier)
                : candidate.maxBarrier;
    final clampedCurrentBarrier = min(
      candidate.maxBarrier,
      max(0, resolvedCurrentBarrier),
    );
    if (clampedHealth == candidate.health &&
        clampedCurrentBarrier == candidate.currentBarrier) {
      return candidate;
    }

    return Battler(
      name: name,
      iconEmoji: iconEmoji,
      health: clampedHealth,
      currentBarrier: clampedCurrentBarrier,
      money: money,
      income: income,
      equipmentCapacity: equipmentCapacity,
      level: min(maximumLevel, max(initialLevel, level)),
      experience: min(maximumLevel, max(initialLevel, level)) >= maximumLevel
          ? 0
          : max(0, experience),
      baseStats: baseStats,
      abilities: abilities,
      statuses: statuses,
      inventoryItems: inventoryItems,
      equippedItems: equippedItems,
      combatFlags: combatFlags,
    );
  }
}
