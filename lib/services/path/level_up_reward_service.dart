import '_imports.dart';

class LevelUpRewardService {
  static const defaultChoiceCount = 3;

  final CatalogRuntimeService _runtimeService;

  const LevelUpRewardService({
    CatalogRuntimeService runtimeService = const CatalogRuntimeService(),
  }) : _runtimeService = runtimeService;

  BattlerLevelRewardOffer buildOffer({
    required Battler player,
    required RunRandomizer randomizer,
    int choiceCount = defaultChoiceCount,
  }) {
    final nextLevel = min(Battler.maximumLevel, player.level + 1);
    final rewardType = rewardTypeForNextLevel(nextLevel);

    switch (rewardType) {
      case BattlerLevelRewardChoiceType.ability:
        final rarity = abilityRarityForNextLevel(nextLevel);
        final choices = _buildAbilityChoices(
          player: player,
          targetRarity: rarity,
          randomizer: randomizer,
          count: choiceCount,
        );
        if (choices.isEmpty) {
          return _buildStatOffer(nextLevel);
        }
        return BattlerLevelRewardOffer(
          nextLevel: nextLevel,
          type: rewardType,
          rarity: choices.first.rarity ?? rarity,
          choices: choices,
        );
      case BattlerLevelRewardChoiceType.item:
        final rarity = itemRarityForNextLevel(nextLevel);
        final choices = _buildItemChoices(
          player: player,
          targetRarity: rarity,
          randomizer: randomizer,
          count: choiceCount,
        );
        if (choices.isEmpty) {
          return _buildStatOffer(nextLevel);
        }
        return BattlerLevelRewardOffer(
          nextLevel: nextLevel,
          type: rewardType,
          rarity: choices.first.rarity ?? rarity,
          choices: choices,
        );
      case BattlerLevelRewardChoiceType.stat:
        return _buildStatOffer(nextLevel);
    }
  }

  static BattlerLevelRewardChoiceType rewardTypeForNextLevel(int nextLevel) {
    final cycleIndex = (max(2, nextLevel) - 2) % 3;
    return switch (cycleIndex) {
      0 => BattlerLevelRewardChoiceType.ability,
      1 => BattlerLevelRewardChoiceType.item,
      _ => BattlerLevelRewardChoiceType.stat,
    };
  }

  static RarityTier abilityRarityForNextLevel(int nextLevel) {
    final cycleCount = (max(2, nextLevel) - 2) ~/ 3;
    if (cycleCount <= 0) return RarityTier.green;
    if (cycleCount == 1) return RarityTier.purple;
    return RarityTier.yellow;
  }

  static RarityTier itemRarityForNextLevel(int nextLevel) {
    final cycleCount = (max(3, nextLevel) - 3) ~/ 3;
    if (cycleCount <= 0) return RarityTier.blue;
    return RarityTier.yellow;
  }

  List<BattlerLevelRewardChoice> _buildStatChoices() {
    return const <BattlerLevelRewardChoice>[
      BattlerLevelRewardChoice.stat(BattlerLevelReward.income),
      BattlerLevelRewardChoice.stat(BattlerLevelReward.attack),
      BattlerLevelRewardChoice.stat(BattlerLevelReward.health),
    ];
  }

  BattlerLevelRewardOffer _buildStatOffer(int nextLevel) {
    return BattlerLevelRewardOffer(
      nextLevel: nextLevel,
      type: BattlerLevelRewardChoiceType.stat,
      choices: _buildStatChoices(),
    );
  }

  List<BattlerLevelRewardChoice> _buildAbilityChoices({
    required Battler player,
    required RarityTier targetRarity,
    required RunRandomizer randomizer,
    required int count,
  }) {
    final pickedAbilities = <BattlerAbility>[];
    for (final rarity in _rarityFallbacksFrom(targetRarity)) {
      final scopedCandidates = _abilityCandidatesForRarity(
        abilityPoolForArchetype(player.archetypeId),
        player: player,
        targetRarity: rarity,
      );
      final fallbackCandidates = _abilityCandidatesForRarity(
        abilityPresets,
        player: player,
        targetRarity: rarity,
      );
      pickedAbilities.addAll(
        _pickPreferredThenFallback<BattlerAbility>(
          preferred: scopedCandidates,
          fallback: fallbackCandidates,
          randomizer: randomizer,
          count: count,
          keyOf: (ability) => ability.id,
        ),
      );
      if (pickedAbilities.isNotEmpty) break;
    }

    return List<BattlerLevelRewardChoice>.unmodifiable(
      pickedAbilities.map(BattlerLevelRewardChoice.ability),
    );
  }

  List<BattlerLevelRewardChoice> _buildItemChoices({
    required Battler player,
    required RarityTier targetRarity,
    required RunRandomizer randomizer,
    required int count,
  }) {
    final pickedItems = <Item>[];
    for (final rarity in _rarityFallbacksFrom(targetRarity)) {
      final scopedCandidates = _itemCandidatesForRarity(
        itemPoolForArchetype(player.archetypeId),
        targetRarity: rarity,
      );
      final fallbackCandidates = _itemCandidatesForRarity(
        itemPresets,
        targetRarity: rarity,
      );
      pickedItems.addAll(
        _pickPreferredThenFallback<Item>(
          preferred: scopedCandidates,
          fallback: fallbackCandidates,
          randomizer: randomizer,
          count: count,
          keyOf: (item) => item.id,
        ),
      );
      if (pickedItems.isNotEmpty) break;
    }

    return List<BattlerLevelRewardChoice>.unmodifiable(
      pickedItems.map(BattlerLevelRewardChoice.item),
    );
  }

  List<BattlerAbility> _abilityCandidatesForRarity(
    Iterable<BattlerAbility> pool, {
    required Battler player,
    required RarityTier targetRarity,
  }) {
    final candidatesById = <BattlerAbilityId, BattlerAbility>{};

    for (final ability in pool) {
      final ownedAbility = player.abilityById(ability.id);
      if (ownedAbility != null) {
        if (ownedAbility.rarity != targetRarity || !ownedAbility.canUpgrade) {
          continue;
        }
        candidatesById.putIfAbsent(
          ability.id,
          () => _runtimeService.runtimeAbility(ownedAbility),
        );
        continue;
      }

      final promotedAbility = _runtimeService.promoteAbilityToExactRarity(
        ability,
        targetRarity,
      );
      if (promotedAbility == null) continue;
      candidatesById.putIfAbsent(ability.id, () => promotedAbility);
    }

    return List<BattlerAbility>.unmodifiable(candidatesById.values);
  }

  List<Item> _itemCandidatesForRarity(
    Iterable<Item> pool, {
    required RarityTier targetRarity,
  }) {
    final candidatesById = <ItemId, Item>{};

    for (final item in pool) {
      final promotedItem =
          _runtimeService.promoteItemToExactRarity(item, targetRarity);
      if (promotedItem == null) continue;
      candidatesById.putIfAbsent(item.id, () => promotedItem);
    }

    return List<Item>.unmodifiable(candidatesById.values);
  }

  List<RarityTier> _rarityFallbacksFrom(RarityTier targetRarity) {
    return List<RarityTier>.unmodifiable(
      RarityTier.values
          .where((rarity) => rarity.index <= targetRarity.index)
          .toList(growable: false)
          .reversed,
    );
  }

  List<T> _pickPreferredThenFallback<T>({
    required Iterable<T> preferred,
    required Iterable<T> fallback,
    required RunRandomizer randomizer,
    required int count,
    required Object Function(T item) keyOf,
  }) {
    if (count <= 0) return const [];

    final pickedItems = <T>[];
    final pickedKeys = <Object>{};

    void pickFrom(Iterable<T> source) {
      if (pickedItems.length >= count) return;

      final seenCandidateKeys = <Object>{};
      final candidates = <T>[];
      for (final item in source) {
        final key = keyOf(item);
        if (pickedKeys.contains(key) || !seenCandidateKeys.add(key)) {
          continue;
        }
        candidates.add(item);
      }

      for (final item in randomizer.pickDistinct(
        candidates,
        count - pickedItems.length,
      )) {
        pickedItems.add(item);
        pickedKeys.add(keyOf(item));
      }
    }

    pickFrom(preferred);
    pickFrom(fallback);

    return List<T>.unmodifiable(pickedItems);
  }
}
