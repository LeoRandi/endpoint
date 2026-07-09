import '../../entities/_exports.dart';
import 'endpoint_json_utils.dart';

abstract final class EndpointDomainCodec {
  static Augment? deserializeAugment(Map<String, dynamic> json) {
    return _deserializeAugment(json);
  }

  static Map<String, Object?> serializeAugment(Augment augment) {
    return _serializeAugment(augment);
  }

  static Item? deserializeItem(Map<String, dynamic> json) {
    return _deserializeItem(json);
  }

  static Map<String, Object?> serializeItem(Item item) {
    return _serializeItem(item);
  }

  static Battler deserializeBattler(Map<String, dynamic> json) {
    final augments = EndpointJsonUtils.readJsonMapList(json['augments'])
        .map<Augment?>(_deserializeAugment)
        .whereType<Augment>()
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
      imageAsset: EndpointJsonUtils.readNullableString(json['imageAsset']),
      archetypeId: _deserializeArchetypeId(json['archetypeId']),
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
      augments: List<Augment>.unmodifiable(augments),
      statuses: List<BattlerStatus>.unmodifiable(statuses),
      inventoryItems: List<Item>.unmodifiable(inventoryItems),
      equippedItems: List<Item>.unmodifiable(equippedItems),
      patternItemPointKeys: patternItemPointKeys,
      reinforcedPatternPointKey: EndpointJsonUtils.readNullableString(
        json['reinforcedPatternPointKey'],
      ),
      purgeDoctrine: EndpointJsonUtils.parseEnumByName(
        PurgeDoctrine.values,
        json['purgeDoctrine'],
      ),
      combatFlags: Set<CombatRuntimeFlag>.unmodifiable(combatFlags),
    );
  }

  static Map<String, Object?> serializeBattler(Battler battler) {
    return {
      'name': battler.name,
      'iconEmoji': battler.iconEmoji,
      'imageAsset': battler.imageAsset,
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
      'augments': battler.augments
          .map<Map<String, Object?>>(_serializeAugment)
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
      'reinforcedPatternPointKey': battler.reinforcedPatternPointKey,
      'purgeDoctrine': battler.purgeDoctrine?.name,
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

    if (node is ArchetypePathNode) {
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
    if (node is ArchetypePathNode && node.startingItems.isNotEmpty) {
      payload['startingItems'] = node.startingItems
          .map<Map<String, Object?>>(_serializeItem)
          .toList(growable: false);
    }

    return payload;
  }
}

ArchetypeId? _deserializeArchetypeId(Object? rawValue) {
  return EndpointJsonUtils.parseEnumByName(
        ArchetypeId.values,
        rawValue,
      ) ??
      switch (rawValue) {
        'veloz' => ArchetypeId.crepitans,
        'inamovible' => ArchetypeId.diabolicus,
        'imparable' => ArchetypeId.hercules,
        'mercante' => ArchetypeId.sacer,
        _ => null,
      };
}

AugmentAffinity? _deserializeAugmentAffinity(Object? rawValue) {
  return EndpointJsonUtils.parseEnumByName(
        AugmentAffinity.values,
        rawValue,
      ) ??
      switch (rawValue) {
        'veloz' => AugmentAffinity.crepitans,
        'inamovible' => AugmentAffinity.diabolicus,
        'imparable' => AugmentAffinity.hercules,
        'mercante' => AugmentAffinity.sacer,
        _ => null,
      };
}

ItemArchetypeAffinity? _deserializeItemArchetypeAffinity(Object? rawValue) {
  return EndpointJsonUtils.parseEnumByName(
        ItemArchetypeAffinity.values,
        rawValue,
      ) ??
      switch (rawValue) {
        'veloz' => ItemArchetypeAffinity.crepitans,
        'inamovible' => ItemArchetypeAffinity.diabolicus,
        'imparable' => ItemArchetypeAffinity.hercules,
        'mercante' => ItemArchetypeAffinity.sacer,
        _ => null,
      };
}

Augment? _deserializeAugment(Map<String, dynamic> json) {
  final id = EndpointJsonUtils.readInt(json['id'], fallback: -1);
  final name = EndpointJsonUtils.readString(json['name'], fallback: '').trim();
  final description = EndpointJsonUtils.readString(
    json['description'],
    fallback: '',
  ).trim();
  final tier = EndpointJsonUtils.parseEnumByName(
    RarityTier.values,
    json['tier'],
  );
  final assetPath = EndpointJsonUtils.readString(
    json['assetPath'],
    fallback: '',
  ).trim();
  final effectEntries = EndpointJsonUtils.readJsonMapList(json['effects']);
  if (id < 0 ||
      name.isEmpty ||
      description.isEmpty ||
      tier == null ||
      assetPath.isEmpty ||
      effectEntries.length != AugmentEffects.tierPatternCount) {
    return null;
  }

  final patternEffects = <List<OperativePatternPoint>, AugmentEffect>{};
  for (final entry in effectEntries) {
    final points = _deserializePatternPointList(entry['pattern']);
    final effectJson = EndpointJsonUtils.asJsonMap(entry['effect']);
    final effect =
        effectJson == null ? null : _deserializeAugmentEffect(effectJson);
    if (points.isEmpty || effect == null) return null;
    patternEffects[points] = effect;
  }
  if (patternEffects.length != AugmentEffects.tierPatternCount) return null;

  return Augment(
    id: id,
    name: name,
    description: description,
    tier: tier,
    assetPath: assetPath,
    affinity: _deserializeAugmentAffinity(json['affinity']) ??
        AugmentAffinity.general,
    tags: _deserializeEntityTags(json['tags']),
    effects: AugmentEffects(patternEffects: patternEffects),
  );
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
  if (statusId == BattlerStatusId.mercadoFuturos) {
    return MercadoFuturosStatus(
      attack: EndpointJsonUtils.readInt(json['attack'], fallback: 1),
      barrier: EndpointJsonUtils.readInt(json['barrier'], fallback: 1),
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
  final name = EndpointJsonUtils.readString(json['name'], fallback: '').trim();
  if (name.isEmpty) return null;

  final itemTier = EndpointJsonUtils.parseEnumByName(
        RarityTier.values,
        json['tier'],
      ) ??
      RarityTier.gray;
  final effects = <Effect, List<int>>{};
  for (final effectJson in EndpointJsonUtils.readJsonMapList(json['effects'])) {
    final effect = _deserializeEffect(effectJson);
    if (effect == null) continue;
    effects[effect] = _deserializeEffectTierValues(
      effectJson,
      effect: effect,
      itemTier: itemTier,
    );
  }

  final instanceId = EndpointJsonUtils.readNullableString(json['instanceId']);
  var item = Item(
    name: name,
    description:
        EndpointJsonUtils.readString(json['description'], fallback: ''),
    affinity: _deserializeItemArchetypeAffinity(json['affinity']) ??
        ItemArchetypeAffinity.general,
    tier: itemTier,
    valueModifier: EndpointJsonUtils.readInt(
      json['valueModifier'],
      fallback: _legacyValueModifierFor(
        tier: itemTier,
        sellValue: EndpointJsonUtils.readNullableInt(json['sellValue']),
      ),
    ),
    tags: _deserializeItemTags(json['tags']),
    asset: EndpointJsonUtils.readString(
      json['asset'],
      fallback: itemAssetPool.first,
    ),
    effects: Map<Effect, List<int>>.unmodifiable(effects),
    instanceId: instanceId,
    isGhostly: EndpointJsonUtils.readBool(
      json['isGhostly'],
      fallback: false,
    ),
  );

  if (item.isInstanced) {
    Item.syncInstanceSequenceFromExistingIds([item.instanceId]);
  } else {
    item = item.toRuntimeInstance();
  }

  return item;
}

CombatRuntimeFlag? _deserializeCombatFlag(Map<String, dynamic> json) {
  final battlerFlag = EndpointJsonUtils.parseEnumByName(
    BattlerCombatFlag.values,
    json['battlerFlag'],
  );
  if (battlerFlag != null) {
    return CombatRuntimeFlag.battler(
      battlerFlag,
      value: EndpointJsonUtils.readNullableInt(json['value']),
      secondaryValue: EndpointJsonUtils.readNullableInt(
        json['secondaryValue'],
      ),
    );
  }

  final itemEffectKey =
      EndpointJsonUtils.readNullableString(json['itemEffectKey']);
  final itemKey = EndpointJsonUtils.readNullableString(json['itemKey']);
  if (itemEffectKey == null || itemKey == null) return null;

  return CombatRuntimeFlag.item(
    itemEffectKey: itemEffectKey,
    itemKey: itemKey,
    itemInstanceId:
        EndpointJsonUtils.readNullableString(json['itemInstanceId']),
    value: EndpointJsonUtils.readNullableInt(json['value']),
    secondaryValue: EndpointJsonUtils.readNullableInt(json['secondaryValue']),
  );
}

Map<String, Object?> _serializeAugment(Augment augment) {
  return {
    'id': augment.id,
    'name': augment.name,
    'description': augment.description,
    'tier': augment.tier.name,
    'assetPath': augment.assetPath,
    'affinity': augment.affinity.name,
    'tags': augment.tags.map((tag) => tag.name).toList(growable: false),
    'effects': augment.effects.patternEffects.entries
        .map<Map<String, Object?>>(
          (entry) => {
            'pattern':
                entry.key.map((point) => point.key).toList(growable: false),
            'effect': _serializeAugmentEffect(entry.value),
          },
        )
        .toList(growable: false),
  };
}

Map<String, Object?> _serializeAugmentEffect(AugmentEffect effect) {
  return {
    'type': effect.type.name,
    'value': effect.value,
    'description': effect.description,
    if (effect.targetPoint != null) 'targetPoint': effect.targetPoint!.key,
  };
}

AugmentEffect? _deserializeAugmentEffect(Map<String, dynamic> json) {
  final type = EndpointJsonUtils.parseEnumByName(
    AugmentEffectType.values,
    json['type'],
  );
  final description = EndpointJsonUtils.readString(
    json['description'],
    fallback: '',
  ).trim();
  if (type == null || description.isEmpty) return null;
  final targetPointKey = EndpointJsonUtils.readNullableString(
    json['targetPoint'],
  );
  final targetPoint = targetPointKey == null
      ? null
      : operativePatternPointsByKey[targetPointKey];
  if (type == AugmentEffectType.patternTargetWeaponPermanentAttackBoost &&
      targetPoint == null) {
    return null;
  }

  return AugmentEffect(
    type: type,
    value: EndpointJsonUtils.readInt(json['value'], fallback: 0),
    description: description,
    targetPoint: targetPoint,
  );
}

Map<String, Object?> _serializeStatus(BattlerStatus status) {
  return {
    'id': status.id.name,
    'name': status.name,
    'type': status.type.name,
    'remainingTurns': status.remainingTurns,
    'value': status.value,
    if (status is CompensadorRutaStatus) 'stat': status.stat.name,
    if (status is MercadoFuturosStatus) ...{
      'attack': status.attack,
      'barrier': status.barrier,
    },
    'isIndefinite': status.isIndefinite,
    'canStack': status.canStack,
    'isPurgeable': status.isPurgeable,
    'persistsOutsideCombat': status.persistsOutsideCombat,
  };
}

Map<String, Object?> _serializeItem(Item item) {
  return {
    'name': item.name,
    'description': item.description,
    'affinity': item.affinity.name,
    'tier': item.tier.name,
    'valueModifier': item.valueModifier,
    'tags': item.tags.map((tag) => tag.name).toList(growable: false),
    'asset': item.asset,
    'effects': item.effects.entries
        .map<Map<String, Object?>?>((entry) => _serializeEffectEntry(
              entry.key,
              entry.value,
            ))
        .whereType<Map<String, Object?>>()
        .toList(growable: false),
    'instanceId': item.instanceId,
    'isGhostly': item.isGhostly,
  };
}

Map<String, Object?>? _serializeEffectEntry(
  Effect effect,
  List<int> tierValues,
) {
  final serialized = switch (effect) {
    ActionEffect action => <String, Object?>{
        'type': 'action',
        ..._serializeActionEffect(action),
      },
    PatternEffect pattern => <String, Object?>{
        'type': 'pattern',
        'pattern': _serializePatternRequirement(pattern.patternType),
        'action': _serializeActionEffect(pattern.actionEffect),
      },
    PassiveEffect passive => <String, Object?>{
        'type': 'passive',
        'hook': passive.hook.name,
        'effectKey': passive.effectKey,
        'description': passive.description,
        'value': passive.value,
      },
  };
  return <String, Object?>{
    ...serialized,
    'tierValues': tierValues,
  };
}

List<int> _deserializeEffectTierValues(
  Map<String, dynamic> json, {
  required Effect effect,
  required RarityTier itemTier,
}) {
  final rawTierValues = json['tierValues'];
  if (rawTierValues is List) {
    final values = rawTierValues.whereType<int>().toList(growable: false);
    if (values.isNotEmpty) return List<int>.unmodifiable(values);
  }

  final upgradeValue = EndpointJsonUtils.readNullableInt(json['upgradeValue']);
  if (upgradeValue == null) {
    return List<int>.unmodifiable(<int>[effect.value]);
  }

  final values = <int>[];
  final reachableTierCount = RarityTier.values.length - itemTier.index;
  for (var i = 0; i < reachableTierCount; i++) {
    values.add(effect.value + (upgradeValue * i));
  }
  return List<int>.unmodifiable(values);
}

int _legacyValueModifierFor({
  required RarityTier tier,
  required int? sellValue,
}) {
  if (sellValue == null) return 0;
  return sellValue - tier.factor;
}

Map<String, Object?> _serializeActionEffect(ActionEffect effect) {
  return {
    'actionType': effect.actionType.name,
    'description': effect.description,
    'customEffectKey': effect.customEffectKey,
    'value': effect.value,
    if (effect.bonusValuesBySource.isNotEmpty)
      'bonusValuesBySource': effect.bonusValuesBySource,
  };
}

Effect? _deserializeEffect(Map<String, dynamic> json) {
  switch (EndpointJsonUtils.readString(json['type'], fallback: '')) {
    case 'action':
      return _deserializeActionEffect(json);
    case 'pattern':
      final pattern = _deserializePatternRequirement(json['pattern']);
      final actionJson = EndpointJsonUtils.asJsonMap(json['action']);
      final action =
          actionJson == null ? null : _deserializeActionEffect(actionJson);
      if (pattern == null || action == null) return null;
      return PatternEffect(patternType: pattern, actionEffect: action);
    case 'passive':
      final hook = EndpointJsonUtils.parseEnumByName(
        ItemEffectHook.values,
        json['hook'],
      );
      final description =
          EndpointJsonUtils.readString(json['description'], fallback: '');
      final effectKey =
          EndpointJsonUtils.readString(json['effectKey'], fallback: '');
      if (hook == null || effectKey.isEmpty || description.isEmpty) return null;
      return PassiveEffect(
        hook: hook,
        effectKey: effectKey,
        description: description,
        value: EndpointJsonUtils.readInt(json['value'], fallback: 0),
      );
    default:
      return null;
  }
}

ActionEffect? _deserializeActionEffect(Map<String, dynamic> json) {
  final actionType = EndpointJsonUtils.parseEnumByName(
    ItemActionType.values,
    json['actionType'],
  );
  if (actionType == null) return null;
  final description = EndpointJsonUtils.readNullableString(json['description']);
  final customEffectKey =
      EndpointJsonUtils.readNullableString(json['customEffectKey']);
  if (actionType == ItemActionType.none &&
      (description == null || customEffectKey == null)) {
    return null;
  }
  return ActionEffect(
    actionType: actionType,
    description: description,
    customEffectKey: customEffectKey,
    bonusValuesBySource: _deserializeIntMap(json['bonusValuesBySource']),
    value: EndpointJsonUtils.readInt(json['value'], fallback: 0),
  );
}

Map<String, int> _deserializeIntMap(Object? rawValue) {
  final jsonMap = EndpointJsonUtils.asJsonMap(rawValue);
  if (jsonMap == null) return const <String, int>{};

  return Map<String, int>.unmodifiable({
    for (final entry in jsonMap.entries)
      if (entry.value is int) entry.key: entry.value as int,
  });
}

Map<String, Object?> _serializePatternRequirement(
  OperativePatternRequirement requirement,
) {
  return {
    'kind': requirement.kind.name,
  };
}

OperativePatternRequirement? _deserializePatternRequirement(Object? rawValue) {
  final json = EndpointJsonUtils.asJsonMap(rawValue);
  if (json == null) return null;
  final kind = EndpointJsonUtils.parseEnumByName(
    OperativePatternRequirementKind.values,
    json['kind'],
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
  }
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

List<EntityTag> _deserializeItemTags(Object? rawValue) {
  return _deserializeEntityTags(rawValue);
}

List<EntityTag> _deserializeEntityTags(Object? rawValue) {
  if (rawValue is! List) return const <EntityTag>[];
  return List<EntityTag>.unmodifiable(
    rawValue
        .map<EntityTag?>(
          (value) => EndpointJsonUtils.parseEnumByName(EntityTag.values, value),
        )
        .whereType<EntityTag>(),
  );
}

Map<String, Object?> _serializeCombatFlag(CombatRuntimeFlag flag) {
  return {
    'battlerFlag': flag.battlerFlag?.name,
    'itemEffectKey': flag.itemEffectKey,
    'itemKey': flag.itemKey,
    'itemInstanceId': flag.itemInstanceId,
    'value': flag.value,
    'secondaryValue': flag.secondaryValue,
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
