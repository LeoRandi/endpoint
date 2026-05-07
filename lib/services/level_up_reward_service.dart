import '_imports.dart';

class LevelUpRewardService {
  static const defaultChoiceCount = 3;

  const LevelUpRewardService();

  BattlerLevelRewardOffer buildOffer({
    required Battler player,
    required RunRandomizer randomizer,
    int choiceCount = defaultChoiceCount,
  }) {
    final nextLevel = min(Battler.maximumLevel, player.level + 1);
    final rewardType = rewardTypeForNextLevel(nextLevel);

    switch (rewardType) {
      case BattlerLevelRewardChoiceType.ability:
        final rarity = nextLevel == 2 ? RarityTier.green : RarityTier.purple;
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
          rarity: rarity,
          choices: choices,
        );
      case BattlerLevelRewardChoiceType.item:
        final rarity = nextLevel == 3 ? RarityTier.blue : RarityTier.yellow;
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
          rarity: rarity,
          choices: choices,
        );
      case BattlerLevelRewardChoiceType.stat:
        return _buildStatOffer(nextLevel);
    }
  }

  static BattlerLevelRewardChoiceType rewardTypeForNextLevel(int nextLevel) {
    switch (nextLevel) {
      case 2:
      case 5:
        return BattlerLevelRewardChoiceType.ability;
      case 3:
      case 6:
        return BattlerLevelRewardChoiceType.item;
      case 4:
      default:
        return BattlerLevelRewardChoiceType.stat;
    }
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
    final scopedCandidates = _abilityCandidatesForRarity(
      abilityPoolForArchetype(player.archetypeId),
      player: player,
      targetRarity: targetRarity,
    );
    final fallbackCandidates = _abilityCandidatesForRarity(
      abilityPresets,
      player: player,
      targetRarity: targetRarity,
    );
    final pickedAbilities = _pickPreferredThenFallback<BattlerAbility>(
      preferred: scopedCandidates,
      fallback: fallbackCandidates,
      randomizer: randomizer,
      count: count,
      keyOf: (ability) => ability.id,
    );

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
    final scopedCandidates = _itemCandidatesForRarity(
      itemPoolForArchetype(player.archetypeId),
      targetRarity: targetRarity,
    );
    final fallbackCandidates = _itemCandidatesForRarity(
      itemPresets,
      targetRarity: targetRarity,
    );
    final pickedItems = _pickPreferredThenFallback<Item>(
      preferred: scopedCandidates,
      fallback: fallbackCandidates,
      randomizer: randomizer,
      count: count,
      keyOf: (item) => item.id,
    );

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
          () => ownedAbility.resetState(),
        );
        continue;
      }

      final promotedAbility = _promoteAbilityToExactRarity(
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
      final promotedItem = _promoteItemToExactRarity(item, targetRarity);
      if (promotedItem == null) continue;
      candidatesById.putIfAbsent(item.id, () => promotedItem);
    }

    return List<Item>.unmodifiable(candidatesById.values);
  }

  BattlerAbility? _promoteAbilityToExactRarity(
    BattlerAbility ability,
    RarityTier targetRarity,
  ) {
    if (ability.rarity.index > targetRarity.index) return null;

    var promotedAbility = ability.resetState();
    while (promotedAbility.rarity.index < targetRarity.index &&
        promotedAbility.canUpgrade) {
      promotedAbility = promotedAbility.upgraded();
    }

    if (promotedAbility.rarity != targetRarity) return null;

    return promotedAbility.resetState();
  }

  Item? _promoteItemToExactRarity(Item item, RarityTier targetRarity) {
    if (item.rarity.index > targetRarity.index) return null;

    var promotedItem = item;
    while (promotedItem.rarity.index < targetRarity.index &&
        promotedItem.canUpgrade) {
      promotedItem = promotedItem.upgraded();
    }

    if (promotedItem.rarity != targetRarity) return null;

    return promotedItem;
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
