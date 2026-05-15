import '../_imports.dart';

part 'battler_ability_management.dart';
part 'battler_combat_runtime.dart';
part 'battler_item_management.dart';
part 'battler_progression.dart';
part 'battler_status_management.dart';

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
        return 'Red. daño';
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

/// Identifica que tipo de eleccion concreta resuelve una subida de nivel.
enum BattlerLevelRewardChoiceType {
  stat,
  ability,
  item,
}

/// Describe una opcion seleccionable de subida de nivel.
class BattlerLevelRewardChoice {
  final BattlerLevelRewardChoiceType type;
  final BattlerLevelReward? statReward;
  final BattlerAbility? ability;
  final Item? item;

  const BattlerLevelRewardChoice.stat(BattlerLevelReward reward)
      : type = BattlerLevelRewardChoiceType.stat,
        statReward = reward,
        ability = null,
        item = null;

  const BattlerLevelRewardChoice.ability(BattlerAbility reward)
      : type = BattlerLevelRewardChoiceType.ability,
        statReward = null,
        ability = reward,
        item = null;

  const BattlerLevelRewardChoice.item(Item reward)
      : type = BattlerLevelRewardChoiceType.item,
        statReward = null,
        ability = null,
        item = reward;

  RarityTier? get rarity => ability?.rarity ?? item?.rarity;
}

/// Agrupa las opciones ya tiradas para una subida de nivel concreta.
class BattlerLevelRewardOffer {
  final int nextLevel;
  final BattlerLevelRewardChoiceType type;
  final RarityTier? rarity;
  final List<BattlerLevelRewardChoice> choices;

  const BattlerLevelRewardOffer({
    required this.nextLevel,
    required this.type,
    required this.choices,
    this.rarity,
  });
}

/// Enumera las flags globales del runtime de combate del battler.
enum BattlerCombatFlag {
  combatActive,
  manualAbilityActivatedThisTurn,
  pendingBasicAttackFollowUp,
  cycleDayContext,
  cycleNightContext,
  currentRoundMarker,
  barrierGainMarker,
  barrierBrokenThisHit,
  barrierLostThisHit,
  healthLostThisHit,
  fragilidadTriggeredThisHit,
  cortafuegosPortatilBlockedDebuff,
  opresionTacticaTriggeredThisTurn,
  copiaSeguridadUsed,
  sobrecargaReguladaPendingCooldownPenalty,
  mandatoColiseoOpeningGranted,
  mandatoColiseoCounterPreventedThisTurn,
}

/// Enumera las flags runtime que usan los items para limitar activaciones por combate.
enum ItemCombatFlagKind {
  crackedBatteryUsed,
  eclipseMantleUsed,
  eclipseMantleInitialized,
  eclipseMantleNightMode,
  operativeBlackBoxUsed,
  operativeBlackBoxProtection,
  succionaCreditosTriggeredThisTurn,
  kunaiAnchoTriggeredThisTurn,
  magnetiCHammerTriggeredThisTurn,
  clavoReactorTriggeredThisTurn,
  ultimaMarchaTriggeredThisTurn,
  responseFrameDamagedThisTurn,
  reboundLensTriggeredThisTurn,
  emergencyPlatingAutoBlockUsed,
  deflectiveCapacitorReflectedDebuff,
  nucleoPiezoelectricoTriggeredThisTurn,
  aislanteArmonicoLostHealthThisTurn,
  aislanteArmonicoTurnStartHealth,
  guanteRetoTriggered,
  ultimaPalabraTriggeredThisTurn,
  aceleradorRetoTriggered,
  thermalTurbineCombatStartTriggered,
}

/// Identifica una flag runtime concreta sin depender de claves String concatenadas.
class CombatRuntimeFlag {
  final BattlerCombatFlag? battlerFlag;
  final ItemCombatFlagKind? itemFlag;
  final ItemId? itemId;
  final String? itemInstanceId;
  final int? value;
  final int? secondaryValue;

  /// Crea una flag global asociada solo al battler.
  const CombatRuntimeFlag.battler(
    this.battlerFlag, {
    this.value,
    this.secondaryValue,
  })  : itemFlag = null,
        itemId = null,
        itemInstanceId = null;

  /// Crea una flag asociada a un item concreto o a una de sus instancias.
  const CombatRuntimeFlag.item({
    required this.itemFlag,
    required this.itemId,
    this.itemInstanceId,
    this.value,
    this.secondaryValue,
  })  : battlerFlag = null,
        assert(itemFlag != null),
        assert(itemId != null);

  /// Compara dos flags por su identidad tipada y por el item al que pertenezcan.
  @override
  bool operator ==(Object other) {
    return other is CombatRuntimeFlag &&
        other.battlerFlag == battlerFlag &&
        other.itemFlag == itemFlag &&
        other.itemId == itemId &&
        other.itemInstanceId == itemInstanceId &&
        other.value == value &&
        other.secondaryValue == secondaryValue;
  }

  /// Calcula el hash estable que permite almacenar la flag en `Set` y `Map`.
  @override
  int get hashCode => Object.hash(
        battlerFlag,
        itemFlag,
        itemId,
        itemInstanceId,
        value,
        secondaryValue,
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
    final equippedItemsByHook = <ItemEffectHook, List<Item>>{};
    var hasItemEffects = false;
    var basicAttackCount = 1;
    var equippedItemCost = 0;

    for (final item in owner.equippedItems) {
      equippedItemsByType.putIfAbsent(item.id, () => item);
      equippedItemCost++;

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

  /// Define el coste fijo en XP para cualquier subida de nivel.
  static const initialLevelUpExperienceCost = 4;

  /// Devuelve las mejoras de capacidad/patron desbloqueadas por niveles pares.
  static int evenLevelProgressionBonusFor(int level) {
    final safeLevel = min(maximumLevel, max(initialLevel, level));
    return safeLevel ~/ 2;
  }

  static const combatActiveFlag = CombatRuntimeFlag.battler(
    BattlerCombatFlag.combatActive,
  );
  static const manualAbilityActivatedThisTurnFlag = CombatRuntimeFlag.battler(
    BattlerCombatFlag.manualAbilityActivatedThisTurn,
  );
  static const pendingBasicAttackFollowUpFlag = CombatRuntimeFlag.battler(
    BattlerCombatFlag.pendingBasicAttackFollowUp,
  );
  static const cycleDayContextFlag = CombatRuntimeFlag.battler(
    BattlerCombatFlag.cycleDayContext,
  );
  static const cycleNightContextFlag = CombatRuntimeFlag.battler(
    BattlerCombatFlag.cycleNightContext,
  );
  static const barrierBrokenThisHitFlag = CombatRuntimeFlag.battler(
    BattlerCombatFlag.barrierBrokenThisHit,
  );
  static final Expando<_BattlerDerivedState> _derivedStateCache =
      Expando<_BattlerDerivedState>('battlerDerivedState');

  final String name;
  final String iconEmoji;
  final ArchetypeId? archetypeId;
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
  final Map<String, String> patternItemPointKeys;
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
    this.archetypeId,
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
    this.patternItemPointKeys = const <String, String>{},
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

  /// Devuelve la reduccion de daño base sin modificadores de equipo ni estados.
  int get baseDamageReduction => baseStat(BattlerStat.damageReduction);

  /// Devuelve la reduccion de daño ya calculada con equipo y estados.
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

  /// Devuelve el valor base de una stat sin aplicar ningun modificador.
  int baseStat(BattlerStat stat) {
    return baseStats[stat] ?? 0;
  }

  /// Calcula una stat final aplicando equipo y despues modificadores de estados.
  int calculatedStat(BattlerStat stat) =>
      _derivedState.calculatedStats[stat] ?? 0;

  /// Clona el battler cambiando cualquier parte de su estado y limitando la vida al maximo actual.
  Battler copyWith({
    String? name,
    String? iconEmoji,
    ArchetypeId? archetypeId,
    bool clearArchetypeId = false,
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
    Map<String, String>? patternItemPointKeys,
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
    final resolvedPatternItemPointKeys = Map<String, String>.unmodifiable(
      patternItemPointKeys ?? this.patternItemPointKeys,
    );
    final resolvedCombatFlags = Set<CombatRuntimeFlag>.unmodifiable(
      combatFlags ?? this.combatFlags,
    );
    return _buildResolved(
      name: name ?? this.name,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      archetypeId: clearArchetypeId ? null : archetypeId ?? this.archetypeId,
      health: max(0, health ?? this.health),
      explicitCurrentBarrier: currentBarrier,
      previousCurrentBarrier: this.currentBarrier,
      previousMaxBarrier: maxBarrier,
      wasCombatActive: this.combatFlags.contains(combatActiveFlag),
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
      patternItemPointKeys: resolvedPatternItemPointKeys,
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

  /// Calcula el coste de XP del siguiente nivel sin escalado entre niveles.
  static int _experienceCostForLevel(int level) {
    return initialLevelUpExperienceCost;
  }

  static Battler _buildResolved({
    required String name,
    required String iconEmoji,
    required ArchetypeId? archetypeId,
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
    required Map<String, String> patternItemPointKeys,
    required Set<CombatRuntimeFlag> combatFlags,
  }) {
    final seedBarrier = max(
      0,
      explicitCurrentBarrier ?? previousCurrentBarrier,
    );
    final candidate = Battler(
      name: name,
      iconEmoji: iconEmoji,
      archetypeId: archetypeId,
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
      patternItemPointKeys: patternItemPointKeys,
      combatFlags: combatFlags,
    );
    final clampedHealth = min(candidate.health, candidate.maxHealth);
    final willBeCombatActive = combatFlags.contains(combatActiveFlag);
    final resolvedCurrentBarrier = !willBeCombatActive
        ? 0
        : explicitCurrentBarrier ??
            (wasCombatActive
                ? previousCurrentBarrier +
                    (candidate.maxBarrier - previousMaxBarrier)
                : candidate.maxBarrier);
    final clampedCurrentBarrier = max(0, resolvedCurrentBarrier);
    if (clampedHealth == candidate.health &&
        clampedCurrentBarrier == candidate.currentBarrier) {
      return candidate;
    }

    return Battler(
      name: name,
      iconEmoji: iconEmoji,
      archetypeId: archetypeId,
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
      patternItemPointKeys: patternItemPointKeys,
      combatFlags: combatFlags,
    );
  }
}
