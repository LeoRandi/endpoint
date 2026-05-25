import '../entities/_exports.dart';
import 'endpoint_json_utils.dart';

abstract final class EndpointDomainCodec {
  static BattlerAbility? deserializeAbility(Map<String, dynamic> json) {
    return _deserializeAbility(json);
  }

  static Map<String, Object?> serializeAbility(BattlerAbility ability) {
    return _serializeAbility(ability);
  }

  static Item? deserializeItem(Map<String, dynamic> json) {
    return _deserializeItem(json);
  }

  static Map<String, Object?> serializeItem(Item item) {
    return _serializeItem(item);
  }

  static Battler deserializeBattler(Map<String, dynamic> json) {
    final abilities = EndpointJsonUtils.readJsonMapList(json['abilities'])
        .map<BattlerAbility?>(_deserializeAbility)
        .whereType<BattlerAbility>()
        .toList(growable: false);
    final statuses = EndpointJsonUtils.readJsonMapList(json['statuses'])
        .map<BattlerStatus?>(_deserializeStatus)
        .whereType<BattlerStatus>()
        .toList(growable: false);
    final inventoryItems = EndpointJsonUtils.readJsonMapList(
      json['inventoryItems'],
    ).map<Item?>(_deserializeItem).whereType<Item>().toList(growable: false);
    final equippedItems = EndpointJsonUtils.readJsonMapList(
      json['equippedItems'],
    ).map<Item?>(_deserializeItem).whereType<Item>().toList(growable: false);
    final patternItemPointKeys = EndpointJsonUtils.readStringMap(
      json['patternItemPointKeys'],
    );
    final combatFlags = EndpointJsonUtils.readJsonMapList(json['combatFlags'])
        .map<CombatRuntimeFlag?>(_deserializeCombatFlag)
        .whereType<CombatRuntimeFlag>()
        .toSet();

    Item.syncInstanceSequenceFromExistingIds([
      ...inventoryItems.map((item) => item.instanceId),
      ...equippedItems.map((item) => item.instanceId),
    ]);

    return Battler(
      name: EndpointJsonUtils.readString(
        json['name'],
        fallback: defaultPlayerBattler.name,
      ),
      iconEmoji: EndpointJsonUtils.readString(
        json['iconEmoji'],
        fallback: defaultPlayerBattler.iconEmoji,
      ),
      archetypeId: EndpointJsonUtils.parseEnumByName(
        ArchetypeId.values,
        json['archetypeId'],
      ),
      health: EndpointJsonUtils.readInt(
        json['currentHealth'],
        fallback: defaultPlayerBattler.health,
      ),
      currentBarrier: EndpointJsonUtils.readInt(
        json['currentBarrier'],
        fallback: 0,
      ),
      money: EndpointJsonUtils.readInt(
        json['money'],
        fallback: defaultPlayerBattler.money,
      ),
      income: EndpointJsonUtils.readInt(
        json['baseIncome'],
        fallback: defaultPlayerBattler.baseIncome,
      ),
      equipmentCapacity: EndpointJsonUtils.readInt(
        json['equipmentCapacity'],
        fallback: defaultPlayerBattler.equipmentCapacity,
      ),
      level: EndpointJsonUtils.readInt(
        json['level'],
        fallback: defaultPlayerBattler.level,
      ),
      experience: EndpointJsonUtils.readInt(
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
      patternItemPointKeys: patternItemPointKeys,
      combatFlags: Set<CombatRuntimeFlag>.unmodifiable(combatFlags),
    );
  }

  static Map<String, Object?> serializeBattler(Battler battler) {
    return {
      'name': battler.name,
      'iconEmoji': battler.iconEmoji,
      'archetypeId': battler.archetypeId?.name,
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
      'patternItemPointKeys': battler.patternItemPointKeys,
      'combatFlags': battler.combatFlags
          .map<Map<String, Object?>>(_serializeCombatFlag)
          .toList(growable: false),
    };
  }

  static PathNode? deserializePathNode(Map<String, dynamic>? json) {
    if (json == null) return null;

    final nodeId = EndpointJsonUtils.readNullableString(json['nodeId']);
    if (nodeId == null) return null;

    final node = pathNodeRegistry[nodeId];
    if (node == null) return null;

    if (node is ShopPathNode) {
      final priceMultiplier = EndpointJsonUtils.readDouble(
        json['priceMultiplier'],
        fallback: node.priceMultiplier,
      );
      if ((priceMultiplier - node.priceMultiplier).abs() > 0.0001) {
        return node.withPriceMultiplier(priceMultiplier);
      }
    }

    if (node is ArchetypePathNode && node.startingItemsBuilder == null) {
      final startingItems = EndpointJsonUtils.readJsonMapList(
        json['startingItems'],
      ).map<Item?>(_deserializeItem).whereType<Item>().toList(growable: false);
      if (startingItems.isNotEmpty) {
        return node.withStartingItems(startingItems);
      }
    }

    return node;
  }

  static Map<String, Object?> serializePathNode(PathNode node) {
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
    if (node is ArchetypePathNode && node.startingItemsBuilder == null) {
      payload['startingItems'] = node.startingItems
          .map<Map<String, Object?>>(_serializeItem)
          .toList(growable: false);
    }

    return payload;
  }
}

BattlerAbility? _deserializeAbility(Map<String, dynamic> json) {
  final abilityId = EndpointJsonUtils.parseEnumByName(
    BattlerAbilityId.values,
    json['id'],
  );
  if (abilityId == null) return null;

  final preset = abilityPresetRegistry[abilityId];
  if (preset == null) return null;

  return preset
      .copyWith(
        rarity: EndpointJsonUtils.parseEnumByName(
                RarityTier.values, json['rarity']) ??
            preset.rarity,
        name: EndpointJsonUtils.readString(
          json['name'],
          fallback: preset.name,
        ),
        description: EndpointJsonUtils.readString(
          json['description'],
          fallback: preset.description,
        ),
        cooldownTurns: EndpointJsonUtils.readInt(
          json['cooldownTurns'],
          fallback: preset.cooldownTurns,
        ),
        remainingCooldownTurns: EndpointJsonUtils.readInt(
          json['remainingCooldownTurns'],
          fallback: preset.remainingCooldownTurns,
        ),
        value: EndpointJsonUtils.readInt(
          json['value'],
          fallback: preset.value,
        ),
        upgradeValue: EndpointJsonUtils.readInt(
          json['upgradeValue'],
          fallback: preset.upgradeValue,
        ),
        runtimeValueBonus: EndpointJsonUtils.readInt(
          json['runtimeValueBonus'],
          fallback: preset.runtimeValueBonus,
        ),
        isActive: EndpointJsonUtils.readBool(
          json['isActive'],
          fallback: preset.isActive,
        ),
        manualActivationContext: EndpointJsonUtils.parseEnumByName(
              BattlerAbilityActivationContext.values,
              json['manualActivationContext'],
            ) ??
            preset.manualActivationContext,
        isImplemented: EndpointJsonUtils.readBool(
          json['isImplemented'],
          fallback: preset.isImplemented,
        ),
      )
      .normalizeUpgradeTier();
}

BattlerStatus? _deserializeStatus(Map<String, dynamic> json) {
  final statusId = EndpointJsonUtils.parseEnumByName(
    BattlerStatusId.values,
    json['id'],
  );
  if (statusId == null) return null;

  final remainingTurns = EndpointJsonUtils.readInt(
    json['remainingTurns'],
    fallback: 1,
  );
  final value = EndpointJsonUtils.readInt(
    json['value'],
    fallback: 1,
  );
  if (statusId == BattlerStatusId.compensadorRuta) {
    return CompensadorRutaStatus(
      stat: EndpointJsonUtils.parseEnumByName(
            BattlerStat.values,
            json['stat'],
          ) ??
          BattlerStat.attack,
      value: value,
    );
  }
  final statusFactory = battlerStatusFactoryById[statusId];
  if (statusFactory == null) return null;

  return statusFactory(
    remainingTurns: remainingTurns,
    value: value,
  );
}

Item? _deserializeItem(Map<String, dynamic> json) {
  final itemId = EndpointJsonUtils.parseEnumByName(ItemId.values, json['id']);
  if (itemId == null) return null;

  final preset = Item.presetForId(itemId);
  final instanceId = EndpointJsonUtils.readNullableString(json['instanceId']);
  var item = preset.copyWith(
    archetypeAffinities: _deserializeItemArchetypeAffinities(
      json['archetypeAffinities'],
      fallback: preset.archetypeAffinities,
    ),
    name: EndpointJsonUtils.readString(
      json['name'],
      fallback: preset.name,
    ),
    description: EndpointJsonUtils.readString(
      json['description'],
      fallback: preset.description,
    ),
    iconEmoji: EndpointJsonUtils.readString(
      json['iconEmoji'],
      fallback: preset.iconEmoji,
    ),
    rarity:
        EndpointJsonUtils.parseEnumByName(RarityTier.values, json['rarity']) ??
            preset.rarity,
    baseCost: EndpointJsonUtils.readInt(
      json['baseCost'],
      fallback: preset.baseCost,
    ),
    sellValueBonus: EndpointJsonUtils.readInt(
      json['sellValueBonus'],
      fallback: preset.sellValueBonus,
    ),
    value: EndpointJsonUtils.readInt(
      json['value'],
      fallback: preset.value,
    ),
    upgradeValue: EndpointJsonUtils.readInt(
      json['upgradeValue'],
      fallback: preset.upgradeValue,
    ),
    incomePerValueUnit: EndpointJsonUtils.readInt(
      json['incomePerValueUnit'],
      fallback: preset.incomePerValueUnit,
    ),
    maxHealthPercentPerValueUnit: EndpointJsonUtils.readInt(
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
    instanceId: instanceId,
    patternBonusKindOverride: EndpointJsonUtils.parseEnumByName(
      OperativePatternBonusKind.values,
      json['patternBonusKind'],
    ),
    patternBonusAmountOverride: EndpointJsonUtils.readNullableInt(
      json['patternBonusAmount'],
    ),
    patternRequirementOverride: _deserializePatternRequirement(json),
    hasPatternAura: EndpointJsonUtils.readBool(
      json['hasPatternAura'],
      fallback: preset.hasPatternAura,
    ),
    combatItemBonusBoost: EndpointJsonUtils.readInt(
      json['combatItemBonusBoost'],
      fallback: preset.combatItemBonusBoost,
    ),
    combatGeneratedPatternBonus: EndpointJsonUtils.readBool(
      json['combatGeneratedPatternBonus'],
      fallback: preset.combatGeneratedPatternBonus,
    ),
    patternAdjacencyBonuses: _deserializePatternAdjacencyBonuses(
      json['patternAdjacencyBonuses'],
      fallback: preset.patternAdjacencyBonuses,
    ),
  );

  if (item.isInstanced) {
    Item.syncInstanceSequenceFromExistingIds([item.instanceId]);
  } else {
    item = item.toOwnedInstance();
  }

  return item.normalizeUpgradeTier();
}

CombatRuntimeFlag? _deserializeCombatFlag(Map<String, dynamic> json) {
  final battlerFlag = EndpointJsonUtils.parseEnumByName(
    BattlerCombatFlag.values,
    json['battlerFlag'],
  );
  if (battlerFlag != null) {
    return CombatRuntimeFlag.battler(battlerFlag);
  }

  final itemFlag = EndpointJsonUtils.parseEnumByName(
    ItemCombatFlagKind.values,
    json['itemFlag'],
  );
  final itemId = EndpointJsonUtils.parseEnumByName(
    ItemId.values,
    json['itemId'],
  );
  if (itemFlag == null || itemId == null) return null;

  return CombatRuntimeFlag.item(
    itemFlag: itemFlag,
    itemId: itemId,
    itemInstanceId:
        EndpointJsonUtils.readNullableString(json['itemInstanceId']),
  );
}

Map<String, Object?> _serializeAbility(BattlerAbility ability) {
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

Map<String, Object?> _serializeStatus(BattlerStatus status) {
  return {
    'id': status.id.name,
    'name': status.name,
    'type': status.type.name,
    'remainingTurns': status.remainingTurns,
    'value': status.value,
    if (status is CompensadorRutaStatus) 'stat': status.stat.name,
    'isIndefinite': status.isIndefinite,
    'canStack': status.canStack,
    'isPurgeable': status.isPurgeable,
    'persistsOutsideCombat': status.persistsOutsideCombat,
  };
}

Map<String, Object?> _serializeItem(Item item) {
  return {
    'id': item.id.name,
    'archetypeAffinities': item.archetypeAffinities
        .map((affinity) => affinity.name)
        .toList(growable: false),
    'instanceId': item.instanceId,
    'name': item.name,
    'displayName': item.displayName,
    'description': item.description,
    'iconEmoji': item.iconEmoji,
    'rarity': item.rarity.name,
    'baseCost': item.baseCost,
    'sellValueBonus': item.sellValueBonus,
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
    'hasPatternBonus': item.hasPatternBonus,
    'patternBonusKind':
        item.hasPatternBonus ? item.patternBonusKind.name : null,
    'patternBonusAmount': item.patternBonusAmount,
    'hasPatternAura': item.hasPatternAura,
    'combatItemBonusBoost': item.combatItemBonusBoost,
    'combatGeneratedPatternBonus': item.combatGeneratedPatternBonus,
    'patternRequirementKind':
        item.hasPatternBonus ? item.patternRequirement.kind.name : null,
    'patternRequirementShapeKind':
        item.hasPatternBonus ? item.patternRequirement.shapeKind.name : null,
    'patternRequirementLabel':
        item.hasPatternBonus ? item.patternRequirement.label : null,
    'patternRequirementShortLabel':
        item.hasPatternBonus ? item.patternRequirement.shortLabel : null,
    'patternRequirementDescription':
        item.hasPatternBonus ? item.patternRequirement.description : null,
    'patternRequirementShape': item.hasPatternBonus
        ? item.patternRequirement.shapePoints
            .map((point) => point.key)
            .toList(growable: false)
        : const <String>[],
    'patternAdjacencyBonuses': item.patternAdjacencyBonuses
        .map<Map<String, Object?>>(_serializePatternAdjacencyBonus)
        .toList(growable: false),
  };
}

Map<String, Object?> _serializePatternAdjacencyBonus(
  OperativePatternAdjacencyBonus adjacencyBonus,
) {
  return {
    'direction': adjacencyBonus.direction.name,
    'requiredTag': adjacencyBonus.requiredTag.name,
    'bonusKind': adjacencyBonus.bonus.kind.name,
    'amount': adjacencyBonus.bonus.amount,
  };
}

OperativePatternRequirement? _deserializePatternRequirement(
  Map<String, dynamic> json,
) {
  final kind = EndpointJsonUtils.parseEnumByName(
    OperativePatternRequirementKind.values,
    json['patternRequirementKind'],
  );
  if (kind == null) return null;

  switch (kind) {
    case OperativePatternRequirementKind.firstPoint:
      return const OperativePatternRequirement.first();
    case OperativePatternRequirementKind.middlePoint:
      return const OperativePatternRequirement.middle();
    case OperativePatternRequirementKind.lastPoint:
      return const OperativePatternRequirement.last();
    case OperativePatternRequirementKind.rightAngle:
      return const OperativePatternRequirement.rightAngle();
    case OperativePatternRequirementKind.straightAngle:
      return const OperativePatternRequirement.straightAngle();
    case OperativePatternRequirementKind.exactShape:
      final shapePoints = _deserializePatternPointList(
        json['patternRequirementShape'],
      );
      if (shapePoints.length < 3 ||
          shapePoints.length >
              OperativePatternRequirement.maxExactShapePoints) {
        return null;
      }

      return OperativePatternRequirement.exactShape(
        shapePoints: shapePoints,
        shapeKind: EndpointJsonUtils.parseEnumByName(
              OperativePatternShapeKind.values,
              json['patternRequirementShapeKind'],
            ) ??
            _inferPatternShapeKindFromLabel(
              EndpointJsonUtils.readNullableString(
                json['patternRequirementLabel'],
              ),
            ),
        labelOverride: EndpointJsonUtils.readNullableString(
          json['patternRequirementLabel'],
        ),
      );
  }
}

OperativePatternShapeKind _inferPatternShapeKindFromLabel(String? label) {
  final normalized = label?.toLowerCase().replaceAll(' ', '') ?? '';
  if (normalized.contains('cuadrado')) return OperativePatternShapeKind.square;
  if (normalized.contains('diamante')) return OperativePatternShapeKind.diamond;
  if (normalized.contains('relojarena')) {
    return OperativePatternShapeKind.hourglass;
  }
  if (normalized.contains('zigzag')) return OperativePatternShapeKind.zigzag;
  return OperativePatternShapeKind.literal;
}

List<OperativePatternPoint> _deserializePatternPointList(Object? rawValue) {
  if (rawValue is! List) return const <OperativePatternPoint>[];

  final pointsByKey = <String, OperativePatternPoint>{
    for (final point in operativePatternPoints) point.key: point,
  };
  final points = <OperativePatternPoint>[];
  for (final entry in rawValue) {
    if (entry is! String) continue;
    final point = pointsByKey[entry];
    if (point == null) continue;
    points.add(point);
  }

  return List<OperativePatternPoint>.unmodifiable(points);
}

List<OperativePatternAdjacencyBonus> _deserializePatternAdjacencyBonuses(
  Object? rawValue, {
  required List<OperativePatternAdjacencyBonus> fallback,
}) {
  if (rawValue is! List) return fallback;

  final bonuses = <OperativePatternAdjacencyBonus>[];
  for (final entry in rawValue) {
    if (entry is! Map) continue;
    final json = Map<String, dynamic>.from(entry);
    final direction = EndpointJsonUtils.parseEnumByName(
      OperativePatternAdjacencyDirection.values,
      json['direction'],
    );
    final requiredTag = EndpointJsonUtils.parseEnumByName(
      EntityTag.values,
      json['requiredTag'],
    );
    final bonusKind = EndpointJsonUtils.parseEnumByName(
      OperativePatternBonusKind.values,
      json['bonusKind'],
    );
    final amount = EndpointJsonUtils.readInt(
      json['amount'],
      fallback: 1,
    );
    if (direction == null || requiredTag == null || bonusKind == null) {
      continue;
    }

    bonuses.add(
      OperativePatternAdjacencyBonus.match(
        direction,
        requiredTag,
        bonusKind,
        amount < 1 ? 1 : amount,
      ),
    );
  }

  return List<OperativePatternAdjacencyBonus>.unmodifiable(bonuses);
}

List<ItemArchetypeAffinity> _deserializeItemArchetypeAffinities(
  Object? rawValue, {
  required List<ItemArchetypeAffinity> fallback,
}) {
  if (rawValue is! List) {
    return List<ItemArchetypeAffinity>.unmodifiable(fallback);
  }

  final parsedAffinities = rawValue
      .map<ItemArchetypeAffinity?>(
        (entry) => EndpointJsonUtils.parseEnumByName(
          ItemArchetypeAffinity.values,
          entry,
        ),
      )
      .whereType<ItemArchetypeAffinity>()
      .toList(growable: false);
  if (parsedAffinities.isEmpty) {
    return List<ItemArchetypeAffinity>.unmodifiable(fallback);
  }

  return List<ItemArchetypeAffinity>.unmodifiable(parsedAffinities);
}

Map<String, Object?> _serializeCombatFlag(CombatRuntimeFlag flag) {
  return {
    'battlerFlag': flag.battlerFlag?.name,
    'itemFlag': flag.itemFlag?.name,
    'itemId': flag.itemId?.name,
    'itemInstanceId': flag.itemInstanceId,
  };
}

Map<String, int> _serializeStatMap(Map<BattlerStat, int> stats) {
  return {
    for (final entry in stats.entries) entry.key.name: entry.value,
  };
}

Map<BattlerStat, int> _deserializeStatMap(
  Object? rawValue, {
  required Map<BattlerStat, int> fallback,
}) {
  final json = EndpointJsonUtils.asJsonMap(rawValue);
  if (json == null) return Map<BattlerStat, int>.from(fallback);

  final stats = <BattlerStat, int>{};
  for (final entry in json.entries) {
    final stat = EndpointJsonUtils.parseEnumByName(
      BattlerStat.values,
      entry.key,
    );
    if (stat == null) continue;
    stats[stat] = EndpointJsonUtils.readInt(
      entry.value,
      fallback: fallback[stat] ?? 0,
    );
  }

  if (stats.isEmpty) {
    return Map<BattlerStat, int>.from(fallback);
  }

  return stats;
}
