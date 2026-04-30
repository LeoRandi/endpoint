import 'dart:math';

import '../entities/_exports.dart';
import 'endpoint_domain_codec.dart';
import 'endpoint_json_utils.dart';

enum RunDaySummaryRewardType {
  item,
  ability,
}

class RunDaySummaryReward {
  final RunDaySummaryRewardType type;
  final String name;
  final String iconEmoji;
  final RarityTier rarity;
  final Item? item;
  final BattlerAbility? ability;

  const RunDaySummaryReward({
    required this.type,
    required this.name,
    required this.iconEmoji,
    required this.rarity,
    this.item,
    this.ability,
  });

  factory RunDaySummaryReward.item(Item item) {
    return RunDaySummaryReward(
      type: RunDaySummaryRewardType.item,
      name: item.displayName,
      iconEmoji: item.iconEmoji,
      rarity: item.rarity,
      item: item,
    );
  }

  factory RunDaySummaryReward.ability(BattlerAbility ability) {
    return RunDaySummaryReward(
      type: RunDaySummaryRewardType.ability,
      name: ability.displayName,
      iconEmoji: '',
      rarity: ability.rarity,
      ability: ability,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'type': type.name,
      'name': name,
      'iconEmoji': iconEmoji,
      'rarity': rarity.name,
      'itemId': item?.id.name,
      'abilityId': ability?.id.name,
      'item': item == null ? null : EndpointDomainCodec.serializeItem(item!),
      'ability': ability == null
          ? null
          : EndpointDomainCodec.serializeAbility(ability!),
    };
  }

  static RunDaySummaryReward? fromJson(Object? rawValue) {
    final json = EndpointJsonUtils.asJsonMap(rawValue);
    if (json == null) return null;

    final type = EndpointJsonUtils.parseEnumByName(
      RunDaySummaryRewardType.values,
      json['type'],
    );
    final rarity = EndpointJsonUtils.parseEnumByName(
      RarityTier.values,
      json['rarity'],
    );
    if (type == null || rarity == null) return null;

    final item = type == RunDaySummaryRewardType.item
        ? _deserializeRewardItem(json, rarity: rarity)
        : null;
    final ability = type == RunDaySummaryRewardType.ability
        ? _deserializeRewardAbility(json, rarity: rarity)
        : null;

    final name = EndpointJsonUtils.readString(json['name'], fallback: '');
    final iconEmoji = EndpointJsonUtils.readString(
      json['iconEmoji'],
      fallback: '',
    );

    return RunDaySummaryReward(
      type: type,
      name: name.isNotEmpty
          ? name
          : item?.displayName ?? ability?.displayName ?? '',
      iconEmoji: iconEmoji.isNotEmpty ? iconEmoji : item?.iconEmoji ?? '',
      rarity: rarity,
      item: item,
      ability: ability,
    );
  }

  static Item? _deserializeRewardItem(
    Map<String, dynamic> json, {
    required RarityTier rarity,
  }) {
    final itemJson = EndpointJsonUtils.asJsonMap(json['item']);
    if (itemJson != null) {
      final item = EndpointDomainCodec.deserializeItem(itemJson);
      if (item != null) return item;
    }

    final itemId = EndpointJsonUtils.parseEnumByName(
      ItemId.values,
      json['itemId'],
    );
    if (itemId == null) {
      return _deserializeLegacyRewardItem(json, rarity: rarity);
    }

    try {
      final preset = Item.presetForId(itemId);
      return preset
          .copyWith(
            name: EndpointJsonUtils.readString(
              json['name'],
              fallback: preset.name,
            ),
            iconEmoji: EndpointJsonUtils.readString(
              json['iconEmoji'],
              fallback: preset.iconEmoji,
            ),
            rarity: rarity,
          )
          .normalizeUpgradeTier();
    } on StateError {
      return null;
    }
  }

  static Item? _deserializeLegacyRewardItem(
    Map<String, dynamic> json, {
    required RarityTier rarity,
  }) {
    final name = EndpointJsonUtils.readString(json['name'], fallback: '');
    final iconEmoji = EndpointJsonUtils.readString(
      json['iconEmoji'],
      fallback: '',
    );
    for (final preset in itemPresets) {
      final matchesName = name.isNotEmpty && preset.displayName == name;
      final matchesIcon = iconEmoji.isNotEmpty && preset.iconEmoji == iconEmoji;
      if (!matchesName && !matchesIcon) continue;

      return preset.copyWith(
        name: name.isEmpty ? preset.name : name,
        iconEmoji: iconEmoji.isEmpty ? preset.iconEmoji : iconEmoji,
        rarity: rarity,
      );
    }

    return null;
  }

  static BattlerAbility? _deserializeRewardAbility(
    Map<String, dynamic> json, {
    required RarityTier rarity,
  }) {
    final abilityJson = EndpointJsonUtils.asJsonMap(json['ability']);
    if (abilityJson != null) {
      final ability = EndpointDomainCodec.deserializeAbility(abilityJson);
      if (ability != null) return ability;
    }

    final abilityId = EndpointJsonUtils.parseEnumByName(
      BattlerAbilityId.values,
      json['abilityId'],
    );
    if (abilityId == null) {
      return _deserializeLegacyRewardAbility(json, rarity: rarity);
    }

    try {
      final preset = BattlerAbility.presetForId(abilityId);
      return preset
          .copyWith(
            name: EndpointJsonUtils.readString(
              json['name'],
              fallback: preset.name,
            ),
            rarity: rarity,
          )
          .normalizeUpgradeTier();
    } on StateError {
      return null;
    }
  }

  static BattlerAbility? _deserializeLegacyRewardAbility(
    Map<String, dynamic> json, {
    required RarityTier rarity,
  }) {
    final name = EndpointJsonUtils.readString(json['name'], fallback: '');
    if (name.isEmpty) return null;

    for (final preset in abilityPresets) {
      if (preset.displayName != name) continue;

      return preset.copyWith(
        name: name,
        rarity: rarity,
      );
    }

    return null;
  }
}

class RunDaySummaryEnemy {
  final Battler battler;
  final RarityTier rarity;

  const RunDaySummaryEnemy({
    required this.battler,
    required this.rarity,
  });

  factory RunDaySummaryEnemy.fromBattler(
    Battler battler, {
    required RarityTier rarity,
  }) {
    return RunDaySummaryEnemy(
      battler: battler,
      rarity: rarity,
    );
  }

  String get name => battler.name;
  String get iconEmoji => battler.iconEmoji;
  int get maxHealth => battler.maxHealth;
  int get attack => battler.attack;
  int get barrier => battler.barrier;
  int get income => battler.income;

  Map<String, Object?> toJson() {
    return {
      'rarity': rarity.name,
      'battler': EndpointDomainCodec.serializeBattler(battler),
    };
  }

  static RunDaySummaryEnemy? fromJson(Object? rawValue) {
    final json = EndpointJsonUtils.asJsonMap(rawValue);
    if (json == null) return null;

    final battlerJson = EndpointJsonUtils.asJsonMap(json['battler']);
    if (battlerJson == null) return null;

    return RunDaySummaryEnemy(
      battler: EndpointDomainCodec.deserializeBattler(battlerJson),
      rarity: EndpointJsonUtils.parseEnumByName(
            RarityTier.values,
            json['rarity'],
          ) ??
          RarityTier.gray,
    );
  }
}

class RunDaySummary {
  final int dayNumber;
  final int enemiesKilled;
  final int moneyGained;
  final List<RunDaySummaryReward> gainedRewards;
  final List<RunDaySummaryEnemy> defeatedEnemies;

  const RunDaySummary({
    required this.dayNumber,
    required this.enemiesKilled,
    required this.moneyGained,
    required this.gainedRewards,
    required this.defeatedEnemies,
  });

  const RunDaySummary.empty({
    this.dayNumber = 1,
  })  : enemiesKilled = 0,
        moneyGained = 0,
        gainedRewards = const <RunDaySummaryReward>[],
        defeatedEnemies = const <RunDaySummaryEnemy>[];

  bool get hasGains =>
      enemiesKilled > 0 ||
      moneyGained > 0 ||
      gainedRewards.isNotEmpty ||
      defeatedEnemies.isNotEmpty;

  RunDaySummary recordScene({
    required Battler before,
    required Battler after,
    bool defeatedEnemy = false,
    Battler? defeatedEnemyBattler,
    RarityTier? defeatedEnemyRarity,
    bool includeRewards = true,
  }) {
    final shouldCountEnemy = defeatedEnemy || defeatedEnemyBattler != null;

    return RunDaySummary(
      dayNumber: dayNumber,
      enemiesKilled: enemiesKilled + (shouldCountEnemy ? 1 : 0),
      moneyGained: moneyGained + max(0, after.money - before.money),
      gainedRewards: List<RunDaySummaryReward>.unmodifiable([
        ...gainedRewards,
        if (includeRewards) ..._newRewards(before: before, after: after),
      ]),
      defeatedEnemies: List<RunDaySummaryEnemy>.unmodifiable([
        ...defeatedEnemies,
        if (defeatedEnemyBattler != null)
          RunDaySummaryEnemy.fromBattler(
            defeatedEnemyBattler,
            rarity: defeatedEnemyRarity ?? RarityTier.gray,
          ),
      ]),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'dayNumber': dayNumber,
      'enemiesKilled': enemiesKilled,
      'moneyGained': moneyGained,
      'gainedRewards': gainedRewards
          .map<Map<String, Object?>>((reward) => reward.toJson())
          .toList(growable: false),
      'defeatedEnemies': defeatedEnemies
          .map<Map<String, Object?>>((enemy) => enemy.toJson())
          .toList(growable: false),
    };
  }

  static RunDaySummary? fromJson(Object? rawValue) {
    final json = EndpointJsonUtils.asJsonMap(rawValue);
    if (json == null) return null;

    return RunDaySummary(
      dayNumber: max(
        1,
        EndpointJsonUtils.readInt(json['dayNumber'], fallback: 1),
      ),
      enemiesKilled: max(
        0,
        EndpointJsonUtils.readInt(json['enemiesKilled'], fallback: 0),
      ),
      moneyGained: max(
        0,
        EndpointJsonUtils.readInt(json['moneyGained'], fallback: 0),
      ),
      gainedRewards: List<RunDaySummaryReward>.unmodifiable(
        EndpointJsonUtils.readJsonMapList(json['gainedRewards'])
            .map<RunDaySummaryReward?>(RunDaySummaryReward.fromJson)
            .whereType<RunDaySummaryReward>(),
      ),
      defeatedEnemies: List<RunDaySummaryEnemy>.unmodifiable(
        EndpointJsonUtils.readJsonMapList(json['defeatedEnemies'])
            .map<RunDaySummaryEnemy?>(RunDaySummaryEnemy.fromJson)
            .whereType<RunDaySummaryEnemy>(),
      ),
    );
  }

  static List<RunDaySummaryReward> _newRewards({
    required Battler before,
    required Battler after,
  }) {
    return [
      ..._newItemRewards(before: before, after: after),
      ..._newAbilityRewards(before: before, after: after),
    ];
  }

  static List<RunDaySummaryReward> _newItemRewards({
    required Battler before,
    required Battler after,
  }) {
    final beforeItems = [
      ...before.equippedItems,
      ...before.inventoryItems,
    ];
    final afterItems = [
      ...after.equippedItems,
      ...after.inventoryItems,
    ];
    final beforeCounts = _itemCountsById(beforeItems);
    final beforeBestRarity = _bestItemRarityById(beforeItems);
    final awardedItemIds = <ItemId>{};
    final rewards = <RunDaySummaryReward>[];

    for (final item in afterItems) {
      if (awardedItemIds.contains(item.id)) continue;

      final beforeCount = beforeCounts[item.id] ?? 0;
      final afterCount =
          afterItems.where((entry) => entry.id == item.id).length;
      final beforeRarity = beforeBestRarity[item.id];
      final isNewCopy = afterCount > beforeCount;
      final isUpgrade =
          beforeRarity != null && item.rarity.index > beforeRarity.index;
      if (!isNewCopy && !isUpgrade) continue;

      awardedItemIds.add(item.id);
      rewards.add(RunDaySummaryReward.item(item));
    }

    return rewards;
  }

  static List<RunDaySummaryReward> _newAbilityRewards({
    required Battler before,
    required Battler after,
  }) {
    final beforeAbilities = {
      for (final ability in before.abilities) ability.id: ability,
    };
    final awardedAbilityIds = <BattlerAbilityId>{};
    final rewards = <RunDaySummaryReward>[];

    for (final ability in after.abilities) {
      if (awardedAbilityIds.contains(ability.id)) continue;

      final previousAbility = beforeAbilities[ability.id];
      final isNew = previousAbility == null;
      final isUpgrade = previousAbility != null &&
          (ability.rarity.index > previousAbility.rarity.index ||
              ability.value > previousAbility.value);
      if (!isNew && !isUpgrade) continue;

      awardedAbilityIds.add(ability.id);
      rewards.add(RunDaySummaryReward.ability(ability));
    }

    return rewards;
  }

  static Map<ItemId, int> _itemCountsById(Iterable<Item> items) {
    final counts = <ItemId, int>{};
    for (final item in items) {
      counts[item.id] = (counts[item.id] ?? 0) + 1;
    }
    return counts;
  }

  static Map<ItemId, RarityTier> _bestItemRarityById(Iterable<Item> items) {
    final rarities = <ItemId, RarityTier>{};
    for (final item in items) {
      final currentRarity = rarities[item.id];
      if (currentRarity != null && currentRarity.index >= item.rarity.index) {
        continue;
      }
      rarities[item.id] = item.rarity;
    }
    return rarities;
  }
}
