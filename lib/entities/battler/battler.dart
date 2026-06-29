import '_imports.dart';

part '../battler_runtime_port.dart';
part 'battler_augment_management.dart';
part 'battler_combat_runtime.dart';
part 'battler_item_management.dart';
part 'battler_progression.dart';
part 'battler_status_management.dart';

/// Enumera las stats base y derivadas que puede consultar un battler.
enum BattlerStat {
  health,
  attack,
  barrier,
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
  augment,
  item,
}

enum PurgeDoctrine {
  embrace,
  wayOut,
}

/// Describe una opcion seleccionable de subida de nivel.
class BattlerLevelRewardChoice {
  final BattlerLevelRewardChoiceType type;
  final BattlerLevelReward? statReward;
  final Augment? augment;
  final Item? item;

  /// Crea una opcion que aplica una mejora permanente de stat.
  const BattlerLevelRewardChoice.stat(BattlerLevelReward reward)
      : type = BattlerLevelRewardChoiceType.stat,
        statReward = reward,
        augment = null,
        item = null;

  /// Crea una opcion que entrega o mejora un aumento.
  const BattlerLevelRewardChoice.augment(Augment reward)
      : type = BattlerLevelRewardChoiceType.augment,
        statReward = null,
        augment = reward,
        item = null;

  /// Crea una opcion que entrega o mejora un item.
  const BattlerLevelRewardChoice.item(Item reward)
      : type = BattlerLevelRewardChoiceType.item,
        statReward = null,
        augment = null,
        item = reward;

  /// Devuelve la rareza de la recompensa cuando la opcion trae contenido.
  RarityTier? get rarity => augment?.rarity ?? item?.rarity;
}

/// Agrupa las opciones ya tiradas para una subida de nivel concreta.
class BattlerLevelRewardOffer {
  final int nextLevel;
  final BattlerLevelRewardChoiceType type;
  final RarityTier? rarity;
  final List<BattlerLevelRewardChoice> choices;

  /// Crea una oferta inmutable de recompensas para el siguiente nivel.
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
  pendingBasicAttackFollowUp,
  cycleDayContext,
  cycleNightContext,
  currentRoundMarker,
  barrierGainMarker,
  barrierBrokenThisHit,
  barrierLostThisHit,
  healthLostThisHit,
  fragilidadTriggeredThisHit,
  removedWallBlockingPointDebt,
  creditsSpentThisCombat,
  itemActionResolved,
  itemAttackActionResolved,
  augmentPatternWeaponAttackBoost,
  itemBarrierActionBoost,
}

/// Identifica una flag runtime concreta sin depender de claves String concatenadas.
class CombatRuntimeFlag {
  final BattlerCombatFlag? battlerFlag;
  final String? itemEffectKey;
  final String? itemKey;
  final String? itemInstanceId;
  final int? value;
  final int? secondaryValue;

  /// Crea una flag global asociada solo al battler.
  const CombatRuntimeFlag.battler(
    this.battlerFlag, {
    this.value,
    this.secondaryValue,
  })  : itemEffectKey = null,
        itemKey = null,
        itemInstanceId = null;

  /// Crea una flag asociada a un item concreto o a una de sus instancias.
  const CombatRuntimeFlag.item({
    required this.itemEffectKey,
    required this.itemKey,
    this.itemInstanceId,
    this.value,
    this.secondaryValue,
  })  : battlerFlag = null,
        assert(itemEffectKey != ''),
        assert(itemKey != null);

  /// Compara dos flags por su identidad tipada y por el item al que pertenezcan.
  @override
  bool operator ==(Object other) {
    return other is CombatRuntimeFlag &&
        other.battlerFlag == battlerFlag &&
        other.itemEffectKey == itemEffectKey &&
        other.itemKey == itemKey &&
        other.itemInstanceId == itemInstanceId &&
        other.value == value &&
        other.secondaryValue == secondaryValue;
  }

  /// Calcula el hash estable que permite almacenar la flag en `Set` y `Map`.
  @override
  int get hashCode => Object.hash(
        battlerFlag,
        itemEffectKey,
        itemKey,
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
  final Map<int, Augment> augmentsById;
  final Map<String, Item> inventoryItemsByType;
  final Map<String, Item> equippedItemsByType;
  final Map<ItemEffectHook, List<Item>> equippedItemsByHook;
  final bool hasItemEffects;

  const _BattlerDerivedState._({
    required this.calculatedStats,
    required this.income,
    required this.basicAttackCount,
    required this.equippedItemCost,
    required this.statusesById,
    required this.statusesByHook,
    required this.augmentsById,
    required this.inventoryItemsByType,
    required this.equippedItemsByType,
    required this.equippedItemsByHook,
    required this.hasItemEffects,
  });

  /// Construye indices derivados para consultas frecuentes de combate y equipo.
  ///
  /// Mantiene el coste de agrupar hooks, ids y stats calculadas fuera de cada
  /// getter publico del Battler.
  factory _BattlerDerivedState.build(Battler owner) {
    final statusesById = <BattlerStatusId, List<BattlerStatus>>{};
    final statusesByHook = <BattlerStatusHook, List<BattlerStatus>>{};
    for (final status in owner.statuses) {
      (statusesById[status.id] ??= <BattlerStatus>[]).add(status);
      _appendHookBindings(statusesByHook, status.hooks, status);
    }

    final augmentsById = <int, Augment>{
      for (final augment in owner.augments) augment.id: augment,
    };
    final inventoryItemsByType = <String, Item>{};
    for (final item in owner.inventoryItems) {
      inventoryItemsByType.putIfAbsent(item.catalogKey, () => item);
    }

    final equippedItemsByType = <String, Item>{};
    final equippedItemsByHook = <ItemEffectHook, List<Item>>{};
    var hasItemEffects = false;
    var basicAttackCount = 1;
    var equippedItemCost = 0;

    for (final item in owner.equippedItems) {
      equippedItemsByType.putIfAbsent(item.catalogKey, () => item);
      equippedItemCost++;

      final passiveEffects = item.passiveEffects;
      if (passiveEffects.isNotEmpty) {
        hasItemEffects = true;
        for (final hook
            in passiveEffects.map((effect) => effect.hook).toSet()) {
          _appendHookBindings(
              equippedItemsByHook, <ItemEffectHook>[hook], item);
        }
        for (final effect in passiveEffects.where(
          (effect) => effect.hook == ItemEffectHook.basicAttackCountModifier,
        )) {
          basicAttackCount += effect.value;
        }
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
        for (final effect in item.passiveEffects.where(
          (effect) => effect.hook == ItemEffectHook.calculatedStatModifier,
        )) {
          updatedValue += effect.value;
        }
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
      augmentsById: Map<int, Augment>.unmodifiable(augmentsById),
      inventoryItemsByType:
          Map<String, Item>.unmodifiable(inventoryItemsByType),
      equippedItemsByType: Map<String, Item>.unmodifiable(equippedItemsByType),
      equippedItemsByHook: _freezeHookIndex(equippedItemsByHook),
      hasItemEffects: hasItemEffects,
    );
  }
}

/// Representa el estado completo de un combatiente, incluyendo economia, equipo y hooks runtime.
class Battler {
  static const defaultEquipmentCapacity = 3;
  static const maxInventoryItems = 10;
  static const defaultEnemyImageAsset =
      'assets/sprites/monsters/Debt roach128.png';

  /// Marca el nivel operativo inicial que tiene cualquier battler controlado por la run.
  static const initialLevel = 1;

  /// Limite practico alto para que la progresion pueda seguir ciclando durante la run.
  static const maximumLevel = 999;

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
  final String? imageAsset;
  final ArchetypeId? archetypeId;
  final int health;
  final int currentBarrier;
  final int money;
  final int baseIncome;
  final int equipmentCapacity;
  final int level;
  final int experience;
  final Map<BattlerStat, int> baseStats;
  final List<Augment> augments;
  final List<BattlerStatus> statuses;
  final List<Item> inventoryItems;
  final List<Item> equippedItems;
  final Map<String, String> patternItemPointKeys;
  final String? reinforcedPatternPointKey;
  final PurgeDoctrine? purgeDoctrine;
  final List<OperativePatternWallSegment> combatWallSegments;
  final Set<String> combatBlockedPointKeys;
  final List<OperativePatternWallSegment> temporaryCombatWallSegments;
  final List<OperativePatternWallSegment> queuedTemporaryCombatWallSegments;
  final int combatDestroyedWallCount;
  final Set<CombatRuntimeFlag> combatFlags;

  /// Devuelve los indices calculados de esta instancia usando cache por identidad.
  ///
  /// Los presets de juego dependen de constructores const, asi que la cache de
  /// derivados vive fuera de la instancia y se rellena a demanda.
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
    this.imageAsset = defaultEnemyImageAsset,
    this.archetypeId,
    required this.health,
    this.currentBarrier = 0,
    this.money = 0,
    int income = 0,
    this.equipmentCapacity = defaultEquipmentCapacity,
    this.level = initialLevel,
    this.experience = 0,
    required this.baseStats,
    this.augments = const [],
    this.statuses = const [],
    this.inventoryItems = const [],
    this.equippedItems = const [],
    this.patternItemPointKeys = const <String, String>{},
    this.reinforcedPatternPointKey,
    this.purgeDoctrine,
    this.combatWallSegments = const <OperativePatternWallSegment>[],
    this.combatBlockedPointKeys = const <String>{},
    this.temporaryCombatWallSegments = const <OperativePatternWallSegment>[],
    this.queuedTemporaryCombatWallSegments =
        const <OperativePatternWallSegment>[],
    this.combatDestroyedWallCount = 0,
    this.combatFlags = const <CombatRuntimeFlag>{},
  })  : baseIncome = income,
        assert(health >= 0),
        assert(currentBarrier >= 0),
        assert(level >= initialLevel),
        assert(experience >= 0),
        assert(combatDestroyedWallCount >= 0);

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
    String? imageAsset,
    bool clearImageAsset = false,
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
    List<Augment>? augments,
    List<BattlerStatus>? statuses,
    List<Item>? inventoryItems,
    List<Item>? equippedItems,
    Map<String, String>? patternItemPointKeys,
    String? reinforcedPatternPointKey,
    bool clearReinforcedPatternPointKey = false,
    PurgeDoctrine? purgeDoctrine,
    bool clearPurgeDoctrine = false,
    List<OperativePatternWallSegment>? combatWallSegments,
    Set<String>? combatBlockedPointKeys,
    List<OperativePatternWallSegment>? temporaryCombatWallSegments,
    List<OperativePatternWallSegment>? queuedTemporaryCombatWallSegments,
    int? combatDestroyedWallCount,
    Set<CombatRuntimeFlag>? combatFlags,
  }) {
    final resolvedBaseStats = baseStats ?? this.baseStats;
    final resolvedStatuses = List<BattlerStatus>.unmodifiable(
      statuses ?? this.statuses,
    );
    final resolvedAugments = List<Augment>.unmodifiable(
      augments ?? this.augments,
    );
    final resolvedInventoryItems = List<Item>.unmodifiable(
      (inventoryItems ?? this.inventoryItems).take(maxInventoryItems),
    );
    final resolvedEquippedItems = List<Item>.unmodifiable(
      equippedItems ?? this.equippedItems,
    );
    final resolvedPatternItemPointKeys = Map<String, String>.unmodifiable(
      patternItemPointKeys ?? this.patternItemPointKeys,
    );
    final resolvedCombatWallSegments =
        List<OperativePatternWallSegment>.unmodifiable(
      _deduplicateWallSegments(combatWallSegments ?? this.combatWallSegments),
    );
    final resolvedCombatBlockedPointKeys = Set<String>.unmodifiable(
      combatBlockedPointKeys ?? this.combatBlockedPointKeys,
    );
    final resolvedTemporaryCombatWallSegments =
        List<OperativePatternWallSegment>.unmodifiable(
      _deduplicateWallSegments(
        temporaryCombatWallSegments ?? this.temporaryCombatWallSegments,
      ),
    );
    final resolvedQueuedTemporaryCombatWallSegments =
        List<OperativePatternWallSegment>.unmodifiable(
      _deduplicateWallSegments(
        queuedTemporaryCombatWallSegments ??
            this.queuedTemporaryCombatWallSegments,
      ),
    );
    final resolvedCombatFlags = Set<CombatRuntimeFlag>.unmodifiable(
      combatFlags ?? this.combatFlags,
    );
    return _buildResolved(
      name: name ?? this.name,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      imageAsset: clearImageAsset ? null : imageAsset ?? this.imageAsset,
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
      augments: resolvedAugments,
      statuses: resolvedStatuses,
      inventoryItems: resolvedInventoryItems,
      equippedItems: resolvedEquippedItems,
      patternItemPointKeys: resolvedPatternItemPointKeys,
      reinforcedPatternPointKey: clearReinforcedPatternPointKey
          ? null
          : reinforcedPatternPointKey ?? this.reinforcedPatternPointKey,
      purgeDoctrine:
          clearPurgeDoctrine ? null : purgeDoctrine ?? this.purgeDoctrine,
      combatWallSegments: resolvedCombatWallSegments,
      combatBlockedPointKeys: resolvedCombatBlockedPointKeys,
      temporaryCombatWallSegments: resolvedTemporaryCombatWallSegments,
      queuedTemporaryCombatWallSegments:
          resolvedQueuedTemporaryCombatWallSegments,
      combatDestroyedWallCount: max(
        0,
        combatDestroyedWallCount ?? this.combatDestroyedWallCount,
      ),
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
    return max(0, baseValue);
  }

  /// Calcula el income base mas los bonus planos aportados por el equipo.
  static int _calculateIncome({
    required int baseIncome,
    required List<Item> equippedItems,
  }) {
    return max(0, baseIncome);
  }

  /// Indica si algun efecto activo ya redujo los bonus positivos al 50%.
  bool get hasBonusDilution => false;

  /// Calcula el coste de XP del siguiente nivel sin escalado entre niveles.
  static int _experienceCostForLevel(int level) {
    return initialLevelUpExperienceCost;
  }

  /// Reconstruye una instancia aplicando invariantes derivadas de vida y barrera.
  ///
  /// Primero crea un candidato para poder calcular stats finales con equipo y
  /// estados; despues ajusta HP y Barrera actual segun si el combate esta activo.
  static Battler _buildResolved({
    required String name,
    required String iconEmoji,
    required String? imageAsset,
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
    required List<Augment> augments,
    required List<BattlerStatus> statuses,
    required List<Item> inventoryItems,
    required List<Item> equippedItems,
    required Map<String, String> patternItemPointKeys,
    required String? reinforcedPatternPointKey,
    required PurgeDoctrine? purgeDoctrine,
    required List<OperativePatternWallSegment> combatWallSegments,
    required Set<String> combatBlockedPointKeys,
    required List<OperativePatternWallSegment> temporaryCombatWallSegments,
    required List<OperativePatternWallSegment>
        queuedTemporaryCombatWallSegments,
    required int combatDestroyedWallCount,
    required Set<CombatRuntimeFlag> combatFlags,
  }) {
    final seedBarrier = max(
      0,
      explicitCurrentBarrier ?? previousCurrentBarrier,
    );
    final candidate = Battler(
      name: name,
      iconEmoji: iconEmoji,
      imageAsset: imageAsset,
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
      augments: augments,
      statuses: statuses,
      inventoryItems: inventoryItems,
      equippedItems: equippedItems,
      patternItemPointKeys: patternItemPointKeys,
      reinforcedPatternPointKey: _validPatternPointKey(
        reinforcedPatternPointKey,
      ),
      purgeDoctrine: purgeDoctrine,
      combatWallSegments: combatWallSegments,
      combatBlockedPointKeys: combatBlockedPointKeys,
      temporaryCombatWallSegments: temporaryCombatWallSegments,
      queuedTemporaryCombatWallSegments: queuedTemporaryCombatWallSegments,
      combatDestroyedWallCount: combatDestroyedWallCount,
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
      imageAsset: imageAsset,
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
      augments: augments,
      statuses: statuses,
      inventoryItems: inventoryItems,
      equippedItems: equippedItems,
      patternItemPointKeys: patternItemPointKeys,
      reinforcedPatternPointKey: _validPatternPointKey(
        reinforcedPatternPointKey,
      ),
      purgeDoctrine: purgeDoctrine,
      combatWallSegments: combatWallSegments,
      combatBlockedPointKeys: combatBlockedPointKeys,
      temporaryCombatWallSegments: temporaryCombatWallSegments,
      queuedTemporaryCombatWallSegments: queuedTemporaryCombatWallSegments,
      combatDestroyedWallCount: combatDestroyedWallCount,
      combatFlags: combatFlags,
    );
  }

  /// Deduplica paredes de combate antes de fijarlas en una instancia inmutable.
  static List<OperativePatternWallSegment> _deduplicateWallSegments(
    Iterable<OperativePatternWallSegment> walls,
  ) {
    final byKey = <String, OperativePatternWallSegment>{};
    for (final wall in walls) {
      byKey[wall.key] = wall;
    }
    return List<OperativePatternWallSegment>.unmodifiable(byKey.values);
  }

  /// Conserva solo claves de puntos que existen en el Patron operativo actual.
  static String? _validPatternPointKey(String? pointKey) {
    if (pointKey == null) return null;
    return operativePatternPointsByKey.containsKey(pointKey) ? pointKey : null;
  }
}
