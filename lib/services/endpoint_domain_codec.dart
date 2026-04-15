import '../entities/_exports.dart';
import 'endpoint_json_utils.dart';

abstract final class EndpointDomainCodec {
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

    return payload;
  }
}

BattlerAbility? _deserializeAbility(Map<String, dynamic> json) {
  final abilityId = EndpointJsonUtils.parseEnumByName(
    BattlerAbilityId.values,
    json['id'],
  );
  if (abilityId == null) return null;

  final preset = BattlerAbility.presetForId(abilityId);
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

  switch (statusId) {
    case BattlerStatusId.calentando:
      return CalentandoStatus(
        remainingTurns: remainingTurns,
        value: value,
      );
    case BattlerStatusId.potencia:
      return PotenciaStatus(value: value);
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
    case BattlerStatusId.conmocion:
      return ConmocionStatus(value: value);
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

Item? _deserializeItem(Map<String, dynamic> json) {
  final itemId = EndpointJsonUtils.parseEnumByName(ItemId.values, json['id']);
  if (itemId == null) return null;

  final preset = Item.presetForId(itemId);
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
    // El coste de equipo ya no se deriva de la rareza guardada.
    // Si no existe un coste explicito en el preset, se usara el default global.
    equipCost: preset.equipCost,
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
    instanceId: EndpointJsonUtils.readNullableString(json['instanceId']),
    bonusShapeOverride: EndpointJsonUtils.parseEnumByName(
      ItemBonusShape.values,
      json['bonusShape'],
    ),
  );

  if (!item.isInstanced) {
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
    'equipCost': item.equipCost,
    'sellValueBonus': item.sellValueBonus,
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
