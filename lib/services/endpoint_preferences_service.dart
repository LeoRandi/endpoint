import 'dart:convert';

import '_imports.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum EndpointGameMode {
  classic,
  drawing,
}

class EndpointSettingsSnapshot {
  final bool soundEnabled;
  final bool vibrationEnabled;
  final int animationSpeed;
  final bool customAvatarEnabled;
  final bool customAvatarSelectionEnabled;
  final EndpointGameMode gameMode;

  const EndpointSettingsSnapshot({
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.animationSpeed,
    required this.customAvatarEnabled,
    required this.customAvatarSelectionEnabled,
    required this.gameMode,
  });

  const EndpointSettingsSnapshot.defaults()
      : soundEnabled = true,
        vibrationEnabled = true,
        animationSpeed = 2,
        customAvatarEnabled = false,
        customAvatarSelectionEnabled = false,
        gameMode = EndpointGameMode.classic;

  EndpointSettingsSnapshot copyWith({
    bool? soundEnabled,
    bool? vibrationEnabled,
    int? animationSpeed,
    bool? customAvatarEnabled,
    bool? customAvatarSelectionEnabled,
    EndpointGameMode? gameMode,
  }) {
    return EndpointSettingsSnapshot(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      animationSpeed: (animationSpeed ?? this.animationSpeed).clamp(1, 3),
      customAvatarEnabled: customAvatarEnabled ?? this.customAvatarEnabled,
      customAvatarSelectionEnabled:
          customAvatarSelectionEnabled ?? this.customAvatarSelectionEnabled,
      gameMode: gameMode ?? this.gameMode,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'animationSpeed': animationSpeed,
      'customAvatarEnabled': customAvatarEnabled,
      'customAvatarSelectionEnabled': customAvatarSelectionEnabled,
      'gameMode': gameMode.name,
    };
  }

  factory EndpointSettingsSnapshot.fromJson(Map<String, dynamic> json) {
    return EndpointSettingsSnapshot(
      soundEnabled: _readBool(
        json['soundEnabled'],
        fallback: const EndpointSettingsSnapshot.defaults().soundEnabled,
      ),
      vibrationEnabled: _readBool(
        json['vibrationEnabled'],
        fallback: const EndpointSettingsSnapshot.defaults().vibrationEnabled,
      ),
      animationSpeed: _readInt(
        json['animationSpeed'],
        fallback: const EndpointSettingsSnapshot.defaults().animationSpeed,
      ).clamp(1, 3),
      customAvatarEnabled: _readBool(
        json['customAvatarEnabled'],
        fallback: const EndpointSettingsSnapshot.defaults().customAvatarEnabled,
      ),
      customAvatarSelectionEnabled: _readBool(
        json['customAvatarSelectionEnabled'],
        fallback: const EndpointSettingsSnapshot.defaults()
            .customAvatarSelectionEnabled,
      ),
      gameMode: _parseGameMode(
        json['gameMode'],
        fallback: const EndpointSettingsSnapshot.defaults().gameMode,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is EndpointSettingsSnapshot &&
        other.soundEnabled == soundEnabled &&
        other.vibrationEnabled == vibrationEnabled &&
        other.animationSpeed == animationSpeed &&
        other.customAvatarEnabled == customAvatarEnabled &&
        other.customAvatarSelectionEnabled == customAvatarSelectionEnabled &&
        other.gameMode == gameMode;
  }

  @override
  int get hashCode => Object.hash(
        soundEnabled,
        vibrationEnabled,
        animationSpeed,
        customAvatarEnabled,
        customAvatarSelectionEnabled,
        gameMode,
      );
}

class EndpointCurrentRunSnapshot {
  final Battler player;
  final RunHourSnapshot currentHour;
  final List<PathNode> visibleNodes;
  final int stageIndex;
  final bool isResolvingNode;
  final bool isRunComplete;
  final RunCompletionType? completionType;
  final int randomSeed;
  final int randomState;
  final Duration battleEnemyTurnDelay;
  final Duration battleCombatEndDelay;
  final PathNode? activeNode;

  const EndpointCurrentRunSnapshot({
    required this.player,
    required this.currentHour,
    required this.visibleNodes,
    required this.stageIndex,
    required this.isResolvingNode,
    required this.isRunComplete,
    required this.completionType,
    required this.randomSeed,
    required this.randomState,
    required this.battleEnemyTurnDelay,
    required this.battleCombatEndDelay,
    this.activeNode,
  });

  int get nodeCount => max(1, visibleNodes.length);

  bool get canContinue => !isRunComplete;
}

abstract final class EndpointPreferencesService {
  static const String currentRunPreferenceKey = 'endpoint.current_run';
  static const String settingsPreferenceKey = 'endpoint.settings';
  static const JsonEncoder _jsonEncoder = JsonEncoder.withIndent('  ');
  static Future<void> _writeQueue = Future<void>.value();

  static Future<void> saveCurrentRunSnapshot({
    required RunState state,
    required RunRandomizer randomizer,
    required bool isResolvingNode,
    required String trigger,
    PathNode? activeNode,
  }) {
    final payload = <String, Object?>{
      'schemaVersion': 3,
      'savedAt': DateTime.now().toUtc().toIso8601String(),
      'trigger': trigger,
      'run': <String, Object?>{
        'stageIndex': state.stageIndex,
        'completedNodes': max(0, state.stageIndex),
        'nodeCount': max(1, state.visibleNodes.length),
        'isResolvingNode': isResolvingNode,
        'isRunComplete': state.isRunComplete,
        'completionType': state.completionType?.name,
        'randomSeed': randomizer.seed,
        'randomState': randomizer.state,
        'battleEnemyTurnDelayMs': state.battleEnemyTurnDelay.inMilliseconds,
        'battleCombatEndDelayMs': state.battleCombatEndDelay.inMilliseconds,
        'currentHour': <String, Object?>{
          'stageIndex': state.currentHour.stageIndex,
          'phase': state.currentHour.phase.name,
          'title': state.currentHour.title,
          'subtitle': state.currentHour.subtitle,
        },
        'activeNode':
            activeNode == null ? null : _serializePathNode(activeNode),
        'visibleNodes': state.visibleNodes
            .map<Map<String, Object?>>(_serializePathNode)
            .toList(growable: false),
        'player': _serializeBattler(state.player),
      },
    };

    return _enqueueWrite(
      key: currentRunPreferenceKey,
      rawValue: _jsonEncoder.convert(payload),
    );
  }

  static Future<EndpointCurrentRunSnapshot?> loadCurrentRunSnapshot() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final rawValue = preferences.getString(currentRunPreferenceKey);
      if (rawValue == null || rawValue.trim().isEmpty) {
        return null;
      }

      final decoded = jsonDecode(rawValue);
      final rootJson = _asJsonMap(decoded);
      if (rootJson == null) return null;

      final runJson = _asJsonMap(rootJson['run']);
      if (runJson == null) return null;

      final snapshot = _deserializeCurrentRunSnapshot(runJson);
      if (snapshot == null) return null;
      if (!snapshot.canContinue) {
        await clearCurrentRunSnapshot();
        return null;
      }

      return snapshot;
    } catch (error, stackTrace) {
      debugPrint(
        'No se pudo cargar la run local guardada: $error\n$stackTrace',
      );
      return null;
    }
  }

  static Future<void> clearCurrentRunSnapshot() {
    return _enqueueRemove(currentRunPreferenceKey);
  }

  static Future<void> saveSettingsSnapshot(
    EndpointSettingsSnapshot settings,
  ) {
    final payload = <String, Object?>{
      'schemaVersion': 1,
      'savedAt': DateTime.now().toUtc().toIso8601String(),
      'settings': settings.toJson(),
    };

    return _enqueueWrite(
      key: settingsPreferenceKey,
      rawValue: _jsonEncoder.convert(payload),
    );
  }

  static Future<EndpointSettingsSnapshot> loadSettingsSnapshot() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final rawValue = preferences.getString(settingsPreferenceKey);
      if (rawValue == null || rawValue.trim().isEmpty) {
        return const EndpointSettingsSnapshot.defaults();
      }

      final decoded = jsonDecode(rawValue);
      final rootJson = _asJsonMap(decoded);
      if (rootJson == null) {
        return const EndpointSettingsSnapshot.defaults();
      }

      final settingsJson = _asJsonMap(rootJson['settings']);
      if (settingsJson == null) {
        return const EndpointSettingsSnapshot.defaults();
      }

      return EndpointSettingsSnapshot.fromJson(settingsJson);
    } catch (error, stackTrace) {
      debugPrint(
        'No se pudieron cargar los settings locales: $error\n$stackTrace',
      );
      return const EndpointSettingsSnapshot.defaults();
    }
  }

  static Future<void> _enqueueWrite({
    required String key,
    required String rawValue,
  }) {
    final pendingWrite = _writeQueue.then((_) async {
      try {
        final preferences = await SharedPreferences.getInstance();
        await preferences.setString(key, rawValue);
      } catch (error, stackTrace) {
        debugPrint(
          'No se pudo guardar la preferencia local "$key": '
          '$error\n$stackTrace',
        );
      }
    });
    _writeQueue = pendingWrite;
    return pendingWrite;
  }

  static Future<void> _enqueueRemove(String key) {
    final pendingRemove = _writeQueue.then((_) async {
      try {
        final preferences = await SharedPreferences.getInstance();
        await preferences.remove(key);
      } catch (error, stackTrace) {
        debugPrint(
          'No se pudo borrar la preferencia local "$key": '
          '$error\n$stackTrace',
        );
      }
    });
    _writeQueue = pendingRemove;
    return pendingRemove;
  }

  static EndpointCurrentRunSnapshot? _deserializeCurrentRunSnapshot(
    Map<String, dynamic> runJson,
  ) {
    final playerJson = _asJsonMap(runJson['player']);
    if (playerJson == null) return null;

    final visibleNodes = _readJsonMapList(runJson['visibleNodes'])
        .map<PathNode?>(_deserializePathNode)
        .whereType<PathNode>()
        .toList(growable: false);
    final isRunComplete = _readBool(runJson['isRunComplete'], fallback: false);
    if (visibleNodes.isEmpty && !isRunComplete) {
      return null;
    }

    final stageIndex = _readInt(
      runJson['stageIndex'],
      fallback: PathNodeService.startStageIndex,
    );
    final currentHourJson = _asJsonMap(runJson['currentHour']);
    final currentHour = currentHourJson == null
        ? RunHourSnapshot(
            stageIndex: stageIndex,
            phase: _parseRunHourPhase(
              null,
              fallback: RunHourPhase.day,
            ),
            title: 'HORA ${stageIndex + 1}',
            subtitle: '',
            nodes: visibleNodes,
          )
        : RunHourSnapshot(
            stageIndex: _readInt(
              currentHourJson['stageIndex'],
              fallback: stageIndex,
            ),
            phase: _parseRunHourPhase(
              currentHourJson['phase'],
              fallback: RunHourPhase.day,
            ),
            title: _readString(
              currentHourJson['title'],
              fallback: 'HORA ${stageIndex + 1}',
            ),
            subtitle: _readString(
              currentHourJson['subtitle'],
              fallback: '',
            ),
            nodes: visibleNodes,
          );

    final activeNode = _deserializePathNode(_asJsonMap(runJson['activeNode']));
    final isResolvingNode = _readBool(
      runJson['isResolvingNode'],
      fallback: false,
    );

    return EndpointCurrentRunSnapshot(
      player: _deserializeBattler(playerJson),
      currentHour: currentHour,
      visibleNodes: visibleNodes,
      stageIndex: stageIndex,
      isResolvingNode: isResolvingNode && activeNode != null,
      isRunComplete: isRunComplete,
      completionType: _parseRunCompletionType(runJson['completionType']),
      randomSeed: _readInt(
        runJson['randomSeed'],
        fallback: RunRandomizer().seed,
      ),
      randomState: _readInt(
        runJson['randomState'],
        fallback: _readInt(
          runJson['randomSeed'],
          fallback: RunRandomizer().seed,
        ),
      ),
      battleEnemyTurnDelay: Duration(
        milliseconds: _readInt(
          runJson['battleEnemyTurnDelayMs'],
          fallback: 900,
        ),
      ),
      battleCombatEndDelay: Duration(
        milliseconds: _readInt(
          runJson['battleCombatEndDelayMs'],
          fallback: 2000,
        ),
      ),
      activeNode: activeNode,
    );
  }

  static Battler _deserializeBattler(Map<String, dynamic> json) {
    final abilities = _readJsonMapList(json['abilities'])
        .map<BattlerAbility?>(_deserializeAbility)
        .whereType<BattlerAbility>()
        .toList(growable: false);
    final statuses = _readJsonMapList(json['statuses'])
        .map<BattlerStatus?>(_deserializeStatus)
        .whereType<BattlerStatus>()
        .toList(growable: false);
    final inventoryItems = _readJsonMapList(json['inventoryItems'])
        .map<Item?>(_deserializeItem)
        .whereType<Item>()
        .toList(growable: false);
    final equippedItems = _readJsonMapList(json['equippedItems'])
        .map<Item?>(_deserializeItem)
        .whereType<Item>()
        .toList(growable: false);
    final combatFlags = _readJsonMapList(json['combatFlags'])
        .map<CombatRuntimeFlag?>(_deserializeCombatFlag)
        .whereType<CombatRuntimeFlag>()
        .toSet();

    Item.syncInstanceSequenceFromExistingIds([
      ...inventoryItems.map((item) => item.instanceId),
      ...equippedItems.map((item) => item.instanceId),
    ]);

    return Battler(
      name: _readString(json['name'], fallback: defaultPlayerBattler.name),
      iconEmoji: _readString(
        json['iconEmoji'],
        fallback: defaultPlayerBattler.iconEmoji,
      ),
      health: _readInt(
        json['currentHealth'],
        fallback: defaultPlayerBattler.health,
      ),
      currentBarrier: _readInt(json['currentBarrier'], fallback: 0),
      money: _readInt(json['money'], fallback: defaultPlayerBattler.money),
      income: _readInt(
        json['baseIncome'],
        fallback: defaultPlayerBattler.baseIncome,
      ),
      equipmentCapacity: _readInt(
        json['equipmentCapacity'],
        fallback: defaultPlayerBattler.equipmentCapacity,
      ),
      level: _readInt(json['level'], fallback: defaultPlayerBattler.level),
      experience: _readInt(
        json['experience'],
        fallback: defaultPlayerBattler.experience,
      ),
      baseStats: Map<BattlerStat, int>.unmodifiable(
        _deserializeStatMap(
          json['baseStats'],
          fallback: defaultPlayerBattler.baseStats,
        ),
      ),
      abilities: List<BattlerAbility>.unmodifiable(abilities),
      statuses: List<BattlerStatus>.unmodifiable(statuses),
      inventoryItems: List<Item>.unmodifiable(inventoryItems),
      equippedItems: List<Item>.unmodifiable(equippedItems),
      combatFlags: Set<CombatRuntimeFlag>.unmodifiable(combatFlags),
    );
  }

  static BattlerAbility? _deserializeAbility(Map<String, dynamic> json) {
    final abilityId = _parseEnumByName(BattlerAbilityId.values, json['id']);
    if (abilityId == null) return null;

    final preset = BattlerAbility.presetForId(abilityId);
    return preset.copyWith(
      rarity:
          _parseEnumByName(RarityTier.values, json['rarity']) ?? preset.rarity,
      name: _readString(json['name'], fallback: preset.name),
      description: _readString(
        json['description'],
        fallback: preset.description,
      ),
      cooldownTurns: _readInt(
        json['cooldownTurns'],
        fallback: preset.cooldownTurns,
      ),
      remainingCooldownTurns: _readInt(
        json['remainingCooldownTurns'],
        fallback: preset.remainingCooldownTurns,
      ),
      value: _readInt(json['value'], fallback: preset.value),
      upgradeValue: _readInt(
        json['upgradeValue'],
        fallback: preset.upgradeValue,
      ),
      runtimeValueBonus: _readInt(
        json['runtimeValueBonus'],
        fallback: preset.runtimeValueBonus,
      ),
      isActive: _readBool(json['isActive'], fallback: preset.isActive),
      manualActivationContext: _parseEnumByName(
            BattlerAbilityActivationContext.values,
            json['manualActivationContext'],
          ) ??
          preset.manualActivationContext,
      isImplemented: _readBool(
        json['isImplemented'],
        fallback: preset.isImplemented,
      ),
    );
  }

  static BattlerStatus? _deserializeStatus(Map<String, dynamic> json) {
    final statusId = _parseEnumByName(BattlerStatusId.values, json['id']);
    if (statusId == null) return null;

    final remainingTurns = _readInt(json['remainingTurns'], fallback: 1);
    final value = _readInt(json['value'], fallback: 1);

    switch (statusId) {
      case BattlerStatusId.calentando:
        return CalentandoStatus(
          remainingTurns: remainingTurns,
          value: value,
        );
      case BattlerStatusId.quemadura:
        return QuemaduraStatus(
          remainingTurns: remainingTurns,
          value: value,
        );
      case BattlerStatusId.intoxicacion:
        return IntoxicacionStatus(
          remainingTurns: remainingTurns,
          value: value,
        );
      case BattlerStatusId.catalisisCruel:
        return CatalisisCruelStatus(value: value);
      case BattlerStatusId.fragilidad:
        return FragilidadStatus(
          remainingTurns: remainingTurns,
          value: value,
        );
      case BattlerStatusId.interferencia:
        return InterferenciaStatus(
          remainingTurns: remainingTurns,
          value: value,
        );
      case BattlerStatusId.blindajeTemporal:
        return BlindajeTemporalStatus(value: value);
      case BattlerStatusId.conmocion:
        return ConmocionStatus(value: value);
      case BattlerStatusId.escudoDeEnergia:
        return EscudoDeEnergiaStatus(value: value);
      case BattlerStatusId.escudoDeFase:
        return EscudoDeFaseStatus(value: value);
      case BattlerStatusId.inercia:
        return InerciaStatus(value: value);
      case BattlerStatusId.inerciaAtaque:
        return InerciaAtaqueStatus(value: value);
      case BattlerStatusId.inerciaBarrera:
        return InerciaBarreraStatus(value: value);
      case BattlerStatusId.deuda:
        return DeudaStatus(value: value);
    }
  }

  static Item? _deserializeItem(Map<String, dynamic> json) {
    final itemId = _parseEnumByName(ItemId.values, json['id']);
    if (itemId == null) return null;

    final preset = Item.presetForId(itemId);
    var item = preset.copyWith(
      name: _readString(json['name'], fallback: preset.name),
      description: _readString(
        json['description'],
        fallback: preset.description,
      ),
      iconEmoji: _readString(json['iconEmoji'], fallback: preset.iconEmoji),
      slot: _parseEnumByName(ItemSlot.values, json['slot']) ?? preset.slot,
      rarity:
          _parseEnumByName(RarityTier.values, json['rarity']) ?? preset.rarity,
      baseCost: _readInt(json['baseCost'], fallback: preset.baseCost),
      equipCost: _readNullableInt(json['equipCost']) ?? preset.equipCost,
      value: _readInt(json['value'], fallback: preset.value),
      upgradeValue: _readInt(
        json['upgradeValue'],
        fallback: preset.upgradeValue,
      ),
      incomePerValueUnit: _readInt(
        json['incomePerValueUnit'],
        fallback: preset.incomePerValueUnit,
      ),
      maxHealthPercentPerValueUnit: _readInt(
        json['maxHealthPercentPerValueUnit'],
        fallback: preset.maxHealthPercentPerValueUnit,
      ),
      statModifiers: _deserializeStatMap(
        json['statModifiers'],
        fallback: preset.statModifiers,
      ),
      upgradeStatModifiers: _deserializeStatMap(
        json['upgradeStatModifiers'],
        fallback: preset.upgradeStatModifiers,
      ),
      instanceId: _readNullableString(json['instanceId']),
      bonusShapeOverride: _parseEnumByName(
        ItemBonusShape.values,
        json['bonusShape'],
      ),
    );

    if (!item.isInstanced) {
      item = item.toOwnedInstance();
    }

    return item;
  }

  static CombatRuntimeFlag? _deserializeCombatFlag(Map<String, dynamic> json) {
    final battlerFlag = _parseEnumByName(
      BattlerCombatFlag.values,
      json['battlerFlag'],
    );
    if (battlerFlag != null) {
      return CombatRuntimeFlag.battler(battlerFlag);
    }

    final itemFlag = _parseEnumByName(
      ItemCombatFlagKind.values,
      json['itemFlag'],
    );
    final itemId = _parseEnumByName(ItemId.values, json['itemId']);
    if (itemFlag == null || itemId == null) return null;

    return CombatRuntimeFlag.item(
      flag: itemFlag,
      itemId: itemId,
      itemInstanceId: _readNullableString(json['itemInstanceId']),
    );
  }

  static PathNode? _deserializePathNode(Map<String, dynamic>? json) {
    if (json == null) return null;

    final nodeId = _readNullableString(json['nodeId']);
    if (nodeId == null) return null;

    final node = pathNodeRegistry[nodeId];
    if (node == null) return null;

    if (node is ShopPathNode) {
      final priceMultiplier = _readDouble(
        json['priceMultiplier'],
        fallback: node.priceMultiplier,
      );
      if ((priceMultiplier - node.priceMultiplier).abs() > 0.0001) {
        return node.withPriceMultiplier(priceMultiplier);
      }
    }

    return node;
  }

  static Map<String, Object?> _serializeBattler(Battler battler) {
    return {
      'name': battler.name,
      'iconEmoji': battler.iconEmoji,
      'level': battler.level,
      'experience': battler.experience,
      'displayedExperience': battler.displayedExperience,
      'experienceToNextLevel': battler.experienceToNextLevel,
      'currentHealth': battler.health,
      'maxHealth': battler.maxHealth,
      'currentBarrier': battler.currentBarrier,
      'maxBarrier': battler.maxBarrier,
      'attack': battler.attack,
      'barrier': battler.barrier,
      'money': battler.money,
      'income': battler.income,
      'baseIncome': battler.baseIncome,
      'equipmentCapacity': battler.equipmentCapacity,
      'remainingEquipmentCapacity': battler.remainingEquipmentCapacity,
      'baseStats': _serializeStatMap(battler.baseStats),
      'abilities': battler.abilities
          .map<Map<String, Object?>>(_serializeAbility)
          .toList(growable: false),
      'statuses': battler.statuses
          .map<Map<String, Object?>>(_serializeStatus)
          .toList(growable: false),
      'equippedItems': battler.equippedItems
          .map<Map<String, Object?>>(_serializeItem)
          .toList(growable: false),
      'inventoryItems': battler.inventoryItems
          .map<Map<String, Object?>>(_serializeItem)
          .toList(growable: false),
      'combatFlags': battler.combatFlags
          .map<Map<String, Object?>>(_serializeCombatFlag)
          .toList(growable: false),
    };
  }

  static Map<String, Object?> _serializeAbility(BattlerAbility ability) {
    return {
      'id': ability.id.name,
      'name': ability.name,
      'description': ability.description,
      'displayName': ability.displayName,
      'rarity': ability.rarity.name,
      'value': ability.value,
      'currentValue': ability.currentValue,
      'upgradeValue': ability.upgradeValue,
      'cooldownTurns': ability.cooldownTurns,
      'remainingCooldownTurns': ability.remainingCooldownTurns,
      'runtimeValueBonus': ability.runtimeValueBonus,
      'isActive': ability.isActive,
      'manualActivationContext': ability.manualActivationContext?.name,
      'isImplemented': ability.isImplemented,
    };
  }

  static Map<String, Object?> _serializeStatus(BattlerStatus status) {
    return {
      'id': status.id.name,
      'name': status.name,
      'type': status.type.name,
      'remainingTurns': status.remainingTurns,
      'value': status.value,
      'isIndefinite': status.isIndefinite,
      'canStack': status.canStack,
      'isPurgeable': status.isPurgeable,
      'persistsOutsideCombat': status.persistsOutsideCombat,
    };
  }

  static Map<String, Object?> _serializeItem(Item item) {
    return {
      'id': item.id.name,
      'instanceId': item.instanceId,
      'name': item.name,
      'displayName': item.displayName,
      'description': item.description,
      'iconEmoji': item.iconEmoji,
      'slot': item.slot?.name,
      'rarity': item.rarity.name,
      'baseCost': item.baseCost,
      'equipCost': item.equipCost,
      'equipmentCost': item.equipmentCost,
      'value': item.value,
      'upgradeValue': item.upgradeValue,
      'upgradeCount': item.upgradeCount,
      'incomePerValueUnit': item.incomePerValueUnit,
      'incomeModifier': item.incomeModifier,
      'maxHealthPercentPerValueUnit': item.maxHealthPercentPerValueUnit,
      'maxHealthPercentModifier': item.maxHealthPercentModifier,
      'statModifiers': _serializeStatMap(item.statModifiers),
      'upgradeStatModifiers': _serializeStatMap(item.upgradeStatModifiers),
      'hasEffect': item.hasEffect,
      'bonusShape': item.bonusShape.name,
      'specialBonusKind': item.specialBonus.kind.name,
      'specialBonusAmount': item.specialBonus.amount,
    };
  }

  static Map<String, Object?> _serializeCombatFlag(CombatRuntimeFlag flag) {
    return {
      'battlerFlag': flag.battlerFlag?.name,
      'itemFlag': flag.itemFlag?.name,
      'itemId': flag.itemId?.name,
      'itemInstanceId': flag.itemInstanceId,
    };
  }

  static Map<String, Object?> _serializePathNode(PathNode node) {
    final payload = <String, Object?>{
      'nodeId': node.nodeId,
      'type': node.type.name,
      'label': node.label,
      'tooltip': node.tooltip,
      'badgeLabel': node.badgeLabel,
      'iconEmoji': node.iconEmoji,
      'rarity': node.rarity.name,
      'hasSignatureBorder': node.hasSignatureBorder,
    };

    if (node is ShopPathNode) {
      payload['priceMultiplier'] = node.priceMultiplier;
    }

    return payload;
  }

  static Map<String, int> _serializeStatMap(Map<BattlerStat, int> stats) {
    return {
      for (final entry in stats.entries) entry.key.name: entry.value,
    };
  }

  static Map<BattlerStat, int> _deserializeStatMap(
    Object? rawValue, {
    required Map<BattlerStat, int> fallback,
  }) {
    final json = _asJsonMap(rawValue);
    if (json == null) return Map<BattlerStat, int>.from(fallback);

    final stats = <BattlerStat, int>{};
    for (final entry in json.entries) {
      final stat = _parseEnumByName(BattlerStat.values, entry.key);
      if (stat == null) continue;
      stats[stat] = _readInt(entry.value, fallback: fallback[stat] ?? 0);
    }

    if (stats.isEmpty) {
      return Map<BattlerStat, int>.from(fallback);
    }

    return stats;
  }
}

Map<String, dynamic>? _asJsonMap(Object? rawValue) {
  if (rawValue is Map<String, dynamic>) return rawValue;
  if (rawValue is! Map) return null;

  return rawValue.map(
    (key, value) => MapEntry(key.toString(), value),
  );
}

List<Map<String, dynamic>> _readJsonMapList(Object? rawValue) {
  if (rawValue is! List) return const <Map<String, dynamic>>[];

  return rawValue
      .map<Map<String, dynamic>?>((entry) => _asJsonMap(entry))
      .whereType<Map<String, dynamic>>()
      .toList(growable: false);
}

bool _readBool(
  Object? rawValue, {
  required bool fallback,
}) {
  return rawValue is bool ? rawValue : fallback;
}

int _readInt(
  Object? rawValue, {
  required int fallback,
}) {
  return rawValue is int ? rawValue : fallback;
}

double _readDouble(
  Object? rawValue, {
  required double fallback,
}) {
  if (rawValue is double) return rawValue;
  if (rawValue is int) return rawValue.toDouble();
  return fallback;
}

String _readString(
  Object? rawValue, {
  required String fallback,
}) {
  return rawValue is String ? rawValue : fallback;
}

String? _readNullableString(Object? rawValue) {
  return rawValue is String && rawValue.isNotEmpty ? rawValue : null;
}

int? _readNullableInt(Object? rawValue) {
  return rawValue is int ? rawValue : null;
}

T? _parseEnumByName<T extends Enum>(List<T> values, Object? rawValue) {
  if (rawValue is! String) return null;

  for (final value in values) {
    if (value.name == rawValue) {
      return value;
    }
  }

  return null;
}

EndpointGameMode _parseGameMode(
  Object? rawValue, {
  required EndpointGameMode fallback,
}) {
  return _parseEnumByName(EndpointGameMode.values, rawValue) ?? fallback;
}

RunHourPhase _parseRunHourPhase(
  Object? rawValue, {
  required RunHourPhase fallback,
}) {
  return _parseEnumByName(RunHourPhase.values, rawValue) ?? fallback;
}

RunCompletionType? _parseRunCompletionType(Object? rawValue) {
  return _parseEnumByName(RunCompletionType.values, rawValue);
}
