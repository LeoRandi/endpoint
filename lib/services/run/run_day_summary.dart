import 'dart:math';

import '../../entities/_exports.dart';
import '../persistence/endpoint_domain_codec.dart';
import '../persistence/endpoint_json_utils.dart';

enum RunDaySummaryRewardType {
  item,
  augment,
}

class RunDaySummaryReward {
  final RunDaySummaryRewardType type;
  final String name;
  final String iconEmoji;
  final RarityTier rarity;
  final Item? item;
  final Augment? augment;

  const RunDaySummaryReward({
    required this.type,
    required this.name,
    required this.iconEmoji,
    required this.rarity,
    this.item,
    this.augment,
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

  factory RunDaySummaryReward.augment(Augment augment) {
    return RunDaySummaryReward(
      type: RunDaySummaryRewardType.augment,
      name: augment.displayName,
      iconEmoji: '',
      rarity: augment.rarity,
      augment: augment,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'type': type.name,
      'name': name,
      'iconEmoji': iconEmoji,
      'rarity': rarity.name,
      'itemKey': item?.catalogKey,
      'augmentId': augment?.id,
      'item': item == null ? null : EndpointDomainCodec.serializeItem(item!),
      'augment': augment == null
          ? null
          : EndpointDomainCodec.serializeAugment(augment!),
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
    final augment = type == RunDaySummaryRewardType.augment
        ? _deserializeRewardAugment(json, rarity: rarity)
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
          : item?.displayName ?? augment?.displayName ?? '',
      iconEmoji: iconEmoji.isNotEmpty ? iconEmoji : item?.iconEmoji ?? '',
      rarity: rarity,
      item: item,
      augment: augment,
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

    final itemKey = EndpointJsonUtils.readNullableString(json['itemKey']);
    if (itemKey == null) return null;
    try {
      return Item.presetForKey(itemKey).copyWith(tier: rarity);
    } on StateError {
      return null;
    }
  }

  static Augment? _deserializeRewardAugment(
    Map<String, dynamic> json, {
    required RarityTier rarity,
  }) {
    final augmentJson = EndpointJsonUtils.asJsonMap(json['augment']);
    if (augmentJson != null) {
      final augment = EndpointDomainCodec.deserializeAugment(augmentJson);
      if (augment != null) return augment;
    }

    final augmentId = EndpointJsonUtils.readNullableInt(json['augmentId']);
    if (augmentId != null) {
      final catalogAugment = augmentCatalogById[augmentId];
      if (catalogAugment != null) {
        return catalogAugment.copyWith(tier: rarity);
      }
    }

    return _deserializeLegacyRewardAugment(json, rarity: rarity);
  }

  static Augment? _deserializeLegacyRewardAugment(
    Map<String, dynamic> json, {
    required RarityTier rarity,
  }) {
    final name = EndpointJsonUtils.readString(json['name'], fallback: '');
    if (name.isEmpty) return null;

    for (final augment in augmentCatalog) {
      if (augment.displayName != name) continue;

      return augment.copyWith(
        name: name,
        tier: rarity,
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
    return RunDaySummary(
      dayNumber: dayNumber,
      enemiesKilled: enemiesKilled + (defeatedEnemy ? 1 : 0),
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
      ..._newAugmentRewards(before: before, after: after),
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
    final awardedItemIds = <String>{};
    final rewards = <RunDaySummaryReward>[];

    for (final item in afterItems) {
      if (awardedItemIds.contains(item.catalogKey)) continue;

      final beforeCount = beforeCounts[item.catalogKey] ?? 0;
      final afterCount = afterItems
          .where((entry) => entry.catalogKey == item.catalogKey)
          .length;
      final beforeRarity = beforeBestRarity[item.catalogKey];
      final isNewCopy = afterCount > beforeCount;
      final isUpgrade =
          beforeRarity != null && item.rarity.isAbove(beforeRarity);
      if (!isNewCopy && !isUpgrade) continue;

      awardedItemIds.add(item.catalogKey);
      rewards.add(RunDaySummaryReward.item(item));
    }

    return rewards;
  }

  static List<RunDaySummaryReward> _newAugmentRewards({
    required Battler before,
    required Battler after,
  }) {
    final beforeAugments = {
      for (final augment in before.augments) augment.id: augment,
    };
    final awardedAugmentIds = <int>{};
    final rewards = <RunDaySummaryReward>[];

    for (final augment in after.augments) {
      if (awardedAugmentIds.contains(augment.id)) continue;

      final previousAugment = beforeAugments[augment.id];
      final isNew = previousAugment == null;
      final isUpgrade = previousAugment != null &&
          augment.rarity.isAbove(previousAugment.rarity);
      if (!isNew && !isUpgrade) continue;

      awardedAugmentIds.add(augment.id);
      rewards.add(RunDaySummaryReward.augment(augment));
    }

    return rewards;
  }

  static Map<String, int> _itemCountsById(Iterable<Item> items) {
    final counts = <String, int>{};
    for (final item in items) {
      counts[item.catalogKey] = (counts[item.catalogKey] ?? 0) + 1;
    }
    return counts;
  }

  static Map<String, RarityTier> _bestItemRarityById(Iterable<Item> items) {
    final rarities = <String, RarityTier>{};
    for (final item in items) {
      final currentRarity = rarities[item.catalogKey];
      if (currentRarity != null && currentRarity.isAtLeast(item.rarity)) {
        continue;
      }
      rarities[item.catalogKey] = item.rarity;
    }
    return rarities;
  }
}
